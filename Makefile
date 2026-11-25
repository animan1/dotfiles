.DEFAULT_GOAL := help
.PHONY: help setup

help: ## Show this help.
	@printf 'Make targets:\n\n'; \
	awk -F ':.*## ' '/^[a-zA-Z0-9_.-]+:.*## / {printf "    %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install tools and plugins, link dotfiles, and set the login shell.
	@sh ./install.sh
