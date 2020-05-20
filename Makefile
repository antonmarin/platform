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

lint:
	terraform validate

ssh:
	ssh antonmarin@$(PLATFORM_SERVER_IP)
