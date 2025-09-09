# Local Development Cluster

A production-like Kubernetes development environment with k3d, Knative, and Kourier.

## Features

- **k3d**: Lightweight Kubernetes cluster in Docker
- **Knative Serving**: Serverless workloads with autoscaling  
- **Kourier**: Simple ingress for Knative services
- **Local Registry**: Push and pull images at `registry.localhost:5000`
- **sslip.io**: Automatic DNS for local development
- **Tilt + Octant**: Development workflow and cluster visualization

## ⚡ 5-Minute Quickstart

```bash
# 1. Clone the repo
git clone https://github.com/mbarlow/local-dev-cluster.git
cd local-dev-cluster

# 2. Install dependencies (requires Docker)
# - k3d: curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
# - kubectl: curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && sudo install kubectl /usr/local/bin/

# 3. One-command setup
make quick-start

# 4. Deploy your first service
kubectl apply -f examples/hello-service.yaml

# 5. Test it works
curl -H "Host: hello.default.127.0.0.1.sslip.io" http://localhost:8080
# Returns: Hello Local Dev Cluster!
```

**That's it!** Your serverless development environment is ready.

---

## Detailed Setup

### Required Tools

**Core requirements:**
- **Docker**: [Install Docker](https://docs.docker.com/get-docker/)
- **k3d**: `curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash`
- **kubectl**: [Install kubectl](https://kubernetes.io/docs/tasks/tools/)

**Optional tools:**
- **Tilt**: [Install Tilt](https://docs.tilt.dev/install.html) (hot-reload development)
- **Octant**: [Install Octant](https://octant.dev/) (cluster dashboard)
- **jq**: `brew install jq` or `sudo apt-get install jq` (JSON formatting)

### Manual Setup Steps

```bash
# 1. Configure local registry (sets up Docker + /etc/hosts)
./scripts/registry-config.sh

# 2. Create k3d cluster with local registry
make cluster-up

# 3. Install Knative + Kourier networking
make install-knative

# 4. Verify everything is running
make status
```

### Development Workflow

```bash
# Start Tilt for hot-reload development
tilt up

# Start Octant dashboard (optional, requires octant installed)  
make octant
```

**Access Points:**
- **Services**: http://localhost:8080 (k3d load balancer)
- **Tilt UI**: http://localhost:10350 (development dashboard)  
- **Octant**: http://localhost:7777 (cluster visualization)
- **Registry**: http://registry.localhost:5000 (local image registry)

## Usage

### Deploy a Knative Service

Create a simple service:

```yaml
# hello-service.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hello
  namespace: default
spec:
  template:
    spec:
      containers:
      - image: gcr.io/knative-samples/helloworld-go
        env:
        - name: TARGET
          value: "Local Dev Cluster"
```

Deploy:

```bash
kubectl apply -f hello-service.yaml

# Get service URL (will use sslip.io domain)
kubectl get ksvc hello

# Test the service
curl -H "Host: hello.default.127.0.0.1.sslip.io" http://localhost:8080
```

### Using the Local Registry

```bash
# Tag your image
docker tag myapp:latest registry.localhost:5000/myapp:latest

# Push to local registry
docker push registry.localhost:5000/myapp:latest

# Use in Kubernetes manifests
image: registry.localhost:5000/myapp:latest
```

### Tilt Development

**Yes!** Tilt automatically deploys and manages the example service:

```bash
tilt up
# - Deploys examples/hello-service.yaml automatically
# - Provides web UI at http://localhost:10350
# - Shows real-time logs and status
# - Automatically redeploys on changes
```

To add your own services, edit the `Tiltfile` and add your manifests.

## Project Structure

```
local-dev-cluster/
├── README.md                # This file  
├── Makefile                # Build and deployment commands
├── Tiltfile                # Tilt development configuration
├── k3d-config.yaml         # k3d cluster configuration
├── examples/               # Example Knative services
│   └── hello-service.yaml  # Hello world service
└── scripts/                # Utility scripts
    ├── registry-config.sh  # Configure local registry
    ├── start-octant.sh     # Launch Octant dashboard
    ├── setup-all.sh        # Complete automated setup
    └── cleanup.sh          # Clean up cluster resources
```

## Makefile Commands

```bash
make help            # Show all available commands
make cluster-up      # Create k3d cluster with registry
make cluster-down    # Delete k3d cluster
make install-knative # Install Knative and Contour
make status         # Show cluster and services status
make registry-test  # Test local registry
make octant         # Start Octant dashboard
make clean          # Remove cluster and clean up
```

## Troubleshooting

### Registry Connection Issues

```bash
# Verify registry is running
docker ps | grep registry

# Test registry endpoint
curl http://registry.localhost:5000/v2/_catalog

# Check /etc/hosts
cat /etc/hosts | grep registry.localhost
```

### Knative Service Not Ready

```bash
# Check Knative pods
kubectl get pods -n knative-serving

# Check Kourier networking
kubectl get pods -n kourier-system

# View service details
kubectl describe ksvc <service-name>
```

### Port Conflicts

If ports 8080, 8443, or 5000 are in use:

1. Stop conflicting services
2. Or modify `k3d-config.yaml` to use different ports

### Cluster Won't Start

```bash
# Clean up and retry
make clean
docker system prune -a
make cluster-up
```

## Advanced Configuration

### Custom Domain

Edit `manifests/knative/config-domain.yaml`:

```yaml
data:
  example.com: ""
  local.dev: ""
```

### Resource Limits

Modify k3d cluster resources in `k3d-config.yaml`:

```yaml
agents: 3  # Increase worker nodes
```

### Additional Ingress Ports

Add to `k3d-config.yaml`:

```yaml
ports:
  - port: 9000:9000
    nodeFilters:
      - loadbalancer
```

## Development Workflow

1. **Write Code**: Make changes to your service
2. **Tilt Sync**: Tilt automatically rebuilds and deploys
3. **Test Locally**: Access via configured ingress
4. **Monitor**: Use Octant to visualize cluster state
5. **Debug**: Check logs with `kubectl logs` or Octant

## Resources

- [k3d Documentation](https://k3d.io/)
- [Knative Docs](https://knative.dev/docs/)
- [Kourier Documentation](https://github.com/knative/net-kourier)
- [Tilt Documentation](https://docs.tilt.dev/)
- [Octant Documentation](https://octant.dev/docs/)

## License

MIT