#!/bin/bash
# scripts/setup-all.sh
# Complete setup script for local development cluster

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Local Development Cluster Setup${NC}"
echo "================================="
echo ""

# Check for required tools
echo -e "${YELLOW}Checking required tools...${NC}"

check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        echo "Please install $1 and try again"
        exit 1
    else
        echo -e "${GREEN}✓${NC} $1 found"
    fi
}

check_tool docker
check_tool k3d
check_tool kubectl
check_tool tilt

# Optional tools
if command -v octant &> /dev/null; then
    echo -e "${GREEN}✓${NC} octant found (optional)"
else
    echo -e "${YELLOW}!${NC} octant not found (optional - needed for dashboard)"
fi

if command -v jq &> /dev/null; then
    echo -e "${GREEN}✓${NC} jq found (optional)"
else
    echo -e "${YELLOW}!${NC} jq not found (optional - for JSON formatting)"
fi

echo ""

# Configure registry
echo -e "${YELLOW}Configuring local registry...${NC}"
./scripts/registry-config.sh
echo ""

# Create cluster
echo -e "${YELLOW}Creating k3d cluster...${NC}"
make cluster-up
echo ""

# Install Knative and Contour
echo -e "${YELLOW}Installing Knative and Contour...${NC}"
make install-knative
echo ""

# Test registry
echo -e "${YELLOW}Testing registry...${NC}"
make registry-test
echo ""

# Show status
echo -e "${GREEN}Showing cluster status...${NC}"
make status
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Your local development cluster is ready!"
echo ""
echo "Available endpoints:"
echo "  - Registry: registry.localhost:5000"
echo "  - Services: http://localhost:8080"
echo ""
echo "Next steps:"
echo "  1. Run 'tilt up' to start Tilt development environment"
echo "  2. Run 'make octant' to start Octant dashboard"
echo "  3. Deploy your first service using Knative"
echo ""
echo "To deploy a test service:"
echo "  kubectl apply -f examples/hello-service.yaml"