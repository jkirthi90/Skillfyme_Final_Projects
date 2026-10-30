# K8s Log Analyzer

- `GET /analyze-pod/{namespace}/{pod}` – checks status, restarts, events, logs
- Rules: CrashLoopBackOff / ImagePullBackOff / OOMKilled → Critical; Pending → Warning; Running + no restarts → Healthy
- Tested with a busybox pod that exits with error
- [ollama/](./ollama) and [openai/](./openai) versions, [k8s/rbac.yaml](./k8s/rbac.yaml) (read-only)

Full steps: [SETUP.md](./SETUP.md)
