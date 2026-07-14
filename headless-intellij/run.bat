@echo off
setlocal enabledelayedexpansion

:: Check if Docker is installed and running
docker info >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Docker is not running or not installed. Please start Docker and try again.
    exit /b 1
)

:: Get target path (default to current directory if not specified)
set "CODEBASE_PATH=%~1"
if "%CODEBASE_PATH%"=="" (
    set "CODEBASE_PATH=%cd%"
)

:: Resolve to absolute path
for %%i in ("%CODEBASE_PATH%") do set "ABS_CODEBASE_PATH=%%~fi"

if not exist "%ABS_CODEBASE_PATH%\" (
    echo Error: Directory "%ABS_CODEBASE_PATH%" does not exist.
    exit /b 1
)

:: Check if the image exists
docker image inspect intellij-mcp-server >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Warning: Docker image 'intellij-mcp-server' not found.
    echo Attempting to build it first...
    if exist build.bat (
        call build.bat
    ) else (
        docker build -t intellij-mcp-server .
    )
)

:: Stop and remove existing container if it exists
set "CONTAINER_NAME=intellij-mcp"
docker ps -aq -f "name=^/%CONTAINER_NAME%$" >temp_cid.txt 2>nul
set /p CONTAINER_ID=<temp_cid.txt
del temp_cid.txt 2>nul

if not "%CONTAINER_ID%"=="" (
    echo ==> Stopping and removing existing '%CONTAINER_NAME%' container...
    docker stop %CONTAINER_NAME% >nul 2>&1
    docker rm %CONTAINER_NAME% >nul 2>&1
)

echo ==> Launching IntelliJ MCP Server...
echo     Mounting:  %ABS_CODEBASE_PATH% -^> /project
echo     Port:      64342

docker run -d ^
  --name %CONTAINER_NAME% ^
  -p 64342:64342 ^
  -v "%ABS_CODEBASE_PATH%:/project" ^
  intellij-mcp-server

if %ERRORLEVEL% equ 0 (
    echo ==> IntelliJ MCP Server successfully started in background!
    echo.
    echo Connection Details:
    echo   - Endpoint URL: http://localhost:64342
    echo   - Container Name: %CONTAINER_NAME%
    echo.
    echo To view logs, run:
    echo   docker logs -f %CONTAINER_NAME%
    echo To stop the server, run:
    echo   docker stop %CONTAINER_NAME%
) else (
    echo Failed to start the container.
    exit /b %ERRORLEVEL%
)
