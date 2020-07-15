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

lint: lint-terraform lint-yaml lint-cloud-init #? pre-run validations
lint-terraform:
	terraform validate
	docker run --rm -v $(PWD):/data -t wata727/tflint
lint-yaml:
	docker run --rm -v "$(PWD):/app" -w /app sdesbure/yamllint sh -c "yamllint **/*.yml"
lint-cloud-init:
	docker run --rm -v "$(PWD):/app" -w /app nonstatic/cloud-init:v1 cloud-init devel schema --config-file /app/cloud-init.cfg

run: run-ingress #? start built in services locally
run-ingress:
	docker-compose -f ingress/docker-compose.yml --env-file ingress/.env up -d
ssh:
	ssh antonmarin@$(PLATFORM_SERVER_IP)
