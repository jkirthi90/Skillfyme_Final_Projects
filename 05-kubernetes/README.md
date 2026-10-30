# 05 – Kubernetes & Helm

- Cluster setup: [Minikube](./cluster-setup/minikube.md), [kubeadm](./cluster-setup/kubeadm.md) (master + 2 workers), [EKS](./cluster-setup/eks.md)
- [manifests/](./manifests) – deployment, service, ingress, HPA, StatefulSet, PV/PVC
- [helm/](./helm) – nginx chart, with and without values.yaml
- HPA load test: scaled 1 → 4 pods at 170% CPU, back to 1

**Projects**
1. [01-node-mongodb](./projects/01-node-mongodb) – web app + MongoDB, Secret, ConfigMap, PVC
2. [02-react-springboot-postgres](./projects/02-react-springboot-postgres) – React + Spring Boot + Postgres StatefulSet, Ingress, probes
3. [03-todo-fastapi-postgres](./projects/03-todo-fastapi-postgres) – same app on Compose and K8s, init script via ConfigMap

Commands: [commands.md](./commands.md)
