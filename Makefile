.DEFAULT_GOAL=help

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
