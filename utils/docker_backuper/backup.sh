#!/bin/env bash
set -euf # Прекратить выполнение при любой ошибке

usage() {
	cat <<EOF
Usage:
  $0 backup  VOLUME [ARCHIVE]
     Environment:
       RETENTION                               Delete files older than N
                                               Int days count or rclone --min-age string https://rclone.org/docs/#time-options when RCLONE_REMOTE set
  $0 restore VOLUME ARCHIVE
Examples:
  $0 backup  my_volume
  $0 restore my_volume ./my_volume-2025-09-12.tar.gz

EOF
	exit 1
}

# Проверяем наличие docker
command -v docker >/dev/null 2>&1 || {
	echo "docker not found in PATH"
	exit 1
}

[ $# -ge 2 ] || usage
MODE=$1
VOLUME=$2
SCRIPT_DIR="$(dirname $(realpath $0))"
ARCHIVE=${3:-"${SCRIPT_DIR}/${VOLUME}-$(date +%F).tar.gz"}
BACKUP_PATH=$(dirname "$ARCHIVE")

# Удаление старых файлов через Х. Int дней или https://rclone.org/docs/#time-options если установлен RCLONE_REMOTE
RETENTION="${RETENTION:-}" # https://rclone.org/docs/#time-options

export RCLONE_CONFIG_REMOTE_TYPE="${RCLONE_CONFIG_REMOTE_TYPE:-s3}"
export RCLONE_CONFIG_REMOTE_PROVIDER="${RCLONE_CONFIG_REMOTE_PROVIDER:-Minio}"
export RCLONE_CONFIG_REMOTE_NO_CHECK_BUCKET="${RCLONE_CONFIG_REMOTE_NO_CHECK_BUCKET:-true}"
export RCLONE_CONFIG_REMOTE_ENDPOINT="${RCLONE_CONFIG_REMOTE_ENDPOINT:-https://minio:9000}"
export RCLONE_CONFIG_REMOTE_ACCESS_KEY_ID="${RCLONE_CONFIG_REMOTE_ACCESS_KEY_ID:-minioadmin}"
export RCLONE_CONFIG_REMOTE_SECRET_ACCESS_KEY="${RCLONE_CONFIG_REMOTE_SECRET_ACCESS_KEY:-minioadmin}"
export RCLONE_CONFIG_REMOTE_FORCE_PATH_STYLE="${RCLONE_CONFIG_REMOTE_FORCE_PATH_STYLE:-true}"
# регион обязателен даже для MinIO
export RCLONE_CONFIG_REMOTE_REGION="${RCLONE_CONFIG_REMOTE_REGION:-us-east-1}"
# какую конфигурацию rclone использовать. Локально если переменная не установлена
RCLONE_REMOTE="${RCLONE_REMOTE:-}"

# Проверка существования тома
volume_exists() {
	docker volume ls | awk '{print $2}' | grep -x "$1" >/dev/null 2>&1
}

# ---------- backup ----------
do_backup() {
	volume_exists "$VOLUME" || {
		echo "volume $VOLUME not found"
		exit 1
	}

	file=$(basename "$ARCHIVE")
	echo "backing up volume $VOLUME -> $ARCHIVE"
	docker run --rm \
		-v "$VOLUME:/data:ro" \
		-v "$BACKUP_PATH:/backup" \
		alpine \
		tar -czf "/backup/$file" -C /data .
	echo "done: $(ls -lh "$ARCHIVE" | awk '{print $5}')"

	if [ -n "${RETENTION}" ]; then
		if [ -n "${RCLONE_REMOTE}" ]; then
			echo "➜ Cleaning files older than ${RETENTION} in ${RCLONE_REMOTE}:${BACKUP_PATH}/ …"
			rclone -q delete "${RCLONE_REMOTE}:${BACKUP_PATH}/" --min-age "${RETENTION}"
		else
			echo "➜ Cleaning files older than ${RETENTION} in ${BACKUP_PATH} …"
			# shellcheck disable=SC2086
			find "$BACKUP_PATH" -type f -name '*.gpg' -mtime +${RETENTION} -exec rm -f {} +
		fi
		echo "✔ Cleanup finished"
	else
		echo "- RETENTION not set – skipping cleanup"
	fi
}

# ---------- restore ----------
do_restore() {
	[ -f "$ARCHIVE" ] || {
		echo "archive $ARCHIVE not found"
		exit 1
	}

	if volume_exists "$VOLUME"; then
		printf "volume %s already exists. Overwrite? [y/N] " "$VOLUME"
		read answer
		case "$answer" in
		y | Y) ;;
		*)
			echo "cancelled"
			exit 0
			;;
		esac
	else
		echo "creating volume $VOLUME"
		docker volume create "$VOLUME" >/dev/null
	fi

	file=$(basename "$ARCHIVE")
	echo "restoring $ARCHIVE into volume $VOLUME"
	docker run --rm \
		-v "$VOLUME:/data" \
		-v "$BACKUP_PATH:/backup" \
		alpine \
		tar -xzf "/backup/$file" -C /data
	echo "$VOLUME restore complete"
}

case "$MODE" in
backup) do_backup ;;
restore) do_restore ;;
*) usage ;;
esac
