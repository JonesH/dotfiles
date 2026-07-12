# dotfiles — common operations. `make` or `make help` lists targets.
.DEFAULT_GOAL := help
SHELL := bash
ARCH ?=

.PHONY: help bootstrap packages check sync lint test test-uv

help: ## show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n",$$1,$$2}'

bootstrap: ## symlink dotfiles into $HOME (idempotent, backs up originals)
	@install/bootstrap.sh

packages: ## bootstrap + install CLI/uv tools (tools.tsv, uv-tools.txt)
	@install/bootstrap.sh --packages

check: ## dry run: show what bootstrap would change, touch nothing
	@install/bootstrap.sh --check

sync: ## pull + re-bootstrap + push (the dfsync engine)
	@install/sync.sh

lint: ## bash -n every install script (+ shellcheck if present)
	@for f in install/*.sh install/git-hooks/pre-commit; do bash -n "$$f" && echo "ok  $$f"; done
	@if command -v shellcheck >/dev/null; then shellcheck -S warning install/*.sh && echo "ok  shellcheck clean"; else echo "· shellcheck not installed, skipped"; fi

test: ## full unattended bootstrap dress-rehearsal in a Debian container (ARCH=amd64 to match the VPS)
	@test/test-full-bootstrap.sh $(ARCH)

test-uv: ## isolated uv-tools/aider install test in a container
	@test/test-bootstrap.sh $(ARCH)
