#!/usr/bin/env sh

# do not rename, it installs by name. see nas every-hour.sh

currentFilePath="$(realpath $(dirname $0))"

compose="$currentFilePath/compose.yml"
echo "Starting portainer from $compose"
# Check if docker-compose exists and is executable
if command -v docker-compose >/dev/null 2>&1; then
    # Run docker-compose up
    echo "Running 'docker-compose up'"
    docker-compose -f "$compose" up -d
else
    # Fall back to docker compose
    echo "Running 'docker compose up'"
    docker compose -f "$compose" up -d
fi
