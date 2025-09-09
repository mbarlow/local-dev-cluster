#!/bin/bash
# scripts/start-octant.sh
# Start Octant dashboard for Kubernetes cluster visualization

set -euo pipefail

OCTANT_PORT="${OCTANT_PORT:-7777}"
OCTANT_HOST="${OCTANT_HOST:-0.0.0.0}"

echo "Starting Octant dashboard on http://localhost:${OCTANT_PORT}"

# Check if Octant is installed
if ! command -v octant &> /dev/null; then
    echo "Error: Octant is not installed"
    echo "Please install Octant first:"
    echo "  brew install octant  # macOS"
    echo "  or download from: https://github.com/vmware-tanzu/octant/releases"
    exit 1
fi

# Check kubeconfig
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster"
    echo "Please ensure your cluster is running: make cluster-up"
    exit 1
fi

# Start Octant
echo "Launching Octant..."
octant \
    --disable-open-browser \
    --listener-addr="${OCTANT_HOST}:${OCTANT_PORT}" \
    --verbose