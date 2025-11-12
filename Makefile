.DEFAULT_GOAL=help
-include .env
export $(shell sed 's/=.*//' .env)

help: #? help me
	$(info Available targets)
	@awk '/^@?[a-zA-Z\-\\_0-9]+:/ { \
		nb = sub( /^#\? /, "", helpMsg ); \
		if(nb == 0) { \
			helpMsg = $$0; \
			nb = sub( /^[^:]*:.* #\? /, "", helpMsg ); \
		} \
		if (nb) \
			printf "\033[1;31m%-" width "s\033[0m %s\n", $$1, helpMsg; \
	} \
	{ helpMsg = $$0 }' \
	$(MAKEFILE_LIST) | column -ts:

format: #? format terraform files
	terraform fmt

lint: lint-terraform lint-yaml #? pre-run validations
lint-terraform:
	terraform validate
	docker run --rm -v $(PWD):/data -t wata727/tflint
lint-yaml: # https://yamllint.readthedocs.io/en/latest/rules.html
	docker run --rm -v "$(PWD):/app" -w /app sdesbure/yamllint sh -c "yamllint platform_apps/**/*.yml"
	docker run --rm -v $(PWD):/apps -w /apps sdesbure/yamllint yamllint /portainer/

portainer-hash-password: #? hash admin password for portainer. used with --admin-password. in /run/secrets/portainer plain is used
	@read -p "Enter new password: " password; \
	htpasswd -nb -B admin $$password | cut -d ":" -f 2
portainer-reset-password:
	docker run --rm -v "$(PWD)/portainer:/data" portainer/helper-reset-password

run: #? start built in services locally
	cd platform_apps/ingress && docker compose up -d
	cd platform_apps/index && docker compose up -d
stop:
	cd platform_apps/index && docker compose down --remove-orphans
	cd platform_apps/ingress && docker compose down --remove-orphans

ssh:
	ssh -o StrictHostKeyChecking=no root@$(PLATFORM_SERVER_IP)

fwd-traefik:
	ssh -NL 8080:localhost:8080 root@$(PLATFORM_SERVER_IP)

fwd-portainer:
	ssh -NL 9001:$(PLATFORM_SERVER_IP):9001 root@$(PLATFORM_SERVER_IP)

fwd-docker:
	ssh -NL 2375:127.0.0.1:2375 root@$(PLATFORM_SERVER_IP)

update-utils:
	docker buildx build --push --platform=linux/amd64,linux/arm64 -t antonmarin/backuper ./utils/backuper

test-restore-vw:
	docker compose -f portainer/vaultwarden/compose.yml down --remove-orphans || true
	docker volume rm vaultwarden_database || true
	docker compose -f portainer/vaultwarden/compose.yml run --remove-orphans backuper '/backuper/backuper.sh pg_restore latest "$$BACKUP_PATH"'
test-restore-lw:
	docker compose -f portainer/linkwarden/compose.yml down --remove-orphans || true
	docker volume rm linkwarden_database || true
	docker compose -f portainer/linkwarden/compose.yml run --remove-orphans backuper '/backuper/backuper.sh pg_restore latest "$$BACKUP_PATH"'
test-restore-port:
	docker compose -f portainer/portainer/compose.yml run --remove-orphans backuper '/backuper/backuper.sh dir_restore latest "$$BACKUP_PATH" /tmp/test'
