@echo off
setlocal enabledelayedexpansion

echo ==> Verifying environment...

:: Check if Docker is installed and running
docker info >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Docker is not running or not installed. Please start Docker and try again.
    exit /b 1
)

:: Check if files exist
if not exist Dockerfile (
    echo Error: Dockerfile not found in current directory.
    exit /b 1
)
if not exist mcpServer.xml (
    echo Error: mcpServer.xml not found in current directory.
    exit /b 1
)

echo ==> Building Docker image 'intellij-mcp-server'...
docker build -t intellij-mcp-server .

if %ERRORLEVEL% equ 0 (
    echo ==> Build successful!
    echo You can now run the server using 'run.bat'
) else (
    echo Build failed.
    exit /b %ERRORLEVEL%
)
