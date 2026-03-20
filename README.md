# Kuack Helm Chart

This Helm chart deploys the Kuack ecosystem, a Virtual Kubelet provider that enables running Kubernetes pods in the browser via WebAssembly (WASM).

## Quick Start

Install the chart from the GitHub Container Registry:

```bash
helm install kuack oci://ghcr.io/kuack-io/charts/kuack --wait
```

## What is installed?

- **[Kuack Node](https://github.com/kuack-io/node)**: Registers as a virtual node in your cluster.
- **[Kuack Agent](https://github.com/kuack-io/agent)**: The server that browser agents connect to.

## Usage

1. **Port-forward Services**

    You need to expose both the Node and Agent services to your local machine.

    Forward the Node service (API):

    ```bash
    kubectl port-forward service/kuack-node 8081:8080
    ```

    Forward the Agent service (UI):

    ```bash
    kubectl port-forward service/kuack-agent 8080:8080
    ```

2. **Connect a Browser Agent**

    Open <http://localhost:8080> in your browser. You should see the Kuack Agent interface waiting for tasks. Type in the address where the Node service can be reached (i.e. `ws://127.0.0.1:8081` for port-forwarding above).

3. **Run an Example**

    To see Kuack in action, you can use the **[Kuack Checker](https://github.com/kuack-io/checker)**.

    Create a pod that tolerates the kuack-node taint and selects the kuack provider:

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: checker
    spec:
      nodeSelector:
        kuack.io/node-type: kuack-node
      tolerations:
        - key: "kuack.io/provider"
          operator: "Equal"
          value: "kuack"
          effect: "NoSchedule"
      containers:
        - name: checker
          image: ghcr.io/kuack-io/checker:latest
          env:
            - name: TARGET_URL
              value: "https://kuack.io"
    ```

    Once deployed, the pod will be scheduled to your browser agent, and Pod will be successfully completed. You can check Console in your browser tab or check the Pod status and logs via `kubectl`.

    **Note:** Log streaming (`kubectl logs`) will not work in K3s clusters because its implementation for kubelet connectivity (using a custom remotedialer tunnel) is non-standard. Support for K3s will be added in later releases. For now, please use Minikube, Kind, EKS, GKE, or other non-Rancher clusters.

## Configuration

See [values.yaml](values.yaml) for all options.

## Valkey (Cache Layer)

This chart uses [Valkey](https://valkey.io/) as the caching layer for the registry service.

### Why Valkey instead of Redis?

- **Open Source**: Valkey is a truly open-source fork of Redis, maintained by the Linux Foundation. After Redis changed to a restrictive license (RSALv2/SSPLv1) in March 2024, the community created Valkey to continue open development.
- **Protocol Compatible**: Valkey is 100% wire-compatible with Redis. The registry uses the standard [go-redis](https://github.com/redis/go-redis) client, which works with both Redis and Valkey without any code changes.
- **AWS ECR Images**: The chart uses `public.ecr.aws/valkey/valkey` images to avoid Docker Hub rate limiting.

### Default Setup

By default, Valkey runs in **standalone mode** (single pod):
- No persistence (it's a cache - data can be re-fetched from OCI registries)
- LRU eviction enabled (`maxmemory 2gb`, `allkeys-lru` policy)
- ~2.5GB memory limit (~20% headroom above maxmemory)

This is sufficient for most use cases since cached WASM artifacts can always be re-downloaded if the cache is lost.

### High Availability (Optional)

For HA, enable replication in `values.yaml`:

```yaml
valkey:
  replica:
    enabled: true
    replicas: 2
    persistence:
      size: "5Gi"  # Required for replica sync
```

This creates 1 master + 2 replicas (3 pods total). Note that **replicas require persistent storage** for data synchronization.

### Using External Redis/Valkey

To use an external Redis or Valkey instance, disable the subchart and configure the registry:

```yaml
valkey:
  enabled: false

registry:
  redis:
    addr: "your-redis.example.com:6379"
    password: "your-password"
```

### Future Plans

Native support for managed Redis/Valkey services (e.g., AWS ElastiCache with IAM authentication, Azure Cache for Redis with Entra ID) is not yet implemented but may be added in future releases.

### Uninstall cleanup

By default, the chart enables a small `pre-delete` hook job that deletes the Kuack virtual `Node` object during `helm uninstall`.
This avoids a race where Helm can remove RBAC/service accounts while the node Pod is terminating, preventing the Pod from deleting its own `Node`.
