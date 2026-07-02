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
# Emit one tab-separated record per document (kind, namespace, name, url) and
# filter in the shell. This avoids `select(...) | a + "/" + b` forms, which
# behave inconsistently across yq versions — on v4.44.x they leaked the
# filtered-out documents and erred on the null .spec.url of the HelmRelease,
# leaving the map empty.
declare -A REPO_URL
while IFS= read -r f; do
  while IFS=$'\t' read -r kind ns name url; do
    [ "$kind" = "HelmRepository" ] && [ -n "$name" ] && REPO_URL["$ns/$name"]="$url"
  done < <(yq -N '[.kind, .metadata.namespace // "", .metadata.name // "", .spec.url // ""] | @tsv' "$f")
done < <(git ls-files -z '*.yaml' | xargs -0 grep -lE '^kind: HelmRepository')

mkdir -p "$(dirname "$OUT")"
: >"$OUT"

while IFS= read -r idx; do
  [ -n "$idx" ] || continue
  # Extract just this HelmRelease document to its own file and query that.
  # Querying a single-document file avoids a yq quirk (seen on v4.44.x) where
  # `select(document_index==N) | .x // "default"` also emits the fallback for
  # the filtered-out documents, duplicating the value (e.g. srcns became
  # "monitoring\nmonitoring", breaking the HelmRepository URL lookup).
  release="$(mktemp)"
  yq -N "select(document_index==$idx)" "$SRC" >"$release"

  name=$(yq -N '.metadata.name' "$release")
  ns=$(yq -N '.metadata.namespace' "$release")
  chart=$(yq -N '.spec.chart.spec.chart' "$release")
  version=$(yq -N '.spec.chart.spec.version // ""' "$release")
  srcname=$(yq -N '.spec.chart.spec.sourceRef.name' "$release")
  srcns=$(yq -N ".spec.chart.spec.sourceRef.namespace // \"$ns\"" "$release")
  url="${REPO_URL[$srcns/$srcname]:-}"
  if [ -z "$url" ]; then
    echo "ERROR: no HelmRepository URL for $name (sourceRef $srcns/$srcname) referenced by $SRC" >&2
    exit 1
  fi

  values="$(mktemp)"
  yq -N '.spec.values // {}' "$release" >"$values"
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
