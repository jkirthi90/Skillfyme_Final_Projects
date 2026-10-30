# Kubernetes Deployment – LearnSphere

Deployed the LearnSphere platform on a kubeadm cluster, using images built by the project's GitHub Actions CI.

## Environment
- 2 × AWS EC2 t3.medium (2 vCPU, 4 GB): `k8s-master`, `k8s-worker01`
- Kubernetes (kubeadm), containerd, Calico
- Images: `ghcr.io/jkirthi90/<service>:latest`, built and pushed by the repo's CI pipeline
- Lite stack: MongoDB, PostgreSQL, Redis + 10 app services (Kafka/Elasticsearch not used by the code)

## Changes from the original `k8s/` manifests

| Original | Problem | Fixed in [manifests/](./manifests) |
|----------|---------|-------------------------|
| `kustomization.yaml` lists `secrets.yaml` | File doesn't exist – `kubectl apply -k` fails | Secret created with `kubectl create secret` (step 4) |
| No MongoDB, PostgreSQL or Redis | Every service crash-loops | StatefulSets for MongoDB and PostgreSQL, Deployment for Redis, seeded from the init scripts |
| Images `ghcr.io/skillfyme/...` | Images don't exist | `ghcr.io/jkirthi90/...` from my CI |
| One `DATABASE_URL` for all services | Python needs `postgresql+asyncpg://`, Go needs `?sslmode=disable` | Separate URL per service |
| 2 replicas, 256Mi requests | Doesn't fit 2 × 4 GB nodes | 1 replica, 64Mi requests |
| Ingress with `skillfyme.com` + TLS | Domain not owned | NodePort 30300 (UI), 30400 (API) |
| No StorageClass | PVCs stay Pending on kubeadm | local-path provisioner |

## Build the images with CI (GitHub Actions)

The project's `k8s/` folder only has manifests – the images they point to don't exist, so they're built by the repo's CI pipeline (`.github/workflows/ci.yml`).

**1. Enable Actions** – repo → **Actions** tab → enable workflows.
Pushes made before Actions is enabled don't trigger a run, so push again afterwards.

**2. Set Git identity on the VM and push to `main`**
```bash
git config --global user.name "jkirthi90"
git config --global user.email "<github-email>"
git commit --amend --reset-author --no-edit     # commit had author "Ubuntu"
git push --force origin main                    # triggers CI
```

**3. CI pipeline runs** – *CI — Build, Test & Lint*
- Lint & test: Node.js (8 services), Python (learning-path), Go (assessment-engine)
- Build Docker Images: 10 parallel jobs, push to `ghcr.io/jkirthi90/<service>:latest`
- Trivy security scan

**4. Make the packages public** – GitHub profile → **Packages** → each package → **Package settings → Change visibility → Public**, so the cluster can pull without credentials.

## Steps

**1. Allow pods on the master too** (2 small nodes)
```bash
kubectl taint nodes k8s-master node-role.kubernetes.io/control-plane:NoSchedule-
```

**2. Install a storage provisioner**
```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl get storageclass          # local-path
```

**3. Get the manifests**
```bash
git clone https://github.com/jkirthi90/Skillfyme_Final_Projects.git
cd Skillfyme_Final_Projects/10-capstone-project
```

**4. Namespace, secret and seed scripts**
```bash
kubectl create namespace skillfyme

kubectl -n skillfyme create secret generic skillfyme-secrets \
  --from-literal=DB_USER=skillfyme \
  --from-literal=DB_PASSWORD=skillfyme_secret \
  --from-literal=MONGODB_URI='mongodb://skillfyme:skillfyme_secret@mongodb:27017/skillfyme?authSource=admin' \
  --from-literal=DATABASE_URL='postgresql://skillfyme:skillfyme_secret@postgres:5432/skillfyme' \
  --from-literal=DATABASE_URL_PY='postgresql+asyncpg://skillfyme:skillfyme_secret@postgres:5432/skillfyme' \
  --from-literal=DATABASE_URL_GO='postgres://skillfyme:skillfyme_secret@postgres:5432/skillfyme?sslmode=disable' \
  --from-literal=JWT_SECRET="$(openssl rand -hex 32)" \
  --from-literal=STRIPE_SECRET_KEY=sk_test_placeholder \
  --from-literal=SMTP_HOST=smtp.mailtrap.io --from-literal=SMTP_PORT=587 \
  --from-literal=SMTP_USER=placeholder --from-literal=SMTP_PASS=placeholder \
  --from-literal=FROM_EMAIL=noreply@skillfyme.com

kubectl -n skillfyme create configmap postgres-init --from-file=init.sql=docker-compose/postgres-init.sql
kubectl -n skillfyme create configmap mongo-init --from-file=$HOME/Project-1-LearnSphere_Skillfyme/scripts/mongo-init.js
```
The Postgres seed uses the corrected script from [docker-compose/](../docker-compose).

**5. Deploy**
```bash
kubectl apply -k kubernetes/manifests
kubectl get pods -n skillfyme -w          # wait until all are Running / 1/1
```

**6. Verify**
```bash
kubectl get all,pvc -n skillfyme
curl localhost:30400/health
curl localhost:30400/api/courses | head -c 200
kubectl -n skillfyme exec postgres-0 -- psql -U skillfyme -d skillfyme -tAc 'SELECT count(*) FROM learning_paths;'
```
UI: `http://<node-public-ip>:30300` (open 30300 and 30400 in the security group, from your IP only)

## Troubleshooting
| Status | Check |
|--------|-------|
| `ImagePullBackOff` | GHCR packages must be **Public**; image name matches `kubectl describe pod` |
| `Pending` | `kubectl describe pod` – memory, or PVC not bound (`kubectl get pvc`) |
| `CrashLoopBackOff` | `kubectl logs <pod> -n skillfyme` – usually the database isn't ready yet; it recovers on restart |
