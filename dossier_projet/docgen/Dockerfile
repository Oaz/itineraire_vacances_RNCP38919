# Use the latest LTS Node.js as base image
FROM node:20-bullseye

# Label for metadata
LABEL authors="oaz"
LABEL description="Docker image for Typst document compilation with Mermaid diagram support"

# Install necessary dependencies for Puppeteer and Typst
RUN apt-get update && apt-get install -y \
    curl \
    xz-utils \
    fontconfig \
    ca-certificates \
    gosu \
    # Puppeteer dependencies
    libglib2.0-0 \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Install Typst
RUN curl -L https://github.com/typst/typst/releases/download/v0.13.1/typst-x86_64-unknown-linux-musl.tar.xz -o typst.tar.xz \
    && mkdir -p /opt/typst \
    && tar -xf typst.tar.xz -C /opt/typst --strip-components=1 \
    && ln -s /opt/typst/typst /usr/local/bin/typst \
    && rm typst.tar.xz

# Install Chrome for Puppeteer
RUN curl -LO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update \
    && apt-get install -y ./google-chrome-stable_current_amd64.deb \
    && rm google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/* \
    && chmod a+rx /usr/bin/google-chrome \
    && google-chrome --version

# Install puppeteer and mermaid-cli
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
RUN npm install -g puppeteer@24.9.0 @mermaid-js/mermaid-cli@11.9.0

# Create a puppeteer configuration file
RUN mkdir -p /etc/puppeteer && \
    echo '{"executablePath": "/usr/bin/google-chrome", "args": ["--no-sandbox", "--disable-setuid-sandbox"]}' > /etc/puppeteer/config.json

# Create a directory for fonts
RUN mkdir -p /fonts

# Create working directory
WORKDIR /workdir

# Copy the entry script that will handle user switching
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy the script to process .mmd files before running typst compile
COPY process_and_compile.sh /usr/local/bin/process_and_compile.sh
RUN chmod +x /usr/local/bin/process_and_compile.sh

# Set the entrypoint to our user-switching script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]