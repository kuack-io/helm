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
