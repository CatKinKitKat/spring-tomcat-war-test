#!/usr/bin/env bash
set -euo pipefail

# Config
IMAGE_NAME="tomcat9:latest"
CONTAINER_NAME="tomcat"
PORT="8080"
WAR_FILE="test.war"
CONTEXT_PATH="test"

echo "[1/5] Building WAR with Maven..."
mvn -q --no-transfer-progress clean package

echo "[2/5] Stopping container if running..."
if docker ps -q --filter name="^${CONTAINER_NAME}$" | grep -q .; then
  docker stop "${CONTAINER_NAME}" || true
fi

echo "[3/5] Removing container if exists..."
if docker ps -aq --filter name="^${CONTAINER_NAME}$" | grep -q .; then
  docker rm "${CONTAINER_NAME}" || true
fi

echo "[4/5] Building Docker image ${IMAGE_NAME}..."
docker build --build-arg WAR_FILE="${WAR_FILE}" --build-arg CONTEXT_PATH="${CONTEXT_PATH}" -t "${IMAGE_NAME}" .

echo "[5/5] Running container ${CONTAINER_NAME}..."
docker run -d --name "${CONTAINER_NAME}" --restart unless-stopped -p ${PORT}:8080 "${IMAGE_NAME}"

echo "Done. Check: http://localhost:${PORT}/${CONTEXT_PATH}/"

