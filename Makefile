.DEFAULT_GOAL=help
include .env
export $(shell sed 's/=.*//' .env)

help:
	@printf "\
		help\t this help\n\
		format\t Format terraform files\n\
		lint\t Validate configuration files\n\
	"

format:
	terraform fmt

lint: lint-terraform lint-yaml
lint-terraform:
	terraform validate
lint-yaml:
	docker run --rm -v "$(PWD):/app" -w /app sdesbure/yamllint sh -c "yamllint **/*.yml"

run: run-ingress
run-ingress:
	export $$(egrep -v '^#' ingress/.env | xargs) && docker-compose -f ingress/docker-compose.yml up -d
ssh:
	ssh antonmarin@$(PLATFORM_SERVER_IP)
