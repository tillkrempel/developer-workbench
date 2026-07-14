#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed. Please install Docker and try again.${NC}" >&2
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker daemon is not running. Please start Docker and try again.${NC}" >&2
    exit 1
fi

# Determine directory to mount
CODEBASE_PATH="${1:-$(pwd)}"

# Convert to absolute path
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS readlink doesn't always support -f, use cd-pwd instead
    if [ -d "$CODEBASE_PATH" ]; then
        CODEBASE_PATH=$(cd "$CODEBASE_PATH" && pwd)
    else
        echo -e "${RED}Error: Directory '$CODEBASE_PATH' does not exist.${NC}" >&2
        exit 1
    fi
else
    # Linux
    if [ -d "$CODEBASE_PATH" ]; then
        CODEBASE_PATH=$(readlink -f "$CODEBASE_PATH")
    else
        echo -e "${RED}Error: Directory '$CODEBASE_PATH' does not exist.${NC}" >&2
        exit 1
    fi
fi

# Check if the image exists
if ! docker image inspect intellij-mcp-server &> /dev/null; then
    echo -e "${YELLOW}Warning: Docker image 'intellij-mcp-server' not found.${NC}"
    echo -e "${BLUE}Attempting to build it first...${NC}"
    if [ -f "./build.sh" ]; then
        ./build.sh
    else
        docker build -t intellij-mcp-server .
    fi
fi

# Stop and remove existing container if it exists
CONTAINER_NAME="intellij-mcp"
if [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    echo -e "${BLUE}==> Stopping and removing existing '${CONTAINER_NAME}' container...${NC}"
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

echo -e "${BLUE}==> Launching IntelliJ MCP Server...${NC}"
echo -e "    Mounting:  ${YELLOW}${CODEBASE_PATH}${NC} -> /project"
echo -e "    Port:      ${YELLOW}64342${NC}"

# Run container
docker run -d \
  --name "$CONTAINER_NAME" \
  -p 64342:64342 \
  -v "$CODEBASE_PATH:/project" \
  intellij-mcp-server

echo -e "${GREEN}==> IntelliJ MCP Server successfully started in background!${NC}"
echo -e ""
echo -e "${BLUE}Connection Details:${NC}"
echo -e "  - Endpoint URL: ${YELLOW}http://localhost:64342${NC}"
echo -e "  - Container Name: ${YELLOW}${CONTAINER_NAME}${NC}"
echo -e ""
echo -e "To view logs, run:"
echo -e "  ${YELLOW}docker logs -f ${CONTAINER_NAME}${NC}"
echo -e "To stop the server, run:"
echo -e "  ${YELLOW}docker stop ${CONTAINER_NAME}${NC}"
