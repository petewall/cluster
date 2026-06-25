#!/usr/bin/env bash
# Render every Flux HelmRelease in the repo to plain Kubernetes manifests via
# `helm template`, so a manifest linter can inspect the actual workloads a chart
# produces (a `kind: HelmRelease` CR on its own tells a linter nothing).
#
# For each HelmRelease it uses the release's own spec.values and resolves the
# chart URL from the HelmRepository named in spec.chart.spec.sourceRef.
#
# Usage: scripts/lint/render-helmreleases.sh [OUT_DIR]   (default: rendered/helm)
set -euo pipefail

OUT_DIR="${1:-rendered/helm}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
mkdir -p "$OUT_DIR"

# Candidate files (yq does the real kind-filtering below). Skip cluster/flux-system:
# those are Flux's own bootstrap controllers, not charts we manage.
mapfile -t FILES < <(grep -rl --include='*.yaml' 'kind: HelmRe' . | grep -v '/flux-system/' | sort -u)

# Build "<namespace>/<name>" -> chart repo URL for every HelmRepository object.
declare -A REPO_URL
for f in "${FILES[@]}"; do
  while IFS=$'\t' read -r key url; do
    [ -n "$key" ] && REPO_URL["$key"]="$url"
  done < <(yq -N 'select(.kind=="HelmRepository") | (.metadata.namespace + "/" + .metadata.name) + "\t" + .spec.url' "$f")
done

rc=0
for f in "${FILES[@]}"; do
  while IFS= read -r idx; do
    [ -n "$idx" ] || continue
    name=$(yq -N "select(document_index==$idx) | .metadata.name" "$f")
    ns=$(yq -N "select(document_index==$idx) | .metadata.namespace" "$f")
    chart=$(yq -N "select(document_index==$idx) | .spec.chart.spec.chart" "$f")
    version=$(yq -N "select(document_index==$idx) | .spec.chart.spec.version // \"\"" "$f")
    srcname=$(yq -N "select(document_index==$idx) | .spec.chart.spec.sourceRef.name" "$f")
    srcns=$(yq -N "select(document_index==$idx) | .spec.chart.spec.sourceRef.namespace // \"$ns\"" "$f")
    url="${REPO_URL[$srcns/$srcname]:-}"

    if [ -z "$url" ]; then
      echo "WARN: no HelmRepository URL for $name in $f (sourceRef $srcns/$srcname); skipping" >&2
      continue
    fi

    values="$(mktemp)"
    yq -N "select(document_index==$idx) | .spec.values // {}" "$f" > "$values"

    out="$OUT_DIR/$(printf '%s' "${f#./}" | tr '/' '_')__${name}.yaml"
    echo "Rendering $name (chart=$chart, version=${version:-latest}, repo=$url)" >&2
    if ! helm template "$name" "$chart" \
        --repo "$url" \
        ${version:+--version "$version"} \
        --namespace "$ns" \
        --include-crds \
        --values "$values" >"$out" 2>"$out.err"; then
      echo "ERROR: helm template failed for $name ($f):" >&2
      sed 's/^/    /' "$out.err" >&2
      rc=1
    fi
    rm -f "$values" "$out.err"
  done < <(yq -N 'select(.kind=="HelmRelease") | document_index' "$f")
done

echo "Rendered manifests written to $OUT_DIR" >&2
exit $rc
