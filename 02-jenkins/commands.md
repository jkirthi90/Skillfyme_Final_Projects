# Jenkins Commands

## Run Jenkins in Docker (controller)

Needs at least 2 CPU cores and 2 GB RAM. Docker install steps are in [04-docker/commands.md](../04-docker/commands.md).

```bash
docker run -d \
  -v jenkins_home:/var/jenkins_home \
  -p 8080:8080 -p 50000:50000 \
  --restart=on-failure \
  jenkins/jenkins:lts                    # LTS is the recommended stable line

docker logs -f <container-id>            # shows the initial admin password
```

Open `http://<public-ip>:8080`, paste the password, install the suggested plugins.

For the 3-tier compose project the controller was published on host port 8085 so it did not clash with Adminer on 8080:

```bash
docker run -d -v jenkins_home:/var/jenkins_home -p 8085:8080 -p 50000:50000 \
  --restart=on-failure jenkins/jenkins:lts
```

## Prepare an agent ("worker") for Docker jobs

```bash
sudo apt install -y openjdk-21-jdk-headless    # agents need Java
sudo apt install -y docker-compose-v2          # provides "docker compose"
sudo usermod -aG docker $USER                  # let the agent user run docker; log out and in
```

> The lab notes used `sudo chmod 666 /var/run/docker.sock`. It works but gives every user on the machine root-level access to Docker; adding the Jenkins user to the `docker` group is the safer fix.

## Freestyle job: build the Maven app

Source code: Git repo, branch `maven`. Build step → *Execute shell*:

```bash
cd my-app
echo "project build is in progress"
mvn clean && mvn package
echo "project test is in progress"
java -cp target/my-app-1.0-SNAPSHOT.jar com.mycompany.app.App
echo "project build complete"
```

## Freestyle job: deploy the 3-tier compose app

Execute shell on the `worker` agent:

```bash
cd 04-docker/projects/3tier-flask-mysql
docker compose down
docker compose up -d
docker ps
bash ../../../02-jenkins/scripts/smoke-test.sh
```

Then open `http://<worker-public-ip>:80` (app via Nginx) and `http://<worker-public-ip>:8080` (Adminer).

## Access control

Install the **Folder-based Authorization Strategy** plugin, then grant users permissions per folder (Manage Jenkins → Security).

Reference: https://www.jenkins.io/doc/book/pipeline/
