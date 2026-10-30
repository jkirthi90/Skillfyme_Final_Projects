# 09 – AI DevOps Projects

FastAPI services running in Kubernetes. Python + Kubernetes API decide the result; the LLM only explains it.

| Project | What it does |
|---------|--------------|
| [log-analyzer](./log-analyzer) | Finds why a pod is failing (CrashLoopBackOff, OOMKilled, etc.) |
| [security-analyzer](./security-analyzer) | Scans pods and RBAC for security issues by severity |

Each has an Ollama (Qwen 2.5 1.5B) version and an OpenAI version.

Known issue: AI explanation step not working yet (Ollama timed out; OpenAI client not created in code). Scans work.
