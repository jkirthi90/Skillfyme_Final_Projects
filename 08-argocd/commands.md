# Argo CD Commands

## Install

```bash
kubectl create namespace argocd

kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl get pods -n argocd
kubectl get svc -n argocd
```

## Log in

```bash
# Initial password for user "admin"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d ; echo

# Option A: NodePort, then open http://<public-ip>:<nodeport>
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'
kubectl get svc argocd-server -n argocd

# Option B: port-forward, then open https://localhost:8080
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Deploy the Nginx app

UI: **Settings → Repositories → Connect Repo** (HTTPS, repo URL), then **Applications → New App** with path `08-argocd/apps/nginx`, then **Sync**.

Or as code:

```bash
kubectl apply -n argocd -f apps/nginx-application.yaml
```

## Check

```bash
kubectl get deployment nginx-deployment
kubectl get pods -l app=nginx -o wide
kubectl get svc nginx-service

argocd login <argocd-server>            # optional CLI
argocd app list
argocd app get nginx-app
argocd app sync nginx-app
```
