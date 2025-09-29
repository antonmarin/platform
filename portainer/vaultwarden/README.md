# Secrets storage
https://github.com/dani-garcia/vaultwarden

- to generate admin token `docker run -it --rm vaultwarden/server:1.34.3-alpine /vaultwarden hash`

# Restore

- start without application VW_REPLICAS=0
- `docker compose run backuper '/backuper/backuper.sh pg_restore latest "$$BACKUP_PATH"'`
