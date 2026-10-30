# 04 – Docker

- Docker CLI, Dockerfile, volumes, port binding
- Docker Compose
- Docker Swarm: 1 manager + 1 worker, nginx service scaled to 3

**Project:** [3tier-flask-mysql](./projects/3tier-flask-mysql) – Nginx → Flask → MySQL, plus Adminer
```bash
docker compose up -d --build
# app: http://<ip>:80   adminer: http://<ip>:8080
```
Deployed through Jenkins: [Jenkinsfile.compose-deploy](../02-jenkins/pipelines/Jenkinsfile.compose-deploy)

Commands: [commands.md](./commands.md)
