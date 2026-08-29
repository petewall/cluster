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
