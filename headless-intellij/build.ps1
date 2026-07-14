# Stop on error
$ErrorActionPreference = "Stop"

Write-Host "==> Verifying environment..." -ForegroundColor Cyan

# Check if Docker is installed and running
& docker info *>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker is not running or not installed. Please start Docker and try again."
    exit 1
}

# Check if required files exist
if (!(Test-Path "Dockerfile") -or !(Test-Path "mcpServer.xml")) {
    Write-Error "Dockerfile or mcpServer.xml not found in the current directory."
    Write-Host "Please run this script from the directory containing these files."
    exit 1
}

Write-Host "==> Building Docker image 'intellij-mcp-server'..." -ForegroundColor Cyan
docker build -t intellij-mcp-server .

if ($LASTEXITCODE -eq 0) {
    Write-Host "==> Build successful!" -ForegroundColor Green
    Write-Host "You can now run the server using '.\run.ps1'"
} else {
    Write-Error "Build failed."
    exit $LASTEXITCODE
}
