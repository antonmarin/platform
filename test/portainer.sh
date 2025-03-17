#!/usr/bin/env sh
set -eu

source ./framework.sh
importEnv ./portainer.env

reset() {
	if command -v docker-compose >/dev/null 2>&1; then
        local compose="docker-compose"
    else
        local compose="docker compose"
    fi
    PROJECT_ROOT="$(realpath $( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )/..)"
    $compose --progress quiet -f "$PROJECT_ROOT/portainer/compose.yml" down --remove-orphans
}
trap reset EXIT

should 'start portainer on localhost:9000'
source portainer.env
# Get the absolute path of the parent directory
PROJECT_ROOT="$(realpath $( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )/..)"
$PROJECT_ROOT/portainer/portainer.sh > /dev/null
curl -sIf http://localhost:9000 2>&1 | grep -q "HTTP/1.1 200 OK"
ok
