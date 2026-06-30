#!/usr/bin/env bash
# Render a single Flux HelmRelease file to plain Kubernetes manifests via
# `helm template`, so a linter can inspect the workloads a chart actually
# produces (a `kind: HelmRelease` CR on its own tells a linter nothing).
#
# The chart URL is resolved from the HelmRepository the release references,
# which may live in a different file (e.g. the shared istio repo), so the whole
# repo is scanned for HelmRepository objects.
#
# Usage: render-helmrelease.sh <helmrelease.yaml> <output.yaml>
set -euo pipefail

SRC="$1"
OUT="$2"
cd "$(dirname "${BASH_SOURCE[0]}")/../.." # repo root

# Map "<namespace>/<name>" -> chart repo URL for every HelmRepository object.
declare -A REPO_URL
while IFS= read -r f; do
  while IFS=$'\t' read -r key url; do
    [ -n "$key" ] && REPO_URL["$key"]="$url"
  done < <(yq -N 'select(.kind=="HelmRepository") | (.metadata.namespace + "/" + .metadata.name) + "\t" + .spec.url' "$f")
done < <(git ls-files -z '*.yaml' | xargs -0 grep -lE '^kind: HelmRepository')

mkdir -p "$(dirname "$OUT")"
: >"$OUT"

while IFS= read -r idx; do
  [ -n "$idx" ] || continue
  name=$(yq -N "select(document_index==$idx) | .metadata.name" "$SRC")
  ns=$(yq -N "select(document_index==$idx) | .metadata.namespace" "$SRC")
  chart=$(yq -N "select(document_index==$idx) | .spec.chart.spec.chart" "$SRC")
  version=$(yq -N "select(document_index==$idx) | .spec.chart.spec.version // \"\"" "$SRC")
  srcname=$(yq -N "select(document_index==$idx) | .spec.chart.spec.sourceRef.name" "$SRC")
  srcns=$(yq -N "select(document_index==$idx) | .spec.chart.spec.sourceRef.namespace // \"$ns\"" "$SRC")
  url="${REPO_URL[$srcns/$srcname]:-}"
  if [ -z "$url" ]; then
    echo "ERROR: no HelmRepository URL for $name (sourceRef $srcns/$srcname) referenced by $SRC" >&2
    exit 1
  fi

  values="$(mktemp)"
  yq -N "select(document_index==$idx) | .spec.values // {}" "$SRC" >"$values"
  echo "Rendering $name (chart=$chart, version=${version:-latest}, repo=$url)" >&2

  rendered="$(mktemp)"
  helm template "$name" "$chart" \
    --repo "$url" \
    ${version:+--version "$version"} \
    --namespace "$ns" \
    --include-crds \
    --values "$values" >"$rendered"
  rm -f "$values"

  # Apply any Flux kustomize postRenderers so the linter sees the same patched
  # manifests Flux applies to the cluster (e.g. ignore-check annotations on
  # workloads from charts that expose no annotation values, like csi-driver-nfs).
  release="$(mktemp)"
  yq -N "select(document_index==$idx)" "$SRC" >"$release"
  npatches="$(yq -N '[.spec.postRenderers[].kustomize.patches[]] | length' "$release")"
  if [ "${npatches:-0}" -gt 0 ]; then
    kdir="$(mktemp -d)"
    cp "$rendered" "$kdir/resources.yaml"
    yq -N -o yaml \
      '{"resources": ["resources.yaml"], "patches": [.spec.postRenderers[].kustomize.patches[]]}' \
      "$release" >"$kdir/kustomization.yaml"
    kustomize build "$kdir" >>"$OUT"
    rm -rf "$kdir"
  else
    cat "$rendered" >>"$OUT"
  fi
  rm -f "$release"
  rm -f "$rendered"
done < <(yq -N 'select(.kind=="HelmRelease") | document_index' "$SRC")
