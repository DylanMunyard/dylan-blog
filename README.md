# mkdocs

`mkdocs serve`

## Jenkins
Plugins used:
- [Kubernetes CIL](https://plugins.jenkins.io/kubernetes-cli/) for running kubectl commands
- [Kubernetes](https://github.com/jenkinsci/kubernetes-plugin/tree/master) for running build agents as pods

## Deploy
- Manually deploy [deployment-manager.yaml](./deploy/k8s/deployment-manager.yaml) to create a role binding between the jenkins default service account and the blog namespace. This will give the pod service account used by the Jenkins agents access to deploy the blog.