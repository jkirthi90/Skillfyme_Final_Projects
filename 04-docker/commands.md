# Docker Commands

## Install Docker (Ubuntu 22.04 / 24.04)

Current method from the Docker docs (https://docs.docker.com/engine/install/ubuntu/):

```bash
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl status docker

sudo usermod -aG docker $USER           # run docker without sudo; log out and back in
```

The plugin gives `docker compose` (Compose v2). The old standalone `docker-compose` (v1) is no longer maintained.

## Containers and images

```bash
docker ps                               # running containers
docker ps -a                            # all containers
docker images                           # local images
docker pull <image>
docker search <term>

docker run -dit ubuntu                  # detached, interactive, with a terminal
docker run -it ubuntu /bin/bash         # foreground shell (exits when you exit)
docker exec -it <container> /bin/bash   # shell inside a running container

docker stop <container>
docker start <container>
docker kill <container>
docker rm <container>
docker logs -f <container>

docker commit <container> <new-image>   # save a container's changes as an image
docker export <container> > <name>.tar  # export a container's filesystem
```

## Port binding

```bash
docker run --name nginx -d -p 8081:80 nginx                 # host 8081 → container 80
docker run --name jenkins -d -p 8082:8080 jenkins/jenkins:lts
```

## Push to Docker Hub

```bash
docker login
docker tag <image-id> <dockerhub-user>/<image>:<tag>
docker push <dockerhub-user>/<image>:<tag>
```

## Dockerfile

Main instructions: `FROM`, `WORKDIR`, `RUN`, `COPY`, `ENV`, `EXPOSE`, `CMD`.

```dockerfile
FROM ubuntu
CMD ["echo", "hello world"]
```

```bash
docker build -t hello:1.0 .
docker run --name test hello:1.0
```

Reference: https://docs.docker.com/reference/dockerfile/

## Volumes

```bash
docker volume create volume1
docker run -d --name devtest --mount source=volume1,target=/app nginx:alpine
docker volume ls
docker volume inspect volume1
```

## Docker Compose

Example from the Docker docs: a Flask app that counts page hits in Redis.

`app.py`
```python
import time
import redis
from flask import Flask

app = Flask(__name__)
cache = redis.Redis(host='redis', port=6379)

def get_hit_count():
    retries = 5
    while True:
        try:
            return cache.incr('hits')
        except redis.exceptions.ConnectionError as exc:
            if retries == 0:
                raise exc
            retries -= 1
            time.sleep(0.5)

@app.route('/')
def hello():
    count = get_hit_count()
    return 'Hello World! I have been seen {} times.\n'.format(count)
```

`requirements.txt`
```
flask
redis
```

`Dockerfile`
```dockerfile
FROM python:3.12-alpine
WORKDIR /code
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
RUN apk add --no-cache gcc musl-dev linux-headers
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
EXPOSE 5000
COPY . .
CMD ["flask", "run"]
```

`compose.yaml`
```yaml
services:
  web:
    build: .
    ports:
      - "8000:5000"
  redis:
    image: "redis:alpine"
```

The top-level `version:` key is obsolete in Compose v2 and is ignored, so it is left out here.

```bash
docker compose up -d                    # build and start in the background
docker compose ps
docker compose logs -f
docker compose down                     # stop and remove; add -v to remove volumes
# open http://<vm-public-ip>:8000
```

## Docker Swarm

```bash
# Manager
docker swarm init --advertise-addr <manager-ip>
# prints a "docker swarm join --token ..." command for workers

# Open the cluster port on manager and workers
sudo ufw allow 2377/tcp

# Worker
docker swarm join --token <token> <manager-ip>:2377

# Manager
docker node ls
docker service create --name web-server --publish 8084:80 nginx:latest
docker service ls
docker service scale web-server=3
docker service ps web-server
# open http://<manager-ip>:8084
```

Swarm also needs 7946/tcp+udp (node discovery) and 4789/udp (overlay network) open between nodes.
