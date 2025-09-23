#!/usr/bin/env sh
set -euf

############################ UTILS #############################
DEBUG=${DEBUG:-false}
log() {
	# shellcheck disable=SC2059
	${DEBUG} && printf "$@"
	return 0
}

#################################################################

usage() {
	cat <<EOF
Backup util
	To get usage guide: $0 <command> --help
	Commands:
	- pg_backup
	- pg_restore
	  utils:
	- encrypt
	- decrypt
	- upload
	- download
Features:
- Compress and encrypting
- Upload to S3
- Removes outdated backups
EOF
}

######################## POSTGRESQL ###################
PGHOST="${PGHOST:-localhost}"
PGPORT="${PGPORT:-5432}"
POSTGRES_DB="${POSTGRES_DB:-database}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-}"

TMP_DIR="${TMP_DIR:-/tmp}"
BACKUPS_STORAGE_DIR="${BACKUPS_STORAGE_DIR:-./backups}"
pg_backup() {
	storageDir="${1:---help}"
	archive_filename=${2:-${POSTGRES_DB}_$(date +%F_%H-%M).sql.gz}

	case "$storageDir" in
	--help | -h)
		cat <<EOF
Backup postgresql database to tar archive
	Usage: pg_backup STORAGE_DIR <ARCHIVE_FILENAME|latest>

	Environment variables (* - required):
		PGHOST                   Postgres host (default: localhost)
		PGPORT                   Postgres port (default: 5432)
		POSTGRES_DB              Database name (default: database)
		POSTGRES_USER            Postgres user (default: postgres)
		POSTGRES_PASSWORD*       Postgres user password
		TMP_DIR                  Directory to isolate archive (default: /tmp)

		GPG_PASSPHRASE*          Password phrase for encryption / decryption
		RCLONE_REMOTE            Use rclone configuration. Uploads/downloads backup if set. (default: not set)
		RETENTION                Delete files older than N
		                         Int days count or rclone --min-age string https://rclone.org/docs/#time-options when RCLONE_REMOTE set
EOF
		return 0
		;;
	esac

	if ! command -v pg_dump >/dev/null 2>&1; then
		printf '❌ pg_dump not found in PATH\n' >&2
		return 1
	fi

	[ -n "$POSTGRES_PASSWORD" ] || {
		printf '❌ POSTGRES_PASSWORD empty\n' >&2
		return 1
	}
	echo "${PGHOST}:${PGPORT}:${POSTGRES_DB}:${POSTGRES_USER}:${POSTGRES_PASSWORD}" >~/.pgpass && chmod 600 ~/.pgpass

	target="${TMP_DIR}/${archive_filename}"
	log '➜ Dumping %s into %s …\n' "${POSTGRES_DB}" "${target}"
	pg_dump -w -h "$PGHOST" -p "$PGPORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f - | gzip >"$target"
	log '✔ Backup created: %s\n' "$target"

	crypt="$target.gpg"
	DEBUG=false encrypt "$target" "$crypt"
	log '✔ Backup encrypted: %s\n' "$crypt"

	DEBUG=false upload "$crypt" "${storageDir}"
	log '✔ Backup uploaded to "%s"\n' "${storageDir}$crypt"
}

pg_restore() {
	archive_filename=${1:---help}
	storageDir="${2:-}"

	case "$archive_filename" in
	--help | -h)
		cat <<EOF
Restores postgresql database from tar archive
	Usage: pg_restore <ARCHIVE_FILENAME|latest> STORAGE_DIR

	Environment variables (* - required):
		PGHOST                   Postgres host (default: localhost)
		PGPORT                   Postgres port (default: 5432)
		POSTGRES_DB              Database name (default: database)
		POSTGRES_USER            Postgres user (default: postgres)
		POSTGRES_PASSWORD*       Postgres user password
		TMP_DIR                  Directory to isolate archive (default: /tmp)

		GPG_PASSPHRASE*          Password phrase for encryption / decryption
		RCLONE_REMOTE            Use rclone configuration. Uploads/downloads backup if set. (default: not set)
EOF
		return 0
		;;
	esac

	[ -n "$storageDir" ] || {
		printf '❌ storageDir not set\n' >&2
		return 1
	}

	if ! command -v psql >/dev/null 2>&1; then
		printf "❌ psql not found in PATH\n" >&2
		return 1
	fi

	[ -n "$POSTGRES_PASSWORD" ] || {
		printf "❌ POSTGRES_PASSWORD empty\n" >&2
		return 1
	}
	echo "${PGHOST}:${PGPORT}:${POSTGRES_DB}:${POSTGRES_USER}:${POSTGRES_PASSWORD}" >~/.pgpass && chmod 600 ~/.pgpass

	isolating_dest=$(DEBUG=false download "$storageDir" "$archive_filename" "$TMP_DIR")

#	isolating_dest="${TMP_DIR}/$(basename "${archive_filename%.gpg}").gpg" # not exists
	log '➜ Decrypting & restoring "%s" …\n' "$isolating_dest"
	DEBUG=false decrypt "$isolating_dest" - | zcat | psql -h "$PGHOST" -p "$PGPORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB"
	log '✔ Restore finished\n'
}

############################  ENCRYPTING ################

GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"
GPG_OPTS="${GPG_OPTS:---batch --yes --passphrase-fd 0 --cipher-algo AES256 --compress-algo 2}"

encrypt() {
	inputFilepath="${1:-}"
	outputFilepath="${2:-${inputFilepath}.gpg}"

	case "$inputFilepath" in
	--help | -h)
		printf 'Encrypts file to output using gpg
	Usage: encrypt INPUT OUTPUT

	Environment variables:
		GPG_PASSPHRASE		passphrase to encrypt with
'
		return 0
		;;
	esac

	if [ ! -f "$inputFilepath" ]; then
		printf '❌ File "%s" does NOT exist\n' "$inputFilepath"
		return 1
	fi
	inputFilepath="$(realpath "$inputFilepath")"

	if ! command -v gpg >/dev/null 2>&1; then
		printf '❌ gpg not found in PATH\n' >&2
		return 1
	fi
	[ -n "$GPG_PASSPHRASE" ] || {
		printf '❌ GPG_PASSPHRASE empty\n' >&2
		return 1
	}

	log '➜ Encrypting %s to %s...\n' "$inputFilepath" "$outputFilepath"
	# shellcheck disable=SC2086
	printf '%s' "$GPG_PASSPHRASE" | gpg $GPG_OPTS -c --output "$outputFilepath" "$inputFilepath"
	log '✔ Encrypting finished: %s\n' "$outputFilepath"

	return 0
}

decrypt() {
	inputFilepath="${1:---help}"
	outputFilepath="${2:-${inputFilepath%.gpg}}"

	case "$inputFilepath" in
	--help | -h)
		printf 'Decrypts file to output using gpg
	Usage: decrypt INPUT OUTPUT

	Environment variables:
		GPG_PASSPHRASE		passphrase to decrypt with
'
		return 0
		;;
	esac

	if [ ! -f "$inputFilepath" ]; then
		printf '❌ File "%s" does NOT exist\n' "$inputFilepath"
		return 1
	fi
	inputFilepath="$(realpath "$inputFilepath")"

	if ! command -v gpg >/dev/null 2>&1; then
		printf '❌ gpg not found in PATH\n' >&2
		return 1
	fi
	[ -n "$GPG_PASSPHRASE" ] || {
		printf '❌ GPG_PASSPHRASE empty\n' >&2
		return 1
	}

	log '➜ Decrypting %s to %s...\n' "$inputFilepath" "$outputFilepath"
	# shellcheck disable=SC2086
	printf '%s' "$GPG_PASSPHRASE" | gpg $GPG_OPTS -d --output "$outputFilepath" "$inputFilepath"
	log '✔ Decrypting finished: %s\n' "$outputFilepath"

	return 0
}

############################ UPLOADING ########################

export RCLONE_CONFIG_REMOTE_TYPE="${RCLONE_CONFIG_REMOTE_TYPE:-s3}"
export RCLONE_CONFIG_REMOTE_PROVIDER="${RCLONE_CONFIG_REMOTE_PROVIDER:-Minio}"
export RCLONE_CONFIG_REMOTE_NO_CHECK_BUCKET="${RCLONE_CONFIG_REMOTE_NO_CHECK_BUCKET:-true}"
export RCLONE_CONFIG_REMOTE_ENDPOINT="${RCLONE_CONFIG_REMOTE_ENDPOINT:-https://minio:9000}"
export RCLONE_CONFIG_REMOTE_ACCESS_KEY_ID="${RCLONE_CONFIG_REMOTE_ACCESS_KEY_ID:-minioadmin}"
export RCLONE_CONFIG_REMOTE_SECRET_ACCESS_KEY="${RCLONE_CONFIG_REMOTE_SECRET_ACCESS_KEY:-minioadmin}"
export RCLONE_CONFIG_REMOTE_FORCE_PATH_STYLE="${RCLONE_CONFIG_REMOTE_FORCE_PATH_STYLE:-true}"
export RCLONE_CONFIG_REMOTE_REGION="${RCLONE_CONFIG_REMOTE_REGION:-us-east-1}"
RCLONE_REMOTE="${RCLONE_REMOTE:-}"
# shellcheck disable=SC2046
SCRIPT_DIR="$(dirname $(realpath "$0"))"

upload() {
	sourceFilename="${1:---help}"
	storageDir="${2:-}"

	case "$sourceFilename" in
	--help | -h)
		printf 'Uploads file to backups storageDir
	Usage: upload SOURCE_FILENAME STORAGE_DIR

	Environment variables:
		RCLONE_REMOTE		use rclone connection (not used by default)
		RETENTION		remove storageDir files older than N (not used by default)
					Int days count or rclone --min-age string https://rclone.org/docs/#time-options when RCLONE_REMOTE set
'
		return 0
		;;
	esac

	if [ -n "$RCLONE_REMOTE" ] && ! command -v rclone >/dev/null 2>&1; then
		printf '❌ rclone not found in PATH\n' >&2
		return 1
	fi

	if [ -n "$RCLONE_REMOTE" ]; then
		rclone lsd "$RCLONE_REMOTE:$storageDir" >/dev/null 2>&1 || {
			printf '❌ Storage directory "%s" not found or not directory\n' "$storageDir" >&2
			return 1
		}
		storageDir="$RCLONE_REMOTE:$storageDir"
	else
		if [ ! -d "$storageDir" ]; then
			mkdir -p "$storageDir" ||
				printf '❌ Storage directory "%s" not found or not directory\n' "$storageDir" >&2 && return 1
		fi
	fi

	if [ -n "$RCLONE_REMOTE" ]; then
		log '➜ Uploading %s -> %s …\n' "$sourceFilename" "$storageDir"
		rclone -q copy "$sourceFilename" "$storageDir"
		log '✔ Remote backup %s uploaded to %s\n' "$sourceFilename" "$storageDir"
	else
		log '➜ Moving %s -> %s …\n' "$sourceFilename" "$storageDir"
		mv "$sourceFilename" "$storageDir"
		log '✔ Backup ready at %s\n' "$storageDir/$sourceFilename"
	fi

	if [ -n "${RETENTION}" ]; then
		if [ -n "${RCLONE_REMOTE}" ]; then
			log '➜ Cleaning files older than %s in %s …' "$RETENTION" "$storageDir"
			rclone -q delete "$storageDir" --min-age "$RETENTION"
		else
			log "➜ Cleaning files older than %s in %s …" "$RETENTION" "$storageDir"
			# shellcheck disable=SC2086
			find "$storageDir" -type f -mtime +${RETENTION} -exec rm -f {} +
		fi
		log '✔ Cleanup finished'
	else
		log '- RETENTION not set – skipping cleanup'
	fi

	return 0
}

download() {
	storageDir="${1:---help}"
	sourceFilename="${2:-latest}"
	destinationDir="${3:-${SCRIPT_DIR}}"

	case "$storageDir" in
	--help | -h)
		printf 'Downloads file from backups storageDir
	Usage: download STORAGE_DIR <latest|SOURCE_FILENAME> DESTINATION_DIR

	Environment variables:
		RCLONE_REMOTE		use rclone connection (not used by default)
'
		return 0
		;;
	esac

	if [ -n "$RCLONE_REMOTE" ] && ! command -v rclone >/dev/null 2>&1; then
		printf '❌ rclone not found in PATH\n' >&2
		return 1
	fi

	if [ -n "$RCLONE_REMOTE" ]; then
		rclone lsd "$RCLONE_REMOTE:$storageDir" >/dev/null 2>&1 || {
			printf '❌ Storage directory "%s" not found or not directory\n' "$storageDir" >&2
			return 1
		}
		storageDir="$RCLONE_REMOTE:$storageDir"
	else
		if [ ! -d "$storageDir" ]; then
			printf '❌ Storage directory "%s" not found or not directory\n' "$storageDir" >&2
			return 1
		fi
	fi

	if [ "$sourceFilename" = "latest" ]; then
		if [ -n "$RCLONE_REMOTE" ]; then
			sourceFilename=$(rclone -q lsf "$storageDir" 2>/dev/null | sort -r | head -1)
		else
			sourceFilename=$(find "$storageDir" -maxdepth 1 -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)
		fi
		[ -n "$sourceFilename" ] || {
			printf '❌ No files found in %s\n' "$storageDir" >&2
			return 1
		}
		log '✔ Latest file selected: %s\n' "$sourceFilename"
	fi

	if [ -n "$RCLONE_REMOTE" ]; then
		log '➜ Downloading %s -> %s …\n' "$storageDir/$sourceFilename" "$destinationDir"
		rclone -q copy --ignore-existing --ignore-times "$storageDir/$sourceFilename" "$destinationDir"
		log '✔ Remote backup %s downloaded to %s\n' "$storageDir/$sourceFilename" "$destinationDir"
	else
		log '➜ Moving %s -> %s …\n' "$storageDir/$sourceFilename" "$destinationDir"
		cp "$storageDir/$sourceFilename" "$destinationDir"
		log '✔ Backup ready at '
	fi

	printf '%s' "$destinationDir/$sourceFilename" # return result
	return 0
}

############################  MAIN  ############################
log "Started with: %s\n" "$@"
case ${1:-usage} in
encrypt) encrypt "${2:-}" "${3:-}" || encrypt --help ;;
decrypt) decrypt "${2:-}" "${3:-}" || decrypt --help ;;
upload) upload "${2:-}" "${3:-}" "${4:-}" || upload --help ;;
download) download "${2:-}" "${3:-}" "${4:-}" || download --help ;;
pg_backup) pg_backup "${2:-}" "${3:-}" ;;
pg_restore) pg_restore "${2:-}" "${3:-}" ;;
*) usage ;;
esac
