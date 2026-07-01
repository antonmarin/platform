SHELL = /bin/sh
.DEFAULT_GOAL=help
.PHONY: help test-restore-sqlite test-restore-dir test-restore-pg
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

init: .env /usr/local/bin/terraform .terraform #? also after adding provider

lint: lint-terraform lint-yaml #? pre-run validations
lint-terraform:
	terraform validate
	docker run --rm -v $(PWD):/data -t wata727/tflint
lint-yaml: # https://yamllint.readthedocs.io/en/latest/rules.html
	docker run --rm -v $(PWD):/platform -w /apps sdesbure/yamllint yamllint /platform/portainer/

plan: #? dry run infrastructure changes
	terraform plan

portainer-hash-password: #? hash admin password for portainer. used with --admin-password. in /run/secrets/portainer plain is used
	@read -p "Enter new password: " password; \
	htpasswd -nb -B admin $$password | cut -d ":" -f 2
portainer-reset-password: #? reset portainer admin password
	docker run --rm -v "$(PWD)/portainer:/data" portainer/helper-reset-password

up: #? start basic infra
	cd portainer/ingress && docker compose up -d
	cd portainer/s3 && docker compose up -d
down: #? stop basic infra
	cd portainer/s3 && docker compose down --remove-orphans
	cd portainer/ingress && docker compose down --remove-orphans

ssh:
	ssh -o StrictHostKeyChecking=no root@$(PLATFORM_SERVER_IP)

fwd-traefik:
	ssh -NL 8080:localhost:8080 root@$(PLATFORM_SERVER_IP)

build-index: #? update image of index server
	docker buildx build --push --platform=linux/amd64,linux/arm64 -t antonmarin/clubindex ./portainer/index
update-utils: #? update platform utils
	docker buildx build --push --platform=linux/amd64,linux/arm64 -t antonmarin/backuper ./utils/backuper

test-restore-vw:
	@make APP_NAME=vaultwarden test-restore-pg
test-restore-lw:
	@make APP_NAME=linkwarden test-restore-pg
test-restore-port:
	@make APP_NAME=portainer test-restore-dir
test-restore-keycloak:
	@make APP_NAME=keycloak test-restore-pg
test-restore-wallabag:
	@make APP_NAME=linkwarden test-restore-pg

define ensure_var_app_name
app_name="$(strip $(APP_NAME))"; \
if [ -z "$$app_name" ]; then \
    read -p "Enter APP_NAME: " app_name; \
fi;
endef
test-restore-sqlite:
	@$(ensure_var_app_name) \
	docker compose -f portainer/$$app_name/compose.yml run --remove-orphans backuper '/backuper/backuper.sh sqlite_restore latest "$$BACKUP_PATH" /data/db.db'
test-restore-dir:
	@$(ensure_var_app_name) \
	docker compose -f portainer/$$app_name/compose.yml run --remove-orphans backuper '/backuper/backuper.sh dir_restore latest "$$BACKUP_PATH" /tmp/test'
test-restore-pg:
	@$(ensure_var_app_name) \
	docker compose -f portainer/$$app_name/compose.yml down --remove-orphans || true; \
	docker volume rm $${app_name}_database || true; \
	docker compose -f portainer/$$app_name/compose.yml run --remove-orphans backuper '/backuper/backuper.sh pg_restore latest "$$BACKUP_PATH"' && echo "$$app_name backup verified" || docker compose -f portainer/$$app_name/compose.yml logs
