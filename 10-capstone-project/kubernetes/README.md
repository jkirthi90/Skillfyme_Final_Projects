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
| Images `ghcr.io/skillfyme/...` | Images don't exist | `ghcr.io/jkirthi90/...` from my CI, pulled with a registry secret |
| One `DATABASE_URL` for all services | Python needs `postgresql+asyncpg://`, Go needs `?sslmode=disable` | Separate URL per service |
| 2 replicas, 256Mi requests | Doesn't fit 2 × 4 GB nodes | 1 replica, 64Mi requests |
| Ingress with `skillfyme.com` + TLS | Domain not owned | NodePort 30300 (UI), 30400 (API) |
| No StorageClass | PVCs stay Pending on kubeadm | local-path provisioner |
| Dev overlay patch uses namespace `skillfyme-dev` | Patch matches nothing – build fails | No overlay; one namespace `skillfyme` |
| HPAs with `minReplicas: 2` | Override the dev overlay's 1 replica | No HPAs (no metrics-server on the lab cluster) |

## Original manifests – where they break

Tried the original `k8s/overlays/dev` first, fixing each error locally to reach the next one.

| # | Command | Result |
|---|---------|--------|
| 1 | `kubectl apply -k k8s/overlays/dev` | ❌ `secrets.yaml: no such file or directory` – nothing created; also 3 deprecation warnings (`bases`, `commonLabels`, `patchesStrategicMerge`) |
| 1b | Same, after removing the `secrets.yaml` line | ❌ `no matches for Id Deployment.v1.apps/ui-backend.skillfyme-dev` – patch namespace doesn't match the base |
| 2 | Same, after fixing the patch namespace | ❌ 16 pods in `ImagePullBackOff` – `ghcr.io/skillfyme/*` images don't exist; HPAs scaled 3 deployments back to 2 replicas |
| 3 | After switching to my CI images | ❌ Postgres/Mongo services `CrashLoopBackOff` – `kubectl get svc` shows no `postgres`, `mongodb` or `redis` |
| 4 | learning-path logs | ❌ `The loaded 'psycopg2' is not async` – shared `DATABASE_URL` has the wrong format for the Python service |

**Commands used to test the original manifests**
```bash
git clone https://github.com/jkirthi90/Project-1-LearnSphere_Skillfyme.git && cd Project-1-LearnSphere_Skillfyme

# Break 1
kubectl apply -k k8s/overlays/dev

# Break 1b – local workaround only
sed -i '/secrets.yaml/d' k8s/base/kustomization.yaml
kubectl create namespace skillfyme-dev
kubectl -n skillfyme-dev create secret generic skillfyme-secrets \
  --from-literal=MONGODB_URI='mongodb://skillfyme:skillfyme_secret@mongodb:27017/skillfyme?authSource=admin' \
  --from-literal=DATABASE_URL='postgresql://skillfyme:skillfyme_secret@postgres:5432/skillfyme' \
  --from-literal=JWT_SECRET=test --from-literal=STRIPE_SECRET_KEY=x
kubectl apply -k k8s/overlays/dev
kubectl kustomize k8s/overlays/dev 2>&1 | grep -v Warning

# Break 2
sed -i 's/namespace: skillfyme-dev/namespace: skillfyme/' k8s/overlays/dev/replicas-patch.yaml
kubectl apply -k k8s/overlays/dev
kubectl get pods -n skillfyme-dev
kubectl describe pod -n skillfyme-dev -l app=course-catalog | tail -8

# Break 3 / 4 – switch to my CI images
kubectl -n skillfyme-dev create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io --docker-username=jkirthi90 --docker-password=<token>
kubectl -n skillfyme-dev patch serviceaccount default -p '{"imagePullSecrets":[{"name":"ghcr-secret"}]}'
for d in $(kubectl -n skillfyme-dev get deploy -o name); do
  n=${d#deployment.apps/}
  kubectl -n skillfyme-dev set image $d $n=ghcr.io/jkirthi90/$n:latest
done
kubectl get pods -n skillfyme-dev
kubectl logs -n skillfyme-dev deploy/learning-path --tail 8
kubectl logs -n skillfyme-dev deploy/course-catalog --tail 8
kubectl get svc -n skillfyme-dev

# clean up
kubectl delete namespace skillfyme-dev
git checkout k8s/
```

## Issues hit while deploying k8s-lite

| Issue | Cause | Fix |
|-------|-------|-----|
| Pods evicted (`ContainerStatusUnknown`), `postgres-0`/`mongodb-0` Pending | Worker launched with the default 8 GB disk; images filled it to 85% → `DiskPressure` taint. Database volumes are bound to the worker, so they couldn't schedule | Resized the EBS volume to 30 GB online: `growpart` + `resize2fs` → 17% used |
| `mongodb-0` stuck at 0/1, course-catalog and live-session crash-looping | Readiness probe runs `mongosh`, which takes ~2.2 s on a t3.medium; default probe timeout is 1 s | `timeoutSeconds: 10` on the database probes. Deleted `mongodb-0` so the StatefulSet recreated it (it won't replace a not-ready pod during a rollout) |
| All pods on `k8s-worker01` | Image locality and free resources; databases bound there by local-path volumes. Master is untainted | No change needed – worker has ~2.3 GB free |

**Commands used to fix them**
```bash
# Diagnose
kubectl describe pod postgres-0 -n skillfyme | tail -8
kubectl get pvc,storageclass -n skillfyme
kubectl describe nodes | grep -iE "^Name:|Pressure|Taints"
df -h / && lsblk                                    # on the worker

# Disk: EC2 → Volumes → Modify volume → 30 GiB, then on the worker
sudo growpart /dev/nvme0n1 1
sudo resize2fs /dev/nvme0n1p1
df -h /

# Clear evicted pods and restart
kubectl delete pods -n skillfyme --field-selector=status.phase=Failed
kubectl delete pods -n local-path-storage --field-selector=status.phase=Failed
kubectl rollout restart deployment -n skillfyme

# MongoDB probe timeout
kubectl describe pod mongodb-0 -n skillfyme | tail -6
time kubectl exec mongodb-0 -n skillfyme -- mongosh --quiet --eval "db.adminCommand('ping')"
kubectl -n skillfyme patch statefulset mongodb --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/readinessProbe/timeoutSeconds","value":10}]'
kubectl delete pod mongodb-0 -n skillfyme
kubectl rollout restart deployment course-catalog live-session -n skillfyme

# Scheduling check
kubectl describe node k8s-master | grep -i taints
```

## Build the cluster (kubeadm)
3 × t3.medium, 30 GB gp3, Standard CPU credits. Full steps: [05-kubernetes/cluster-setup/kubeadm.md](../../05-kubernetes/cluster-setup/kubeadm.md).
```bash
# all nodes: hostname, /etc/hosts, swap off, kernel modules, sysctl, containerd, kubeadm/kubelet/kubectl
sudo hostnamectl set-hostname k8s-master          # k8s-worker01 / k8s-worker02 on the workers
sudo swapoff -a && sudo sed -i '/ swap / s/^/#/' /etc/fstab

# master
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 | tee ~/kubeadm-init.log
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/calico.yaml
sudo kubeadm token create --print-join-command

# each worker
sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

# master
kubectl get nodes
```
If `admin.conf` is missing, `kubeadm init` didn't finish: `sudo kubeadm reset -f`, then run init again.

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

**4. Images stay private** – the cluster pulls them with a registry secret (step 4 below), using a GitHub token with only `read:packages`.

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

**3. Clone the project** (private – password is a classic token with `repo` + `read:packages`)
```bash
git clone https://github.com/jkirthi90/Project-1-LearnSphere_Skillfyme.git
cd Project-1-LearnSphere_Skillfyme
```
The manifests in [manifests/](./manifests) are in the project repo as `k8s-lite/`.

**4. Namespace, registry secret, app secret, seed scripts**
```bash
kubectl create namespace skillfyme

# pull private images from GHCR
kubectl -n skillfyme create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io --docker-username=jkirthi90 --docker-password=<token>
kubectl -n skillfyme patch serviceaccount default \
  -p '{"imagePullSecrets":[{"name":"ghcr-secret"}]}'

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

kubectl -n skillfyme create configmap postgres-init --from-file=init.sql=scripts/postgres-init.sql
kubectl -n skillfyme create configmap mongo-init --from-file=mongo-init.js=scripts/mongo-init.js
```

**5. Deploy**
```bash
kubectl apply -k k8s-lite
kubectl get pods -n skillfyme -w          # wait until all are Running / 1/1
```

**6. Verify**
```bash
kubectl get pods,svc,pvc -n skillfyme -o wide
curl -s localhost:30400/health; echo
curl -s localhost:30400/api/courses | head -c 200; echo
curl -s localhost:30400/api/learning-paths | grep -o '"slug"' | wc -l
kubectl -n skillfyme exec postgres-0 -- psql -U skillfyme -d skillfyme \
  -tAc 'SELECT count(*) FROM learning_paths;' -tAc 'SELECT count(*) FROM assessments;'
TOKEN=$(curl -s -X POST localhost:30400/api/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"test@demo.com","password":"password123"}' | grep -o '"token":"[^"]*' | cut -d'"' -f4)
echo ${TOKEN:0:25}...
curl -s localhost:30400/api/cart -H "Authorization: Bearer $TOKEN"; echo
curl -s -o /dev/null -w "%{http_code}\n" localhost:30400/api/cart
```
Ports 30300/30400 were later replaced by the [Gateway API](../gateway-api).
UI: `http://<node-public-ip>:30300` (open 30300 and 30400 in the security group, from your IP only)

## Troubleshooting
| Status | Check |
|--------|-------|
| `ImagePullBackOff` | `ghcr-secret` exists and is on the default ServiceAccount; token has `read:packages`; image name matches `kubectl describe pod` |
| `Pending` | `kubectl describe pod` – memory, or PVC not bound (`kubectl get pvc`) |
| `CrashLoopBackOff` | `kubectl logs <pod> -n skillfyme` – usually the database isn't ready yet; it recovers on restart |
| Node `DiskPressure` | `df -h /` on the node – grow the EBS volume |

## Screenshots

**1. Cluster ready**
![Nodes](./screenshots/01-nodes-ready.png)
kubeadm cluster with `k8s-master` (control plane) and `k8s-worker01`, both `Ready`, Kubernetes v1.33.13.

**2. CI pipeline**
![CI runs](./screenshots/02-ci-runs.png)
GitHub Actions *CI — Build, Test & Lint*: every push to `main` lints, tests and builds the 10 images to GHCR; pull requests run the same checks.

**3. Original manifests – build errors**
![Build errors](./screenshots/03-original-build-errors.png)
First apply fails on the missing `secrets.yaml`; after removing it, the dev overlay's patch fails to find its targets. No resources created.

**4. Original manifests – images don't exist**
![Image pull](./screenshots/04-original-image-pull.png)
All 16 pods in `ErrImagePull` / `ImagePullBackOff` – `ghcr.io/skillfyme/*` doesn't exist. Note 2 pods for deployments the dev overlay sets to 1 replica (HPA override).

**5. Original manifests – no databases**
![No databases](./screenshots/05-original-no-databases.png)
With working images, database-backed services crash. learning-path fails on the wrong `DATABASE_URL` format (`psycopg2 is not async`), and `kubectl get svc` lists no `postgres`, `mongodb` or `redis`.

**6. k8s-lite – deployed and verified**
![Verification](./screenshots/06-lite-verification.png)
13 pods `1/1 Running`, NodePorts 30300/30400, both database volumes `Bound`. Health `ok` for Redis, catalog and enrollment; 4 learning paths and 4 assessments in Postgres; login returns a JWT, cart works with it and returns `401` without it.

**7. UI on Kubernetes – course catalog**
![Courses](./screenshots/07-ui-courses.png)
Served through NodePort 30300; 4 courses loaded from MongoDB via course-catalog.

**8. UI on Kubernetes – live sessions**
![Live sessions](./screenshots/08-ui-live-sessions.png)
Live sessions from MongoDB via the live-session service, with format filters.
