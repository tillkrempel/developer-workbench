# Headless IntelliJ MCP Server with Host Repository Mount

This setup allows you to run a full, headless instance of IntelliJ IDEA inside a isolated Docker container to act as a **Model Context Protocol (MCP)** server. Instead of copying project files into the container, the host repository is safely mounted directly into the container workspace, allowing real-time synchronization between your host editing tools, AI agents, and IntelliJ's advanced language indexing engine.

---

## 🛠️ Prerequisites

1. **Docker** installed and running on your host machine.
2. An AI agent client that supports MCP connections (e.g., **Claude Desktop**, **Cursor**, **Claude Code**, or **JetBrains Junie**).

---

## 🏗️ Architecture Setup

To run this environment, you need two files in the same directory: `Dockerfile` and `mcpServer.xml`.

### 1. `mcpServer.xml`
This file seeds the JetBrains configuration environment, ensuring the MCP server starts on initialization and binds to the designated port.

```xml
<application>
  <component name="McpServerOptions">
    <option name="enableMcpServer" value="true" />
    <option name="mcpServerPort" value="64342" />
  </component>
</application>
```

### 2. `Dockerfile`
The Docker build instructions package IntelliJ along with a virtual framebuffer (`xvfb`) to simulate a display headless server, and installs required core interaction tools (`git`, `nano`, `curl`, `openssh-client`, `diffutils`, `zsh`).

```dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install headless system prerequisites, GUI dependencies, and development tools
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    xvfb \
    libxrender1 \
    libxtst6 \
    libxi6 \
    tar \
    git \
    nano \
    curl \
    openssh-client \
    diffutils \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Set Zsh as the default shell for interactive terminal sessions
ENV SHELL=/bin/zsh

# 2. Download and extract IntelliJ IDEA Community Edition
WORKDIR /opt/intellij
RUN curl -L "https://download.jetbrains.com/idea/ideaIC-2026.1.tar.gz" | tar -xz --strip-components=1

# 3. Seed the MCP Server configuration into IntelliJ's Linux profile path
RUN mkdir -p /root/.config/JetBrains/IdeaIC2026.1/options/
COPY mcpServer.xml /root/.config/JetBrains/IdeaIC2026.1/options/mcpServer.xml

# 4. Expose the native JetBrains MCP Port
EXPOSE 64342

# 5. Launch IntelliJ using xvfb
RUN echo '#!/bin/bash\n\
xvfb-run --server-args="-screen 0 1024x768x24" /opt/intellij/bin/idea.sh "$@"' > /usr/local/bin/idea-headless && \
    chmod +x /usr/local/bin/idea-headless

WORKDIR /project
ENTRYPOINT ["idea-headless"]
```

---

## 🚀 Step-by-Step Usage Guide

Helper scripts are provided to simplify building the image and running the container.

### Option A: Using Helper Scripts

#### Windows (PowerShell)
1. **Build the image**:
   ```powershell
   .\build.ps1
   ```
2. **Run the server** (defaults to mounting the current directory):
   ```powershell
   .\run.ps1
   ```
   *To mount a specific codebase directory:*
   ```powershell
   .\run.ps1 -CodebasePath "C:\path\to\your\project"
   ```

#### Windows (Command Prompt)
1. **Build the image**:
   ```cmd
   build.bat
   ```
2. **Run the server** (defaults to mounting the current directory):
   ```cmd
   run.bat
   ```
   *To mount a specific codebase directory:*
   ```cmd
   run.bat "C:\path\to\your\project"
   ```

#### Linux & macOS
1. **Make the scripts executable**:
   ```bash
   chmod +x build.sh run.sh
   ```
2. **Build the image**:
   ```bash
   ./build.sh
   ```
3. **Run the server** (defaults to mounting the current directory):
   ```bash
   ./run.sh
   ```
   *To mount a specific codebase directory:*
   ```bash
   ./run.sh /path/to/your/project
   ```

---

### Option B: Manual Execution

#### Step 1: Build the Image manually
```bash
docker build -t intellij-mcp-server .
```

#### Step 2: Spin up the Container manually
Map your host project folder directory to the container's `/project` workspace via a bind volume mount:
```bash
docker run -d \
  --name intellij-mcp \
  -p 64342:64342 \
  -v /path/to/your/local/codebase:/project \
  intellij-mcp-server
```

---

### Step 3: Connect your AI Client
Point your MCP-compatible client to the exposed endpoint:
* **Protocol:** HTTP / SSE (Server-Sent Events) or WebSocket depending on client configuration.
* **Host Port:** `http://localhost:64342`

---

## 🔒 Security & Safety Analysis of Bind Mounting

Mounting your host codebase directly into the container using `-v` (bind mounting) is highly efficient, but it introduces distinct security and practical behaviors you should keep in mind:

### Advantages
* **Zero Duplication:** No massive code directories are copied into the container filesystem, saving disk space and eliminating sync lag.
* **Instant Host Updates:** Whenever you or your AI agent modify code via your local IDE, the changes instantly reflect inside the containerized IntelliJ instance for index reassessment.
* **Ephemerality:** The build tools, JVM runtimes, and headless engines stay entirely encapsulated inside the container, keeping your host system clean.

### Safety Considerations
1. **File System Permissions (UID/GID):** By default, the processes inside the container run as `root`. If IntelliJ writes new index files, caches, or automated refactoring modifications into the mounted repository, those files will be owned by `root` on your host filesystem. This can cause permission issues when trying to modify or delete them locally outside Docker.
   * *Mitigation:* Pass your local user ID to the execution flag via `--user $(id -u):$(id -g)` if write permissions mismatch, ensuring your host user retains native file privileges.
2. **Container Escape & Access Scope:** The container can read and write *only* to the specific folder directory specified in the `-v` execution string. It cannot wander into other parts of your host hard drive unless you accidentally mount your entire root user home directory. Keep mounts specific to individual project subfolders.
3. **Malicious Code Modification:** Because the containerized IntelliJ instance has direct write privileges to your codebase, if your AI agent receives a compromised prompt, it could theoretically rewrite or insert malicious code strings directly into your local working files.
   * *Mitigation:* Always leverage a structured Git status control loop. Check `git status` and `git diff` on your host machine before committing any changes authorized or constructed via the MCP automation pipeline.