# Simple 3-Tier Todo Application

Browser -> Nginx frontend -> FastAPI backend -> PostgreSQL database.

Run with Docker:
```bash
docker compose up --build
```
Open http://localhost:8080

API docs: http://localhost:8000/docs

Test:
```bash
curl http://localhost:8000/health
curl http://localhost:8000/todos
curl -X POST http://localhost:8000/todos -H 'Content-Type: application/json' -d '{"title":"Learn Kubernetes"}'
```

For Kubernetes:
```bash
docker build -t three-tier-backend:1.0 ./backend
docker build -t three-tier-frontend:1.0 ./frontend
kubectl apply -f k8s/
kubectl get pods -n three-tier
kubectl port-forward svc/frontend 8080:80 -n three-tier
```

Backend experiments: edit `backend/main.py`.
Database experiments: edit `database/init.sql`.

To recreate the Compose database:
```bash
docker compose down -v
docker compose up --build
```

The Kubernetes PostgreSQL manifest uses `emptyDir` only for a disposable lab. Use persistent storage for real data.
