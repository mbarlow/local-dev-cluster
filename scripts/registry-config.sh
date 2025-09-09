#!/bin/bash
# scripts/registry-config.sh
# Configure local registry for development

set -euo pipefail

REGISTRY_HOST="registry.localhost"
REGISTRY_PORT="5000"

echo "Configuring local registry at ${REGISTRY_HOST}:${REGISTRY_PORT}"

# Add registry to /etc/hosts if not present
if ! grep -q "${REGISTRY_HOST}" /etc/hosts; then
    echo "Adding ${REGISTRY_HOST} to /etc/hosts (requires sudo)"
    echo "127.0.0.1 ${REGISTRY_HOST}" | sudo tee -a /etc/hosts
fi

# Configure Docker daemon for insecure registry
DOCKER_CONFIG_FILE="/etc/docker/daemon.json"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macOS detected - Please configure Docker Desktop manually:"
    echo "1. Open Docker Desktop settings"
    echo "2. Go to Docker Engine"
    echo "3. Add to daemon.json:"
    echo '  "insecure-registries": ["registry.localhost:5000"]'
else
    echo "Configuring Docker daemon for insecure registry"
    if [ -f "$DOCKER_CONFIG_FILE" ]; then
        echo "Backing up existing Docker daemon config"
        sudo cp "$DOCKER_CONFIG_FILE" "${DOCKER_CONFIG_FILE}.bak"
    fi
    
    # Create or update Docker daemon config
    sudo tee "$DOCKER_CONFIG_FILE" > /dev/null <<EOF
{
  "insecure-registries": ["${REGISTRY_HOST}:${REGISTRY_PORT}"]
}
EOF
    
    echo "Restarting Docker daemon"
    sudo systemctl restart docker
fi

echo "Registry configuration complete"