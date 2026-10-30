# Monitoring Commands

## Install Helm

```bash
sudo snap install helm --classic
helm version
```

## Option 1 — kube-prometheus-stack (kubeadm cluster)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm install monitoring prometheus-community/kube-prometheus-stack --namespace monitoring

kubectl get pods -n monitoring
```

Grafana admin password (user `admin`):

```bash
kubectl --namespace monitoring get secrets monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```

Expose Grafana and Prometheus with NodePort:

```bash
kubectl patch svc monitoring-grafana -n monitoring \
  -p '{"spec":{"type":"NodePort"}}'

kubectl patch svc monitoring-kube-prometheus-prometheus -n monitoring \
  -p '{"spec":{"type":"NodePort"}}'

kubectl get svc -n monitoring           # note the NodePort numbers
# open http://<node-public-ip>:<nodeport>
```

Open the matching ports in the EC2 security group.

## Option 2 — separate Prometheus and Grafana charts (Minikube)

Prometheus:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus

kubectl expose service prometheus-server --type=NodePort --target-port=9090 --name=prometheus-server-np
kubectl get svc
minikube service prometheus-server-np --url

# reach it from outside the VM
kubectl port-forward --address 0.0.0.0 svc/prometheus-server-np 8888:80
# open http://<vm-ip>:8888
```

Grafana:

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana

kubectl expose service grafana --type=NodePort --target-port=3000 --name=grafana-np

kubectl get secret --namespace default grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

minikube service grafana-np --url
kubectl port-forward --address 0.0.0.0 svc/grafana-np 3000:80
# open http://<vm-ip>:3000, then add Prometheus as a data source:
#   http://prometheus-server.default.svc.cluster.local
```
