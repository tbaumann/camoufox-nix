#!/usr/bin/env sh
# ~/camoufox-docker/run-camoufox.sh

IMAGE_NAME="camoufox-app"

echo "Building/updating Docker image '$IMAGE_NAME'..."
docker build -t "$IMAGE_NAME" .

echo "Starting Camoufox from Docker container..."

# Run the container with flags to connect to the host's Wayland/XWayland display.
# This is the modern, correct method and does NOT use .Xauthority.
docker run \
    --rm \
    -it \
    --user "$(id -u):$(id -g)" \
    -e DISPLAY=$DISPLAY \
    -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
    -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR \
    -e HOME=/home/user \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR \
    --name camoufox \
    "$IMAGE_NAME"
