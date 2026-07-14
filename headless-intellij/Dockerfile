FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install system prerequisites & headless virtual display 
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    xvfb \
    libxrender1 \
    libxtst6 \
    libxi6 \
    curl \
    tar \
    && rm -rf /var/lib/apt/lists/*

# 2. Download and extract IntelliJ IDEA Community Edition (Adjust version numbers as needed)
WORKDIR /opt/intellij
RUN curl -L "https://download.jetbrains.com/idea/ideaIC-2026.1.tar.gz" | tar -xz --strip-components=1

# 3. Seed the MCP Server configuration into IntelliJ's Linux profile path
# (Replacing 'IdeaIC2026.1' if you are pinning a different version string)
RUN mkdir -p /root/.config/JetBrains/IdeaIC2026.1/options/
COPY mcpServer.xml /root/.config/JetBrains/IdeaIC2026.1/options/mcpServer.xml

# 4. Expose the native JetBrains MCP Port
EXPOSE 64342

# 5. Launch IntelliJ using xvfb. 
# We add the bind property to ensure Java listens globally (0.0.0.0) instead of restricting to localhost inside the isolated container.
RUN echo '#!/bin/bash\n\
xvfb-run --server-args="-screen 0 1024x768x24" /opt/intellij/bin/idea.sh "$@"' > /usr/local/bin/idea-headless && \
    chmod +x /usr/local/bin/idea-headless

WORKDIR /project
ENTRYPOINT ["idea-headless"]