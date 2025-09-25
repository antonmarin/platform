#!/usr/bin/env sh
set -euf

usage() {
	cat <<EOF
Local tunnel with auto-reconnect
	Usage:   $0 TUNNEL CONNECTION

	Example: $0 8022:127.0.0.1:22 user@server.com
EOF
}

tunnel() {
	tunnel="${1:-}"
	connection="${2:-}"

	[ -n "$tunnel" ] || {
		printf '❌ TUNNEL not set\n' >&2
		return 1
	}

	[ -n "$connection" ] || {
		printf '❌ CONNECTION not set\n' >&2
		return 1
	}

	ssh -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -N -L "$tunnel" "$connection"
}

############################  MAIN  ############################
#log "Started with: %s\n" "$@"
case ${1:-usage} in
usage) usage ;;
*) tunnel "${2:-}" "${3:-}" || usage ;;
esac
