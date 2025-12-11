param(
  [string]$ImageName = "tomcat9:latest",
  [string]$ContainerName = "tomcat",
  [int]$Port = 8080,
  [string]$WarFile = "test.war",
  [string]$ContextPath = "test"
)

$ErrorActionPreference = "Stop"

Write-Host "[1/5] Building WAR with Maven..."
mvn -q --no-transfer-progress clean package

Write-Host "[2/5] Stopping container if running..."
$runningId = docker ps -q --filter "name=^$ContainerName$"
if ($runningId) { docker stop $ContainerName | Out-Null }

Write-Host "[3/5] Removing container if exists..."
$anyId = docker ps -aq --filter "name=^$ContainerName$"
if ($anyId) { docker rm $ContainerName | Out-Null }

Write-Host "[4/5] Building Docker image $ImageName..."
docker build -t $ImageName --build-arg WAR_FILE=$WarFile --build-arg CONTEXT_PATH=$ContextPath .

Write-Host "[5/5] Running container $ContainerName..."
docker run -d --name $ContainerName --restart unless-stopped -p $Port:8080 $ImageName | Out-Null

Write-Host "Done. Check: http://localhost:$Port/$ContextPath/"

