#!/bin/bash
# scripts/cleanup.sh
# Clean up any existing k3d resources before creating new cluster

set -euo pipefail

echo "Cleaning up existing k3d resources..."

# Delete any existing cluster with our name
k3d cluster delete dev-cluster 2>/dev/null || true

# Stop and remove any k3d containers
docker stop $(docker ps -q --filter name=k3d) 2>/dev/null || true
docker rm $(docker ps -aq --filter name=k3d) 2>/dev/null || true

# Clean up registry container
docker stop registry.localhost 2>/dev/null || true
docker rm registry.localhost 2>/dev/null || true

# Remove k3d networks
docker network rm dev-network 2>/dev/null || true
docker network rm k3d-dev-cluster 2>/dev/null || true

echo "Cleanup complete"