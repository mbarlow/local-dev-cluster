# Complete Start/Stop Workflow

## 🛑 Stop Everything

```bash
# 1. Stop Tilt (if running)
tilt down

# 2. Stop the k3d cluster
make cluster-down
```

## 🚀 Start Everything

```bash
# 1. Start the k3d cluster with registry
make cluster-up

# 2. Install Knative + Kourier (only needed first time or after cluster-down)
make install-knative

# 3. Start Tilt (deploys hello service automatically)
tilt up
```

## 🔄 Restart Just Tilt (cluster stays running)

```bash
# Stop Tilt
tilt down

# Start Tilt again  
tilt up
```

## ✅ Verify Everything Works

```bash
# Check cluster status
make status

# Test the service (after tilt up)
curl -H "Host: hello.default.127.0.0.1.sslip.io" http://localhost:8080
```