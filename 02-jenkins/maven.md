# Maven (used in Jenkins pipelines)

## Install Java and Maven (Ubuntu)

```bash
sudo apt update
sudo apt install -y openjdk-17-jdk      # JDK is needed to compile; the JRE alone only runs Java
java -version

sudo apt install -y maven
mvn --version
```

If a build fails because Java is too old, install a newer JDK and point `JAVA_HOME` at the JDK folder (not at the `java` binary):

```bash
sudo apt install -y openjdk-21-jdk
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH="$JAVA_HOME/bin:$PATH"
java -version
```

Manual alternative used earlier in the course: download a JDK tarball, extract it to `/opt`, and set `JAVA_HOME` the same way.

## Create a sample project

From the Maven "in five minutes" guide (https://maven.apache.org/guides/getting-started/maven-in-five-minutes.html):

```bash
mvn archetype:generate \
  -DgroupId=com.mycompany.app \
  -DartifactId=my-app \
  -DarchetypeArtifactId=maven-archetype-quickstart \
  -DarchetypeVersion=1.4 \
  -DinteractiveMode=false

cd my-app
tree                                    # shows pom.xml and src/main, src/test
```

## Build, test and run

```bash
mvn clean
mvn test
mvn package                             # creates target/my-app-1.0-SNAPSHOT.jar

java -cp target/my-app-1.0-SNAPSHOT.jar com.mycompany.app.App
# Hello World!
```

## Downloads used in the assignment

- Apache Maven binaries: https://maven.apache.org/download.cgi
- Apache Tomcat (to deploy a WAR): https://tomcat.apache.org/
