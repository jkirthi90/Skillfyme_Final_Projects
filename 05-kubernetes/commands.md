# Kubernetes Commands

Reference: https://kubernetes.io/docs/

## Cluster

```bash
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A                     # every pod in every namespace
kubectl get all -n <namespace>
```

## Pods, Deployments, StatefulSets, DaemonSets

```bash
kubectl apply -f nginx-deployment.yaml
kubectl get pods
kubectl get pods --watch
kubectl get deployments
kubectl get statefulsets
kubectl get daemonsets -A

kubectl describe pod <pod>
kubectl logs -f <pod>
kubectl exec -it <pod> -- /bin/bash     # note the "--" before the command
kubectl cp /home/ubuntu/devops.txt <pod>:/home
kubectl delete pod <pod>                # the Deployment creates a replacement

kubectl scale deployment <name> --replicas=4
```

## Services and access

```bash
kubectl get svc
minikube service nginx-service --url    # Minikube: URL for a NodePort service
kubectl port-forward --address 0.0.0.0 svc/<service> <local-port>:<service-port>
```

## Rolling update and rollback

```bash
kubectl set image deployment/nginx-deployment nginx=nginx:1.25
kubectl rollout status deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment
kubectl rollout undo deployment/nginx-deployment
```

## Ingress

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
kubectl apply -f manifests/nginx-ingress.yaml
# On a self-managed cluster without a cloud load balancer:
kubectl patch svc ingress-nginx-controller -n ingress-nginx --type=merge \
  -p '{"spec": {"externalIPs": ["<master-public-ip>"]}}'
```

## Horizontal Pod Autoscaler load test

```bash
minikube addons enable metrics-server   # Minikube
# kubeadm cluster:
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl apply -f manifests/hpa-php-apache.yaml
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
kubectl get hpa

# Generate load (Ctrl+C to stop)
kubectl run -it --rm load-generator --image=busybox -- /bin/sh -c \
  "while true; do wget -q -O- http://php-apache; done"

kubectl get hpa --watch
```

What I saw:

```
NAME         REFERENCE               TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache   170%/50%   1         10        1          3m12s
php-apache   Deployment/php-apache   170%/50%   1         10        4          3m15s
php-apache   Deployment/php-apache   0%/50%     1         10        4          6m
php-apache   Deployment/php-apache   0%/50%     1         10        1          11m
```

Scale-down waits about 5 minutes after the load stops, so pods don't flap.

## Storage

```bash
kubectl apply -f manifests/postgres/configmap.yaml
kubectl apply -f manifests/postgres/storage.yaml
kubectl apply -f manifests/postgres/deployment.yaml
kubectl get pv,pvc
kubectl exec -it <postgres-pod> -- psql -h localhost -U admin --password -p 5432 postgresdb
```

## Helm

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

helm install nginx helm/nginx-basic
helm install nginx-helm helm/nginx-values
helm install nginx-helm helm/nginx-values --set image=nginx:1.27   # override a value
helm list
helm uninstall <release>
```
