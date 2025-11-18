---
title: "Building a Production-Ready Kubernetes Cluster from Scratch"
description: "A deep dive into setting up a multi-node Kubernetes cluster with best practices for security, networking, and observability"
date: 2025-01-18
tags: ["kubernetes", "devops", "infrastructure", "containers"]
---

After years of running applications in various environments, I finally decided to build my own production-ready Kubernetes cluster from scratch. This post walks through the journey, challenges, and lessons learned.

## Why Kubernetes?

Kubernetes has become the de facto standard for container orchestration. But beyond the hype, here's what sold me:

- **Declarative configuration** - Define desired state, let K8s handle the rest
- **Self-healing** - Automatic restarts, replacements, and rescheduling
- **Horizontal scaling** - Scale applications up or down with a single command
- **Service discovery** - Built-in DNS and load balancing
- **Rolling updates** - Zero-downtime deployments

> **💡 Pro Tip**
>
> Before diving into Kubernetes, make sure you're comfortable with Docker and containerization concepts. K8s adds significant complexity, so ensure you actually need it for your use case.

## Architecture Overview

My cluster consists of three nodes:

| Node Type | Hostname | IP Address | Role | Specs |
|-----------|----------|------------|------|-------|
| Control Plane | k8s-master-01 | 192.168.1.10 | Master | 4 vCPU, 8GB RAM |
| Worker | k8s-worker-01 | 192.168.1.11 | Worker | 4 vCPU, 16GB RAM |
| Worker | k8s-worker-02 | 192.168.1.12 | Worker | 4 vCPU, 16GB RAM |

## Initial Setup

### Preparing the Nodes

First, I updated all nodes and installed required dependencies:

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y apt-transport-https ca-certificates curl

# Disable swap (Kubernetes requirement)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Load kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

### Container Runtime: containerd

I chose `containerd` as the container runtime since it's lightweight and the current recommended option:

```bash
# Install containerd
sudo apt install -y containerd

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable systemd cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd
```

### Installing kubeadm, kubelet, and kubectl

```bash
# Add Kubernetes apt repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes components
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Hold packages at current version
sudo apt-mark hold kubelet kubeadm kubectl
```

## Initializing the Control Plane

On the master node, I initialized the cluster:

```bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.1.10 \
  --control-plane-endpoint=k8s-master-01
```

After successful initialization, kubeadm outputs a join command. **Save this immediately** - you'll need it to add worker nodes:

```bash
kubeadm join k8s-master-01:6443 --token abc123.xyz789 \
  --discovery-token-ca-cert-hash sha256:1234567890abcdef...
```

Set up `kubectl` access:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Installing a CNI Plugin: Cilium

I chose Cilium for networking because of its eBPF-based implementation and excellent observability features:

```bash
# Install Cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz

# Install Cilium
cilium install --version 1.14.5
```

Verify the installation:

```bash
cilium status --wait
```

Output should look like:

```
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    OK
 \__/¯¯\__/    Hubble Relay:       OK
    \__/

Deployment             cilium-operator    Desired: 1, Ready: 1/1, Available: 1/1
DaemonSet              cilium             Desired: 3, Ready: 3/3, Available: 3/3
```

## Joining Worker Nodes

On each worker node, run the join command from earlier:

```bash
sudo kubeadm join k8s-master-01:6443 \
  --token abc123.xyz789 \
  --discovery-token-ca-cert-hash sha256:1234567890abcdef...
```

Back on the master, verify all nodes are ready:

```bash
kubectl get nodes
```

```
NAME              STATUS   ROLES           AGE   VERSION
k8s-master-01     Ready    control-plane   10m   v1.29.0
k8s-worker-01     Ready    <none>          5m    v1.29.0
k8s-worker-02     Ready    <none>          5m    v1.29.0
```

## Deploying a Test Application

Let's deploy a simple nginx application to test everything:

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
```

Apply the configuration:

```bash
kubectl apply -f nginx-deployment.yaml
```

Check the deployment:

```bash
kubectl get pods -o wide
```

```
NAME                               READY   STATUS    RESTARTS   AGE   IP           NODE
nginx-deployment-6d4cf56db6-7xqwm  1/1     Running   0          30s   10.244.1.5   k8s-worker-01
nginx-deployment-6d4cf56db6-hjk9p  1/1     Running   0          30s   10.244.2.3   k8s-worker-02
nginx-deployment-6d4cf56db6-mnbvc  1/1     Running   0          30s   10.244.1.6   k8s-worker-01
```

## Setting Up Ingress with Traefik

To expose services externally, I installed Traefik as the ingress controller:

```bash
# Add Traefik Helm repository
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Install Traefik
helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set ports.web.exposedPort=80 \
  --set ports.websecure.exposedPort=443
```

Create an IngressRoute for nginx:

```yaml
# nginx-ingress.yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: nginx-ingress
  namespace: default
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`nginx.local.dev`)
    kind: Rule
    services:
    - name: nginx-service
      port: 80
```

```bash
kubectl apply -f nginx-ingress.yaml
```

## Monitoring with Prometheus and Grafana

No cluster is complete without proper monitoring. I used the kube-prometheus-stack:

```bash
# Add Prometheus community Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install the stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin
```

This gives you:
- **Prometheus** - Metrics collection and storage
- **Grafana** - Beautiful dashboards and visualizations
- **AlertManager** - Alert routing and management
- **Node Exporter** - Hardware and OS metrics
- **kube-state-metrics** - Kubernetes object metrics

Access Grafana:

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Navigate to `http://localhost:3000` (admin/admin)

## Persistent Storage with Longhorn

For persistent storage, I deployed Longhorn:

```bash
# Install Longhorn
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.3/deploy/longhorn.yaml

# Wait for deployment
kubectl -n longhorn-system get pods --watch
```

Create a PersistentVolumeClaim:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 10Gi
```

## Backup Strategy

I automated etcd backups with a CronJob:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: etcd-backup
  namespace: kube-system
spec:
  schedule: "0 2 * * *"  # 2 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: bitnami/etcd:3.5
            command:
            - /bin/sh
            - -c
            - |
              etcdctl snapshot save /backup/etcd-$(date +%Y%m%d-%H%M%S).db \
                --endpoints=https://192.168.1.10:2379 \
                --cacert=/etc/kubernetes/pki/etcd/ca.crt \
                --cert=/etc/kubernetes/pki/etcd/server.crt \
                --key=/etc/kubernetes/pki/etcd/server.key
            volumeMounts:
            - name: backup
              mountPath: /backup
          restartPolicy: OnFailure
          volumes:
          - name: backup
            hostPath:
              path: /var/backups/etcd
```

## Lessons Learned

1. **Start small** - I initially tried to set up everything at once. Bad idea. Build incrementally.

2. **Resource requests/limits matter** - Without them, one pod can starve others. Always set them.

3. **Network policies are crucial** - Don't leave your cluster wide open. Implement network policies from day one.

4. **Monitoring is not optional** - You need visibility into what's happening. Install monitoring early.

5. **Backup everything** - Including etcd, persistent volumes, and configuration files.

## What's Next?

I'm currently working on:

- **GitOps with ArgoCD** - Declarative deployments from Git repositories
- **Service Mesh with Istio** - Advanced traffic management and observability
- **Autoscaling** - Implementing HPA and cluster autoscaling
- **Security hardening** - Pod security policies, RBAC fine-tuning, and network policies

## Useful Commands

Here's a cheat sheet I reference constantly:

```bash
# Get all resources in all namespaces
kubectl get all -A

# Describe a pod for troubleshooting
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name> -f

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/sh

# Get events sorted by timestamp
kubectl get events --sort-by='.lastTimestamp'

# Drain a node for maintenance
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Check cluster health
kubectl get componentstatuses

# View resource usage
kubectl top nodes
kubectl top pods
```

## Conclusion

Building a Kubernetes cluster from scratch is challenging but incredibly rewarding. You gain deep understanding of how everything fits together - from container runtimes to network plugins to storage provisioners.

The initial time investment pays off when you can confidently troubleshoot issues, optimize performance, and understand exactly what's running in your cluster.

If you're considering this journey, my advice: **Do it**. The learning experience is invaluable.

Got questions about my setup? Find me on [GitHub](https://github.com/DylanMunyard) or check out my [other posts](/posts).

---

**Resources that helped me:**
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kelsey Hightower's Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [Cilium Documentation](https://docs.cilium.io/)
- [Longhorn Docs](https://longhorn.io/docs/)
