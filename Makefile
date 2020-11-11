.DEFAULT_GOAL=help
include .env
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
lint-yaml:
	docker run --rm -v "$(PWD):/app" -w /app sdesbure/yamllint sh -c "yamllint platform_apps/**/*.yml"

run: #? start built in services locally
	cd platform_apps/ingress && docker-compose up -d
	cd platform_apps/index && docker-compose up -d
stop:
	cd platform_apps/ingress && docker-compose down --remove-orphans
	cd platform_apps/index && docker-compose down --remove-orphans

ssh:
	ssh antonmarin@$(PLATFORM_SERVER_IP)
