# Makefile
# Build and deployment commands for local development cluster

.PHONY: help cluster-up cluster-down install-knative status registry-test octant clean verify-tools wait-for-knative

# Default target
.DEFAULT_GOAL := help

# Variables
CLUSTER_NAME := dev-cluster
REGISTRY_PORT := 5000
OCTANT_PORT := 7777
K3D_CONFIG := k3d-config.yaml

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(GREEN)Local Development Cluster Management$(NC)"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

verify-tools: ## Verify required tools are installed
	@echo "$(GREEN)Verifying required tools...$(NC)"
	@which docker > /dev/null || (echo "$(RED)Docker not found$(NC)" && exit 1)
	@which k3d > /dev/null || (echo "$(RED)k3d not found$(NC)" && exit 1)
	@which kubectl > /dev/null || (echo "$(RED)kubectl not found$(NC)" && exit 1)
	@which tilt > /dev/null || (echo "$(RED)Tilt not found$(NC)" && exit 1)
	@echo "$(GREEN)All required tools found$(NC)"

cluster-up: verify-tools ## Create k3d cluster with registry
	@echo "$(GREEN)Creating k3d cluster with registry...$(NC)"
	@k3d cluster create --config $(K3D_CONFIG)
	@echo "$(GREEN)Cluster created successfully$(NC)"
	@echo "Registry available at: registry.localhost:$(REGISTRY_PORT)"
	@echo "Run 'make install-knative' to install Knative and Contour"

cluster-down: ## Delete k3d cluster
	@echo "$(YELLOW)Deleting k3d cluster...$(NC)"
	@k3d cluster delete $(CLUSTER_NAME)
	@echo "$(GREEN)Cluster deleted$(NC)"

install-knative: ## Install Knative Serving with Kourier
	@echo "$(GREEN)Installing Knative Serving...$(NC)"
	@kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.13.0/serving-crds.yaml
	@kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.13.0/serving-core.yaml
	@echo "$(GREEN)Waiting for Knative Serving to be ready...$(NC)"
	@kubectl wait --for=condition=Ready pods --all -n knative-serving --timeout=300s
	@echo "$(GREEN)Installing Kourier networking...$(NC)"
	@kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.13.0/kourier.yaml
	@kubectl wait --for=condition=Ready pods --all -n kourier-system --timeout=300s
	@echo "$(GREEN)Configuring Knative to use Kourier...$(NC)"
	@kubectl patch configmap/config-network --namespace knative-serving --type merge --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'
	@kubectl patch configmap/config-domain --namespace knative-serving --type merge --patch '{"data":{"127.0.0.1.sslip.io":""}}'
	@echo "$(GREEN)Knative installation complete$(NC)"

wait-for-knative: ## Wait for Knative to be fully ready
	@echo "$(GREEN)Waiting for all Knative components...$(NC)"
	@kubectl wait --for=condition=Ready pods --all -n knative-serving --timeout=300s
	@echo "$(GREEN)Knative is ready$(NC)"

status: ## Show cluster and services status
	@echo "$(GREEN)Cluster Status:$(NC)"
	@k3d cluster list
	@echo ""
	@echo "$(GREEN)Nodes:$(NC)"
	@kubectl get nodes
	@echo ""
	@echo "$(GREEN)Knative Services:$(NC)"
	@kubectl get ksvc -A || echo "No Knative services found"
	@echo ""
	@echo "$(GREEN)Knative Serving Pods:$(NC)"
	@kubectl get pods -n knative-serving
	@echo ""
	@echo "$(GREEN)Kourier Pods:$(NC)"
	@kubectl get pods -n kourier-system

registry-test: ## Test local registry
	@echo "$(GREEN)Testing local registry...$(NC)"
	@docker pull hello-world:latest
	@docker tag hello-world:latest registry.localhost:$(REGISTRY_PORT)/hello-world:latest
	@docker push registry.localhost:$(REGISTRY_PORT)/hello-world:latest
	@echo "$(GREEN)Registry test successful$(NC)"
	@echo "Image pushed: registry.localhost:$(REGISTRY_PORT)/hello-world:latest"
	@curl -s http://registry.localhost:$(REGISTRY_PORT)/v2/_catalog | jq || echo "Install jq for prettier output"

octant: ## Start Octant dashboard
	@echo "$(GREEN)Starting Octant dashboard on http://localhost:$(OCTANT_PORT)$(NC)"
	@./scripts/start-octant.sh

clean: cluster-down ## Remove cluster and clean up
	@echo "$(GREEN)Cleaning up...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)Cleanup complete$(NC)"

tilt-up: ## Start Tilt for development
	@echo "$(GREEN)Starting Tilt...$(NC)"
	@echo "Tilt UI will be available at http://localhost:10350"
	@tilt up

tilt-down: ## Stop Tilt
	@echo "$(YELLOW)Stopping Tilt...$(NC)"
	@tilt down

logs-knative: ## Show Knative serving logs
	@kubectl logs -n knative-serving -l app.kubernetes.io/name=controller --tail=50 -f

logs-contour: ## Show Contour logs
	@kubectl logs -n projectcontour -l app=contour --tail=50 -f

quick-start: cluster-up install-knative registry-test ## Complete cluster setup (cluster + knative + registry test)
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)Cluster setup complete!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Run 'make octant' to start the dashboard"
	@echo "  2. Run 'tilt up' to start development"
	@echo "  3. Deploy services to registry.localhost:$(REGISTRY_PORT)"