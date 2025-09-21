#!/bin/sh
set -euf # Прекратить выполнение при любой ошибке

#docker run --rm -v portainer_portainer_app:/data -v ./backup:/backup alpine \
#    tar -czf "/backup/portainer-backup-$(date +%Y%m%d-%H%M).tar.gz" -C /data .

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
ARCHIVE=${3:-}
SCRIPT_DIR="$(dirname $(realpath $0))"
# Удаление старых файлов через Х. Int дней или https://rclone.org/docs/#time-options если установлен RCLONE_REMOTE
RETENTION="${RETENTION:-}" # https://rclone.org/docs/#time-options

# Дефолтное имя архива при backup
if [ "$MODE" = "backup" ] && [ -z "$ARCHIVE" ]; then
	ARCHIVE="${SCRIPT_DIR}/${VOLUME}-$(date +%F).tar.gz"
fi
BACKUP_PATH="$(dirname $ARCHIVE)"

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
	# Директория, куда положим архив
	dir=$(dirname "$ARCHIVE")
	file=$(basename "$ARCHIVE")
	echo "backing up volume $VOLUME -> $ARCHIVE"
	docker run --rm \
		-v "$VOLUME:/data:ro" \
		-v "$dir:/backup" \
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
		read ans
		case "$ans" in
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
	dir=$(dirname "$ARCHIVE")
	file=$(basename "$ARCHIVE")
	echo "restoring $ARCHIVE into volume $VOLUME"
	docker run --rm \
		-v "$VOLUME:/data" \
		-v "$dir:/backup" \
		alpine \
		tar -xzf "/backup/$file" -C /data
	echo "restore complete"
}

case "$MODE" in
backup) do_backup ;;
restore) do_restore ;;
*) usage ;;
esac
