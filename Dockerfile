# ~/camoufox-docker/Dockerfile

# Use Ubuntu 24.04 as the base image
FROM ubuntu:24.04

# Set arguments for the version to make updates easier
ARG CAMOUFOX_VERSION=135.0.1-beta.24
ARG CAMOUFOX_URL=https://github.com/daijro/camoufox/releases/download/v${CAMOUFOX_VERSION}/camoufox-${CAMOUFOX_VERSION}-lin.x86_64.zip

# Set DEBIAN_FRONTEND to noninteractive to avoid prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for a GTK app and the requested tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    unzip \
    libgtk-3-0 \
    build-essential make rustc \
    git golang-go curl rsync \
    libnss3 \
    libdbus-glib-1-2 \
    libx11-xcb1 \
    # --- User requested packages ---
    msitools \
    p7zip-full \
    aria2 \
    libasound2t64 \
    && rm -rf /var/lib/apt/lists/* && update-ca-certificates

# Download, unzip, and make the application executable
WORKDIR /app

RUN wget -O camoufox.zip "${CAMOUFOX_URL}" && \
    7z x camoufox.zip && \
    rm camoufox.zip && \
    chmod +x /app/camoufox-bin


# --- THE FIX IS HERE ---
# Create a generic home directory that will be owned by the runtime user.
RUN mkdir -p /home/user && chown 1000:1000 /home/user

# Set the entrypoint to the real binary
ENTRYPOINT [ "/app/camoufox-bin" ]