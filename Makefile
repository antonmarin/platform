SHELL = /bin/sh
.DEFAULT_GOAL=help
.PHONY: help
GOOS=$(shell uname -s | tr '[:upper:]' '[:lower:]')
-include .env
export $(shell sed 's/=.*//' .env)

# decorations
COLOR_NONE="\\033[0m"
COLOR_BLUE="\\033[34m"
COLOR_CYAN="\\033[36m"
COLOR_GREEN="\\033[32m"
COLOR_YELLOW="\\033[33m"
COLOR_ORANGE="\\033[43m"
COLOR_RED="\\033[31m"

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

apply:
	terraform apply -auto-approve

format: #? format terraform files
	terraform fmt

/usr/local/bin/terraform:
	curl -so ./terraform.zip http://terraform-mirror.timeweb.cloud/1.5.7/terraform_1.5.7_darwin_amd64.zip \
	&& unzip ./terraform.zip terraform && rm ./terraform.zip \
	&& echo "$(COLOR_CYAN)Enter sudo password next if requested$(COLOR_NONE)"\
	&& sudo mv ./terraform /usr/local/bin && terraform -v
.env:
	cp .env.dist .env
.terraform:
	terraform init

init: .env /usr/local/bin/terraform .terraform

lint: lint-terraform lint-yaml #? pre-run validations
lint-terraform:
	terraform validate
	docker run --rm -v $(PWD):/data -t wata727/tflint
lint-yaml: # https://yamllint.readthedocs.io/en/latest/rules.html
	docker run --rm -v $(PWD):/platform -w /apps sdesbure/yamllint yamllint /platform/portainer/

dirs:
	@echo "$(COLOR_BLUE)Доступные ДЦ ruvds:$(COLOR_NONE)" && curl -sX GET \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $(RUVDS_API_TOKEN)" \
		https://api.ruvds.com/v2/datacenters | jq -r '.datacenters[].name'
	@echo "$(COLOR_BLUE)Доступные ОС ruvds:$(COLOR_NONE)" && curl -sX GET \
	   -H "Content-Type: application/json" \
	   -H "Authorization: Bearer $(RUVDS_API_TOKEN)" \
	   "https://api.ruvds.com/v2/os" | jq -r '.os[] | .type + " - " + .name'
	@echo "$(COLOR_BLUE)Доступные тарифы ruvds:$(COLOR_NONE)" && curl -sX GET \
	   -H "Content-Type: application/json" \
	   -H "Authorization: Bearer $(RUVDS_API_TOKEN)" \
	   "https://api.ruvds.com/v2/tariffs" | jq

	@echo "$(COLOR_BLUE)Доступные локации twc:$(COLOR_NONE)" && curl -sX GET \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $(TWC_TOKEN)" \
      "https://api.timeweb.cloud/api/v2/locations" | jq

plan: #? dry run infrastructure changes
	terraform plan

portainer-hash-password: #? hash admin password for portainer. used with --admin-password. in /run/secrets/portainer plain is used
	@read -p "Enter new password: " password; \
	htpasswd -nb -B admin $$password | cut -d ":" -f 2
portainer-reset-password:
	docker run --rm -v "$(PWD)/portainer:/data" portainer/helper-reset-password

run: #? start built in services locally
	cd portainer/ingress && docker compose up -d
	cd portainer/s3 && docker compose up -d
stop:
	cd portainer/s3 && docker compose down --remove-orphans
	cd portainer/ingress && docker compose down --remove-orphans

ssh:
	ssh -o StrictHostKeyChecking=no root@$(PLATFORM_SERVER_IP)

fwd-traefik:
	ssh -NL 8080:localhost:8080 root@$(PLATFORM_SERVER_IP)

update-utils: #? update platform utils
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
test-restore-karakeep:
	docker compose -f portainer/karakeep/compose.yml run --remove-orphans backuper '/backuper/backuper.sh sqlite_restore latest "$$BACKUP_PATH" /data/db.db'
