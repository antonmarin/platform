#!/usr/bin/env sh

#volumes="/volume1/@docker/volumes"
#storage="/volume1/Storage"
#
#rm "$volumes/media_manga/_data"
#ln -s "$storage/Manga" "$volumes/media_manga/_data"
#
#rm "$volumes/media_books/_data"
#ln -s "$storage/Books" "$volumes/media_books/_data"
#
#rm "$volumes/media_audio/_data"
#ln -s "$storage/Audio" "$volumes/media_audio/_data"
#
#rm "$volumes/media_video/_data"
#ln -s "$storage/Video" "$volumes/media_video/_data"

currentFilePath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )
compose="$currentFilePath/compose.yml"
echo "Starting portainer from $compose"
# Check if docker-compose exists and is executable
if command -v docker-compose >/dev/null 2>&1; then
    # Run docker-compose up
    echo "Running 'docker-compose up'"
    docker-compose --progress quiet -f "$compose" up -d --wait
else
    # Fall back to docker compose
    echo "Running 'docker compose up'"
    docker compose --progress quiet -f "$compose" up -d --wait
fi
