#!/usr/bin/env python3
"""Filter KRR JSON to *significant* right-sizing changes, have a local LLM write
a short plain-English summary of them, and post the whole thing to a single
evergreen GitHub issue.

Principle: KRR computes the numbers and this script does the filtering/math
(deterministic, verifiable). Ollama is asked ONLY to phrase the already-computed
facts into prose — it never invents numbers or decides anything. If Ollama is
unreachable the deterministic table still posts; the summary is best-effort.

stdlib only (runs inside the KRR image). Set DRY_RUN=1 to print the rendered
issue body and skip all GitHub calls.
"""
import datetime
import json
import os
import urllib.error
import urllib.request

KRR_JSON = os.environ.get("KRR_JSON", "/tmp/krr.json")
DRY_RUN = os.environ.get("DRY_RUN")

# A change is "significant" only if it clears BOTH an absolute floor AND a
# relative floor — that drops noise like 11Mi->10Mi while keeping 900Mi->10Mi.
CPU_ABS_M = float(os.environ.get("CPU_ABS_FLOOR_M", "50"))  # millicores
CPU_PCT = float(os.environ.get("CPU_PCT_FLOOR", "25"))
MEM_ABS_MI = float(os.environ.get("MEM_ABS_FLOOR_MI", "64"))  # MiB
MEM_PCT = float(os.environ.get("MEM_PCT_FLOOR", "25"))

# Local LLM (Ollama). Empty OLLAMA_URL disables the prose summary entirely.
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://ollama.ollama.svc.cluster.local:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "qwen2.5:7b-instruct")
OLLAMA_TIMEOUT = float(os.environ.get("OLLAMA_TIMEOUT", "600"))  # CPU inference is slow

SEV_RANK = {"CRITICAL": 0, "WARNING": 1, "OK": 2, "GOOD": 3, "UNKNOWN": 4}
SEV_ICON = {"CRITICAL": "🔴", "WARNING": "🟡", "OK": "⚪", "GOOD": "🟢", "UNKNOWN": "⚫"}
API = "https://api.github.com"


def fmt_cpu(v):
    if v is None:
        return "unset"
    if isinstance(v, str):
        return "?"  # "?" = HPA-managed
    return f"{round(v * 1000)}m"


def fmt_mem(v):
    if v is None:
        return "unset"
    if isinstance(v, str):
        return "?"
    mi = v / (1024.0 * 1024.0)
    return f"{mi / 1024:.1f}Gi" if mi >= 1024 else f"{round(mi)}Mi"


def cpu_units(v):  # cores -> millicores
    return v * 1000.0 if isinstance(v, (int, float)) else None


def mem_units(v):  # bytes -> MiB
    return v / (1024.0 * 1024.0) if isinstance(v, (int, float)) else None


def rec_value(entry):
    # recommended.{requests,limits}.{cpu,memory} is {"value":..., "severity":...}
    return entry.get("value") if isinstance(entry, dict) else entry


def significant(cur, rec, abs_floor, pct_floor, conv):
    if isinstance(rec, str):  # "?" -> HPA/unknown, can't act
        return False
    c, r = conv(cur), conv(rec)
    if c is None and r is None:
        return False
    if c is None:  # unset -> set
        return r is not None and r >= abs_floor
    if r is None:  # set -> unset (e.g. dropping a limit)
        return c >= abs_floor
    delta = abs(r - c)
    pct = (delta / c * 100.0) if c > 0 else 100.0
    return delta >= abs_floor and pct >= pct_floor


def grade(score):
    return "F" if score < 30 else "D" if score < 55 else "C" if score < 70 else "B" if score < 90 else "A"


DIMS = [
    ("requests", "cpu", CPU_ABS_M, CPU_PCT, cpu_units),
    ("requests", "memory", MEM_ABS_MI, MEM_PCT, mem_units),
    ("limits", "cpu", CPU_ABS_M, CPU_PCT, cpu_units),
    ("limits", "memory", MEM_ABS_MI, MEM_PCT, mem_units),
]


def cell(alloc, rec, sel, rt, fmt):
    cur = alloc.get(sel, {}).get(rt)
    new = rec_value(rec.get(sel, {}).get(rt))
    cs, rs = fmt(cur), fmt(new)
    return cs if cs == rs else f"{cs} → {rs}"


def significant_rows(data):
    rows = []
    for s in data.get("scans", []):
        obj, rec, alloc = s["object"], s["recommended"], s["object"]["allocations"]
        hit = any(
            significant(alloc.get(sel, {}).get(rt), rec_value(rec.get(sel, {}).get(rt)), af, pf, conv)
            for sel, rt, af, pf, conv in DIMS
        )
        if not hit:
            continue
        rows.append({
            "sev": s.get("severity", "UNKNOWN"),
            "ns": obj["namespace"], "name": obj["name"], "container": obj["container"],
            "cpu_req": cell(alloc, rec, "requests", "cpu", fmt_cpu),
            "cpu_lim": cell(alloc, rec, "limits", "cpu", fmt_cpu),
            "mem_req": cell(alloc, rec, "requests", "memory", fmt_mem),
            "mem_lim": cell(alloc, rec, "limits", "memory", fmt_mem),
        })
    rows.sort(key=lambda r: (SEV_RANK.get(r["sev"], 9), r["ns"], r["name"], r["container"]))
    return rows


def ollama_summary(rows):
    """Ask the local LLM to phrase the already-computed rows into prose. Returns
    None on any failure — the caller falls back to the table alone."""
    if not OLLAMA_URL or not rows:
        return None
    # Feed the model only the deterministic facts, as compact lines.
    facts = "\n".join(
        f"- {r['ns']}/{r['name']} ({r['container']}): "
        f"CPU req {r['cpu_req']}, CPU lim {r['cpu_lim']}, "
        f"Mem req {r['mem_req']}, Mem lim {r['mem_lim']} [{r['sev']}]"
        for r in rows
    )
    prompt = (
        "You are writing a brief summary for a Kubernetes resource right-sizing "
        "report. The changes below were already computed by KRR. Write 2 to 4 "
        "sentences in plain English calling out the most impactful changes "
        "(largest CPU or memory reductions/increases) and any overall pattern. "
        "Rules: only describe what is listed below; do NOT invent numbers, "
        "workloads, or recommendations; no markdown headings; no preamble like "
        "'Here is a summary'. Just the summary text.\n\n"
        f"Changes:\n{facts}\n"
    )
    payload = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "stream": False,
        "options": {"temperature": 0},
    }
    req = urllib.request.Request(
        OLLAMA_URL.rstrip("/") + "/api/generate",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=OLLAMA_TIMEOUT) as resp:
            out = json.load(resp).get("response", "").strip()
            return out or None
    except (urllib.error.URLError, TimeoutError, ValueError) as e:
        print(f"[warn] Ollama summary skipped: {e}", flush=True)
        return None


def build_body(data):
    scans = data.get("scans", [])
    score = data.get("score", 0)
    rows = significant_rows(data)

    now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    out = [
        "<!-- krr-report -->",
        f"_Updated {now} · cluster grade **{grade(score)}** ({score}/100) · "
        f"{len(rows)} of {len(scans)} workloads over threshold_",
        "",
        f"Thresholds: CPU ≥ {int(CPU_ABS_M)}m **and** ≥ {int(CPU_PCT)}%, "
        f"Memory ≥ {int(MEM_ABS_MI)}Mi **and** ≥ {int(MEM_PCT)}%. "
        "Recommendations only — review before applying (KRR sets memory limit == request, "
        "which can OOM bursty workloads).",
        "",
    ]

    if rows:
        summary = ollama_summary(rows)
        if summary:
            out += ["> **Summary** _(local LLM — phrasing only; the table below is authoritative)_",
                    "", "> " + summary.replace("\n", "\n> "), ""]
        out += [
            "| Sev | Namespace | Workload | Container | CPU req | CPU lim | Mem req | Mem lim |",
            "|-----|-----------|----------|-----------|---------|---------|---------|---------|",
        ]
        out += [
            f"| {SEV_ICON.get(r['sev'], '')} | {r['ns']} | {r['name']} | {r['container']} | "
            f"{r['cpu_req']} | {r['cpu_lim']} | {r['mem_req']} | {r['mem_lim']} |"
            for r in rows
        ]
    else:
        out.append("✅ Everything is within threshold — no significant changes recommended.")
    out += ["", "<sub>Generated weekly by the KRR CronJob against Grafana Cloud metrics.</sub>"]
    return "\n".join(out), len(rows)


def gh(method, path, payload=None):
    req = urllib.request.Request(
        API + path,
        data=json.dumps(payload).encode() if payload is not None else None,
        method=method,
    )
    req.add_header("Authorization", f"Bearer {os.environ['GITHUB_TOKEN']}")
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("X-GitHub-Api-Version", "2022-11-28")
    if payload is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.load(resp)
    except urllib.error.HTTPError as e:
        return e.code, {"_error": e.read().decode()}


def main():
    with open(KRR_JSON) as f:
        data = json.load(f)
    body, n = build_body(data)

    if DRY_RUN:
        print(body)
        print(f"\n[dry-run] {n} significant recommendations; GitHub not touched", flush=True)
        return

    repo = os.environ["GITHUB_REPO"]
    title = os.environ.get("ISSUE_TITLE", "KRR right-sizing recommendations")
    label = os.environ.get("ISSUE_LABEL", "krr-report")

    st, issues = gh("GET", f"/repos/{repo}/issues?state=open&per_page=100")
    if st >= 300:
        raise SystemExit(f"list issues failed {st}: {issues.get('_error')}")
    existing = next((i for i in issues if i.get("title") == title and "pull_request" not in i), None)

    if existing:
        st, resp = gh("PATCH", f"/repos/{repo}/issues/{existing['number']}", {"body": body})
        if st >= 300:
            raise SystemExit(f"update issue failed {st}: {resp.get('_error')}")
        print(f"Updated issue #{existing['number']} ({n} recommendations)")
    else:
        gh("POST", f"/repos/{repo}/labels",
           {"name": label, "color": "0e8a16", "description": "KRR right-sizing report"})  # best-effort
        st, resp = gh("POST", f"/repos/{repo}/issues", {"title": title, "body": body, "labels": [label]})
        if st >= 300:  # retry without the label if it couldn't be attached
            st, resp = gh("POST", f"/repos/{repo}/issues", {"title": title, "body": body})
        if st >= 300:
            raise SystemExit(f"create issue failed {st}: {resp.get('_error')}")
        print(f"Created issue #{resp['number']} ({n} recommendations)")


if __name__ == "__main__":
    main()
