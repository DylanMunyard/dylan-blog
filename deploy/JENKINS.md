# Jenkins CI/CD — blog

Jenkins runs on the local k8s cluster (the same `bethany` node it deploys
to) and uses **in-cluster ServiceAccount auth** — no kubeconfig credential to
manage. The Jenkins agent pod is launched into the `blog` namespace under the
`blog-deployer` ServiceAccount; `kubectl` inside the pod authenticates with
the auto-mounted token.

The pipeline is a single component: build the Astro static site into an nginx
image, push it to Docker Hub, then `kubectl apply` + `rollout restart` the
`blog` Deployment.

---

## 1. One-time cluster bootstrap

Apply the namespace, ServiceAccount, Role, RoleBinding, and the internal
Traefik ingress from a laptop with admin kubeconfig:

```bash
kubectl apply -f deploy/k8s/rbac.yaml
kubectl apply -f deploy/k8s/blog-ingress.yaml
```

The ingress is applied manually (CI only touches `blog-deployment.yaml`), so
it isn't disturbed by pipeline runs. It routes `https://blog.home.net`
(internal `websecure` entrypoint) to the `blog-service`.

---

## 2. Configure Docker Hub credentials in Jenkins

The Jenkinsfile pushes to `dylanmunyard/dylan-blog:latest` using a Docker Hub
Access Token. This reuses the **existing shared** `dylanmunyard-dockerhub-pat`
credential already configured in Jenkins for other apps on this cluster — no
new credential is needed.

If for some reason that credential is missing, recreate it:

1. [Docker Hub > Account Settings > Security](https://hub.docker.com/settings/security) → **New Access Token**
2. Description `jenkins`, **Read/Write** permissions, copy the token.
3. In **Jenkins > Manage Jenkins > Credentials**, add a **Username with password** credential:
   - **Username**: `dylanmunyard`
   - **Password**: the access token
   - **ID**: `dylanmunyard-dockerhub-pat`

---

## 3. Configure the Kubernetes cloud in Jenkins

The `Local k8s` cloud is already configured (shared across every app on this
cluster). No per-app config is required — the Jenkinsfile sets
`namespace 'blog'` on each agent block. If the `Local k8s` cloud restricts its
allowed-namespaces list, add `blog` to it: **Manage Jenkins > Clouds >
Local k8s > Kubernetes Namespace**.

---

## First deploy

Once `rbac.yaml` is applied and the Docker Hub credential exists, trigger a
build (push to the repo, or run the job manually). To force a build/deploy
when no relevant files changed, run the job with the `BUILD_ALL` parameter
checked.
