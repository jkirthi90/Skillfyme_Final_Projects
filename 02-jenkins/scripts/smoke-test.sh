#!/usr/bin/env bash
# Smoke test for the 3-tier Flask + MySQL app, run as a Jenkins build step
# after `docker compose up -d`. Waits for MySQL, queries it, then hits the app.
set -e

echo "Waiting for MySQL to be ready inside container 'mysql'..."
for i in {1..15}; do
  if docker exec mysql mysqladmin -h 127.0.0.1 -u admin -ppassword ping --silent; then
    echo "MySQL is up on attempt $i"
    break
  fi
  echo "MySQL not ready yet (attempt $i), sleeping 2s..."
  sleep 2
done

echo "Running test query..."
docker exec mysql mysql -h 127.0.0.1 -u admin -ppassword demo -e "SELECT * FROM greetings;"
echo "DB check succeeded."

echo "Checking the app through Nginx (port 80) and Adminer (port 8080)..."
curl -f http://localhost/
curl -f http://localhost:8080/ > /dev/null && echo "Adminer is up"

docker logs --tail 100 mysql
docker logs --tail 100 flask-app
docker logs --tail 100 web
docker logs --tail 100 adminer
