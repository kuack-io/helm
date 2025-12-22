# Kuack Helm Chart

This Helm chart deploys the Kuack ecosystem, a Virtual Kubelet provider that enables running Kubernetes pods in the browser via WebAssembly (WASM).

## Quick Start

Install the chart from the GitHub Container Registry:

```bash
helm install kuack oci://ghcr.io/kuack-io/charts/kuack
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

    Open <http://localhost:8080> in your browser. You should see the Kuack Agent interface waiting for tasks. Type in the address where the Node service can be reached (i.e. <ws://127.0.0.1:8081> for port-forwarding above).

3. **Run an Example**

    To see Kuack in action, you can use the **[Kuack Checker](https://github.com/kuack-io/checker)**.

    Create a pod that tolerates the virtual-kubelet taint and selects the wasm provider:

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: checker
    spec:
      nodeSelector:
        type: virtual-kubelet
      tolerations:
        - key: "virtual-kubelet.io/provider"
          operator: "Equal"
          value: "wasm"
          effect: "NoSchedule"
      containers:
        - name: checker
          image: ghcr.io/kuack-io/checker:latest
    ```

    Once deployed, the pod will be scheduled to your browser agent, and Pod will be successfully completed. You can check Console in your browser tab or check the Pod status and logs via `kubectl`.

## Configuration

See [values.yaml](values.yaml) for all options.
