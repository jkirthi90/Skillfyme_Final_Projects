# 02 – Jenkins + Maven

Jenkins pipelines build and test a Maven Java app (`my-app`).

- Maven: install, generate project, `mvn clean / test / package`, run JAR → [maven.md](./maven.md)
- Jenkins in Docker, agent node, folder-based access → [commands.md](./commands.md)
- Freestyle job running Maven build
- Pipelines:
  - [Scripted](./pipelines/Jenkinsfile.scripted) – clone, build, test on agent
  - [Declarative](./pipelines/Jenkinsfile.declarative) – same flow
  - [Declarative with mvn test](./pipelines/Jenkinsfile.declarative-sudo)
  - [Compose deploy](./pipelines/Jenkinsfile.compose-deploy) – deploys the Docker 3-tier app + [smoke test](./scripts/smoke-test.sh)
