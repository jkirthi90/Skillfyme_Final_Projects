# K8s Security Analyzer

- `GET /scan/namespace/{ns}`, `GET /scan/cluster`
- Checks: privileged, root user, hostNetwork/PID/hostPath, privilege escalation, latest tag, no limits, default ServiceAccount, cluster-admin, wildcard RBAC, no NetworkPolicy
- Tested with an insecure pod: [test-bad-workload.yaml](./k8s/test-bad-workload.yaml)

**Result** ([samples](./samples))

| Scan | Critical | High |
|------|---------:|-----:|
| Namespace – insecure pod | 3 | 18 |
| Namespace – after setting privileged/escalation to false | 2 | 17 |

Full steps: [SETUP.md](./SETUP.md)
