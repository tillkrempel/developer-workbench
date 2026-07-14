param (
    [string]$CodebasePath = (Get-Item .).FullName
)

# Stop on error
$ErrorActionPreference = "Stop"

# Check if Docker is installed and running
& docker info *>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker is not running or not installed. Please start Docker and try again."
    exit 1
}

# Resolve codebase path to absolute path
$AbsoluteCodebasePath = (Resolve-Path $CodebasePath).Path
if (!(Test-Path $AbsoluteCodebasePath -PathType Container)) {
    Write-Error "Directory '$AbsoluteCodebasePath' does not exist."
    exit 1
}

# Check if the image exists
$imageCheck = docker images -q intellij-mcp-server
if ([string]::IsNullOrEmpty($imageCheck)) {
    Write-Host "Warning: Docker image 'intellij-mcp-server' not found." -ForegroundColor Yellow
    Write-Host "Attempting to build it first..." -ForegroundColor Cyan
    if (Test-Path ".\build.ps1") {
        .\build.ps1
    } else {
        docker build -t intellij-mcp-server .
    }
}

# Stop and remove existing container if it exists
$ContainerName = "intellij-mcp"
$existingContainer = docker ps -aq -f "name=^/${ContainerName}$"
if (![string]::IsNullOrEmpty($existingContainer)) {
    Write-Host "==> Stopping and removing existing '${ContainerName}' container..." -ForegroundColor Cyan
    & docker stop $ContainerName *>$null
    & docker rm $ContainerName *>$null
}

Write-Host "==> Launching IntelliJ MCP Server..." -ForegroundColor Cyan
Write-Host "    Mounting:  $AbsoluteCodebasePath -> /project" -ForegroundColor Yellow
Write-Host "    Port:      64342" -ForegroundColor Yellow

# Run container
docker run -d `
  --name $ContainerName `
  -p 64342:64342 `
  -v "${AbsoluteCodebasePath}:/project" `
  intellij-mcp-server

Write-Host "==> IntelliJ MCP Server successfully started in background!" -ForegroundColor Green
Write-Host ""
Write-Host "Connection Details:" -ForegroundColor Cyan
Write-Host "  - Endpoint URL: http://localhost:64342" -ForegroundColor Yellow
Write-Host "  - Container Name: $ContainerName" -ForegroundColor Yellow
Write-Host ""
Write-Host "To view logs, run:"
Write-Host "  docker logs -f $ContainerName" -ForegroundColor Yellow
Write-Host "To stop the server, run:"
Write-Host "  docker stop $ContainerName" -ForegroundColor Yellow
