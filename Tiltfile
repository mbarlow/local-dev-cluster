# Tiltfile
# Tilt configuration for local development with Knative

# Configure k8s context
allow_k8s_contexts('k3d-dev-cluster')

# Local registry configuration  
default_registry('registry.localhost:5000')

# Deploy the example hello service
k8s_yaml('examples/hello-service.yaml')

# Monitoring and observability (optional - only if octant is installed)
local_resource(
    'octant',
    serve_cmd='octant --disable-open-browser --listener-addr=0.0.0.0:7777',
    labels=['monitoring'],
    allow_parallel=True
)

# Knative serving health check
local_resource(
    'knative-health',
    cmd='kubectl get ksvc -A',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    labels=['health']
)

# Registry health check
local_resource(
    'registry-health',
    cmd='curl -s http://registry.localhost:5000/v2/_catalog | jq',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    labels=['health']
)