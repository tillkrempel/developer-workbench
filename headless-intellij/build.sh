#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==> Verifying environment...${NC}"

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

# Check if required files exist in the current directory
if [ ! -f "Dockerfile" ] || [ ! -f "mcpServer.xml" ]; then
    echo -e "${RED}Error: Dockerfile or mcpServer.xml not found in the current directory.${NC}" >&2
    echo -e "Please run this script from the directory containing these files."
    exit 1
fi

echo -e "${BLUE}==> Building Docker image 'intellij-mcp-server'...${NC}"
docker build -t intellij-mcp-server .

echo -e "${GREEN}==> Build successful!${NC}"
echo -e "You can now run the server using './run.sh'"
