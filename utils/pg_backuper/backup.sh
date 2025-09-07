#!/usr/bin/env sh
set -euf

############################  CONFIG  ############################
PGHOST="${PGHOST:-localhost}"
PGPORT="${PGPORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-database}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-}"

# Директорий с бэкапами. Включает имя бакета при использовании s3
TMP_DIR="${TMP_DIR:-/tmp}"
BACKUP_PATH="${BACKUP_PATH:-./backups}"
DUMP_FILE="${DUMP_FILE:-${POSTGRES_DB}_$(date +%F_%H-%M).sql.gz}"

# Шифрование (gpg symmetric)
GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"
GPG_OPTS="${GPG_OPTS:---batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 --compress-algo 2}"

# shellcheck disable=SC2034
export RCLONE_CONFIG_S3REMOTE_TYPE="${RCLONE_CONFIG_S3REMOTE_TYPE:-s3}"
export RCLONE_CONFIG_S3REMOTE_PROVIDER="${RCLONE_CONFIG_S3REMOTE_PROVIDER:-Minio}"
export RCLONE_CONFIG_S3REMOTE_NO_CHECK_BUCKET="${RCLONE_CONFIG_S3REMOTE_NO_CHECK_BUCKET:-true}"
export RCLONE_CONFIG_S3REMOTE_ENDPOINT="${RCLONE_CONFIG_S3REMOTE_ENDPOINT:-https://minio:9000}"
export RCLONE_CONFIG_S3REMOTE_ACCESS_KEY_ID="${RCLONE_CONFIG_S3REMOTE_ACCESS_KEY_ID:-minioadmin}"
export RCLONE_CONFIG_S3REMOTE_SECRET_ACCESS_KEY="${RCLONE_CONFIG_S3REMOTE_SECRET_ACCESS_KEY:-minioadmin}"
export RCLONE_CONFIG_S3REMOTE_FORCE_PATH_STYLE="${RCLONE_CONFIG_S3REMOTE_FORCE_PATH_STYLE:-true}"
# регион обязателен даже для MinIO
export RCLONE_CONFIG_S3REMOTE_REGION="${RCLONE_CONFIG_S3REMOTE_REGION:-us-east-1}"
# какую конфигурацию rclone использовать. Локально если переменная не установлена
RCLONE_REMOTE="${RCLONE_REMOTE:-}"

# Удаление старых файлов через Х. Int дней или https://rclone.org/docs/#time-options если установлен RCLONE_REMOTE
RETENTION="${RETENTION:-}" # https://rclone.org/docs/#time-options

#################################################################

usage(){
  cat << EOF
Backup Postgresql database.
Features:
- Compress and encrypting required
- Upload to S3
- Removes outdated backups

Usage:
  $0                                   – create encrypted backup & upload to S3 if RCLONE_REMOTE set
     Environment:
       RETENTION                               Delete files older than N
                                               Int days count or rclone --min-age string https://rclone.org/docs/#time-options when RCLONE_REMOTE set

  $0 restore <file.sql.gz.gpg|latest>  – restore database
     Options:
       file.sql.gz.gpg                         – filename to decrypt & restore
       latest                                  – auto-pick newest backup

Supported environment variables (* - required):
  PGHOST*                                      Postgres host (default: localhost)
  PGPORT*                                      Postgres port (default: 5432)
  POSTGRES_USER*                               Postgres user (default: postgres)
  POSTGRES_DB*                                 Database name (default: database)
  POSTGRES_PASSWORD*
  GPG_PASSPHRASE*                              Password phrase for encryption / decryption
  TMP_DIR*                                     Temp directory for work files (default: /tmp)
  BACKUP_PATH*                                 Path to directory with backups. S3 bucket name prefixed when RCLONE_REMOTE used. (default: ./backups)
  RCLONE_REMOTE                                Use rclone configuration. Uploads/downloads backup if set. (default: not set)

EOF
}

# ---------- BACKUP ----------
backup() {
	if ! command -v pg_dump >/dev/null 2>&1; then
		echo "❌ pg_dump not found in PATH" >&2
		return 1
	fi
	[ -n "$POSTGRES_PASSWORD" ] || {
		echo "❌ POSTGRES_PASSWORD empty" >&2
		exit 1
	}
	echo "${PGHOST}:${PGPORT}:${POSTGRES_DB}:${POSTGRES_USER}:${POSTGRES_PASSWORD}" >~/.pgpass && chmod 600 ~/.pgpass

	if ! command -v gpg >/dev/null 2>&1; then
		echo "❌ gpg not found in PATH" >&2
		return 1
	fi
	[ -n "$GPG_PASSPHRASE" ] || {
		echo "❌ GPG_PASSPHRASE empty" >&2
		exit 1
	}

	if [ -n "${RCLONE_REMOTE}" ]; then
		if ! command -v rclone >/dev/null 2>&1; then
			echo "❌ rclone not found in PATH" >&2
			return 1
		fi
	else
		if [ ! -d "$BACKUP_PATH" ]; then
			echo "❌ Directory $DIR does NOT exist" >&2
			return 1
		fi
	fi

	# execution

	target="${TMP_DIR}/${DUMP_FILE}"

	echo "➜ Dumping ${POSTGRES_DB} into ${target} …"
	pg_dump -w -h "$PGHOST" -p "$PGPORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f - | gzip > "$target"
	echo "✔ Backup created: $target"

	crypt="$target.gpg"
	echo "➜ Encrypting ${target} -> ${crypt} …"
	# shellcheck disable=SC2086
	printf '%s' "$GPG_PASSPHRASE" | gpg $GPG_OPTS --output "$crypt" "$target"
	rm -f "$target"
	echo "✔ Encrypting finished: $crypt"

	if [ -n "${RCLONE_REMOTE}" ]; then
		echo "➜ Uploading ${crypt} to ${RCLONE_REMOTE}:${BACKUP_PATH}/ …"
		rclone -q copy "$crypt" "${RCLONE_REMOTE}:${BACKUP_PATH}/"
		echo "✔ Upload finished: ${RCLONE_REMOTE}:${BACKUP_PATH}/$(basename "$crypt")"
	else
		echo "➜ Moving ${crypt} to ${BACKUP_PATH}/ …"
		mv "$crypt" "${BACKUP_PATH}/"
		echo "✔ Moved: ${BACKUP_PATH}/$(basename "$crypt")"
	fi

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

# ---------- RESTORE ----------
restore() {
	filename=${1:-}

	if ! command -v psql >/dev/null 2>&1; then
		echo "❌ psql not found in PATH" >&2
		return 1
	fi
	[ -n "$POSTGRES_PASSWORD" ] || {
		echo "❌ POSTGRES_PASSWORD empty" >&2
		exit 1
	}
	echo "${PGHOST}:${PGPORT}:${POSTGRES_DB}:${POSTGRES_USER}:${POSTGRES_PASSWORD}" >~/.pgpass && chmod 600 ~/.pgpass

	[ -n "$filename" ] || {
		echo "❌ Missing filename argument (or 'latest')" >&2
		exit 1
	}

	if ! command -v gpg >/dev/null 2>&1; then
		echo "❌ gpg not found in PATH" >&2
		return 1
	fi
	[ -n "$GPG_PASSPHRASE" ] || {
		echo "❌ GPG_PASSPHRASE empty" >&2
		exit 1
	}

	if [ -n "${BACKUP_PATH}" ] && ! command -v rclone >/dev/null 2>&1; then
		echo "❌ rclone not found in PATH" >&2
		return 1
	fi

	# если указали latest — найдём самый свежий архив
	if [ "$filename" = "latest" ]; then
		if [ -n "$RCLONE_REMOTE" ]; then
			filename=$(rclone -q lsf "$RCLONE_REMOTE:$BACKUP_PATH" 2>/dev/null | grep '\.gpg$' | sort -r | head -1)
			[ -n "$filename" ] || {
				echo "❌ No .gpg files found in $RCLONE_REMOTE:$BACKUP_PATH" >&2
				return 1
			}
		else
			filename=$(find "$BACKUP_PATH" -maxdepth 1 -type f -name '*.gpg' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)
			[ -n "$filename" ] || {
				echo "❌ No .gpg files found locally in $(realpath "$BACKUP_PATH")" >&2
				return 1
			}
		fi
		echo "✔ Latest filename selected: $filename"
	fi

	# сначала изолируем от изменений
	local_dest=$TMP_DIR/$(basename "$filename")
	if [ -n "$RCLONE_REMOTE" ]; then
		echo "➜ Downloading $RCLONE_REMOTE:$BACKUP_PATH/$filename -> $local_dest …"
		rclone -q copy "$RCLONE_REMOTE:$BACKUP_PATH/$filename" "$TMP_DIR/"
		echo "✔ Remote backup $RCLONE_REMOTE:$BACKUP_PATH/$filename downloaded to $TMP_DIR"
	else
		echo "➜ Moving $BACKUP_PATH/$filename -> $local_dest …"
		cp "$BACKUP_PATH/$filename" "$local_dest"
		echo "✔ Backup ready at $local_dest"
	fi

	[ -f "$local_dest" ] || {
		echo "❌ Error preparing backup to use: $local_dest" >&2
		ls -la "$TMP_DIR"
		exit 1
	}

	echo "➜ Decrypting & restoring …"
	printf '%s' "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 -d "$local_dest" | zcat |
		psql -h "$PGHOST" -p "$PGPORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB"
	echo "✔ Restore finished"
}

############################  MAIN  ############################
case ${1:-usage} in
backup) backup ;;
restore) restore "$2" ;;
*) usage ;;
esac
