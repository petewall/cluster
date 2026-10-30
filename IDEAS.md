# Ideas

Speculative / in-flight ideas — not committed work (that lives in `TODO.md`).
Prune freely; promote to `TODO.md` once an idea firms up into a real plan.

## 1. Finish the local-AI integrations (daily report + analysis)

Build out more single-shot Ollama workloads now that the pattern is proven (the
KRR right-sizing digest works end-to-end). Guiding principle stands: deterministic
code gathers the data + does the math, the LLM only phrases/classifies. Candidates:

- **Daily report** — gather cluster + home state (metrics, recent events, KRR
  findings, maybe HA data) → Ollama writes a plain-English summary → deliver it
  (GitHub issue / ntfy / **e-ink panel, see #3**).
- **Daily Loki event digest** — restarts / OOMKills / `FailedCreatePodSandBox`;
  overlaps the control-plane alerting work in `TODO.md`.
- Stay single-shot + text (CPU-viable, ~tens of seconds). Vision/agentic still
  needs a GPU. (See memory: `llm-roadmap`.)

## 1b. GPU node for local AI (VRAM targets + buying rules)

The single-shot Ollama pattern works on CPU but is slow (`qwen2.5:7b-instruct`
~47s/call) and the agentic/vision tier is off the table without a GPU. A GPU
worker node is the unlock. **VRAM is the only spec that matters** — it decides
which models fit fully on the card (partial offload = mostly CPU speed anyway):

- **3GB** — only ≤3B models (`llama3.2:3b`, `qwen2.5:3b` ~2GB Q4). Too small:
  can't hold the 7B we use now, and won't grow into the agentic/vision tier.
- **8GB** — 7B at Q4 fits; workable floor.
- **12GB** — 7B comfortably, 14B at a squeeze. **The homelab sweet spot.**

- **Target card: used RTX 3060 12GB (~$250–300).** 4× the VRAM of a 1060,
  has tensor cores, current driver support. Better spend than a whole old
  gaming PC. Drop it in a cheap Ubuntu box, or an existing node with PCIe + PSU
  headroom.
- **Avoid:** anything with <8GB VRAM (e.g. GTX 1060 3GB), and old Pascal-era
  cards generally (no tensor cores, weak FP16, driver support aging out).
- **k8s wiring is easy:** wipe to Ubuntu 22.04 (cluster standard, amd64) →
  `microk8s join` → `microk8s enable gpu` (pulls the NVIDIA GPU operator +
  device plugin) → Ollama requests `nvidia.com/gpu` and schedules there.
- **Gotchas for an always-on GPU box:** meaningfully higher idle/load power
  (~40–60W idle, 150–200W under load) + heat/noise, and it's another node to
  power-protect — ties to the UPS item in `TODO.md` and the node-outage
  incidents. Put the OS/containerd on an SSD; a bundled HDD is useless for k8s.
- **Lesson (2026-09-30):** evaluated a $350 i5-7600K / GTX 1060 **3GB** / 24GB
  gaming PC — passed. The 3GB VRAM caps it below the current 7B workload; the
  rest is serviceable-but-old 2017 hardware realistically worth ~$150–200.
  Buy for VRAM, not for a whole cheap machine.

## 2. Investigate K8sGPT

AI-powered Kubernetes diagnostics — scans the cluster for problems and explains
them in plain English. https://github.com/k8sgpt-ai/k8sgpt

- Relevant after the iSCSI/DB read-only incident — it may have surfaced the
  crashloop root cause faster; complements the Grafana Cloud alerting.
- Runs in-cluster and supports a **local LLM backend (Ollama)** → fits the
  self-hosted goal.
- Promising nuance: K8sGPT's analyzers detect issues *deterministically*, then
  the LLM only *explains* the finding — that's the single-shot pattern that works
  on our CPU-only Ollama, unlike HolmesGPT's agentic tool-loop that failed on CPU
  (see `llm-roadmap`). So it's worth a real try where HolmesGPT wasn't.

## 3. Tesserae e-ink dashboard

- **tesserae** — e-ink dashboard companion: compose dashboards in a browser,
  render server-side, push to e-ink panels over REST/MQTT. Python, actively
  maintained. https://github.com/dmellok/tesserae
- **tesserae-device-pi-png** — Raspberry Pi daemon that subscribes to a Tesserae
  server over MQTT and paints PNG frames onto a Pimoroni **inky** e-ink panel.
  https://github.com/dmellok/tesserae-device-pi-png
- **Why it's exciting here:** this is the missing *screen* for the daily-briefing
  idea in `llm-roadmap`. Run the tesserae server in-cluster, have the local LLM
  generate the daily report (#1), render it, and push it to an e-ink panel on a
  Pi. Ties #1 + #3 together. Would need an MQTT broker in-cluster and a Pi with a
  Pimoroni panel.
