#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NODES_DIR="$REPO_ROOT/nodes"
ARTIFACTS_DIR="$REPO_ROOT/artifacts"

AURORABOOT_IMAGE="quay.io/kairos/auroraboot@sha256:780e9884a1ac6dc41d03c48e010a2a3d2cb2d2bcd197215b420618dbdd4fca63"
BASE_IMAGE="${KAIROS_BASE_IMAGE:-}"

NODES=(
  master-1
  master-2
  master-3
  worker-1
  worker-2
  worker-3
  data-1
  data-2
  data-3
)

usage() {
  echo "Usage: $0 [node-name]"
  echo "Builds all node ISOs or a single node ISO if node-name is provided."
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  usage
  exit 1
fi

mkdir -p "$ARTIFACTS_DIR"

if [[ -z "$BASE_IMAGE" ]]; then
  echo "Set KAIROS_BASE_IMAGE to a pinned Kairos k3s-capable source image before building." >&2
  exit 1
fi

build_node() {
  local node="$1"
  local cfg="$NODES_DIR/$node.yaml"
  local iso="$ARTIFACTS_DIR/$node.iso"

  if [[ ! -f "$cfg" ]]; then
    echo "Missing node config: $cfg" >&2
    exit 1
  fi

  echo "Building ISO for $node"
  docker run --rm \
    -v "$NODES_DIR:/config" \
    -v "$ARTIFACTS_DIR:/artifacts" \
    "$AURORABOOT_IMAGE" \
    build-iso \
    --cloud-config "/config/$node.yaml" \
    --output /artifacts \
    --override-name "$node.iso" \
    "$BASE_IMAGE"

  if [[ ! -f "$iso" ]]; then
    echo "Expected artifact not found: $iso" >&2
    exit 1
  fi
}

if [[ $# -eq 1 ]]; then
  build_node "$1"
else
  for node in "${NODES[@]}"; do
    build_node "$node"
  done
fi

echo "Build complete. ISOs are in $ARTIFACTS_DIR"
