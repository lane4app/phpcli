SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables
DOCKER_COMPOSE := docker compose -f src/docker-compose.yml
NO_CACHE ?= false
.DEFAULT_GOAL := help

include src/.env

# ---------------------------------------------------------------------------
# Makefiles einbinden
# ---------------------------------------------------------------------------
include support/docker.mk
include support/test.mk
include support/ssh.mk

# ---------------------------------------------------------------------------
# Debug-Target zum Testen der Umgebung
# ---------------------------------------------------------------------------
##@ Info
info: ## Aktuelle Umgebungseinstellungen anzeigen
	@printf "\033[34m%-15s\033[0m %s\n" "ALPINE_VERSION                :" "$(ALPINE_VERSION)"
	@printf "\033[34m%-15s\033[0m %s\n" "APCU_VERSION                  :" "$(APCU_VERSION)"
	@printf "\033[34m%-15s\033[0m %s\n" "REDIS_VERSION                 :" "$(REDIS_VERSION)"
	@printf "\033[34m%-15s\033[0m %s\n" "XDEBUG_VERSION                :" "$(XDEBUG_VERSION)"
	@printf "\033[34m%-15s\033[0m %s\n" "PHP_MEMORY_LIMIT              :" "$(PHP_MEMORY_LIMIT)"
	@printf "\033[34m%-15s\033[0m %s\n" "PHP_MAX_EXECUTION_TIME        :" "$(PHP_MAX_EXECUTION_TIME)"
	@printf "\033[34m%-15s\033[0m %s\n" "PHP_TIMEZONE                  :" "$(PHP_TIMEZONE)"
	@printf "\033[34m%-15s\033[0m %s\n" "APCU_SHM_SIZE                 :" "$(APCU_SHM_SIZE)"
	@printf "\033[34m%-15s\033[0m %s\n" "OPCACHE_MEMORY_CONSUMPTION    :" "$(OPCACHE_MEMORY_CONSUMPTION)"
	@printf "\033[34m%-15s\033[0m %s\n" "OPCACHE_MAX_ACCELERATED_FILES :" "$(OPCACHE_MAX_ACCELERATED_FILES)"
	@printf "\033[34m%-15s\033[0m %s\n" "OPCACHE_REVALIDATE_FREQ       :" "$(OPCACHE_REVALIDATE_FREQ)"
	@printf "\033[34m%-15s\033[0m %s\n" "OPCACHE_JIT_MODE              :" "$(OPCACHE_JIT_MODE)"
	@printf "\033[34m%-15s\033[0m %s\n" "OPCACHE_JIT_BUFFER_SIZE       :" "$(OPCACHE_JIT_BUFFER_SIZE)"
	@printf "\033[34m%-15s\033[0m %s\n" "PHP_ERROR_REPORTING           :" "$(PHP_ERROR_REPORTING)"
	@printf "\033[34m%-15s\033[0m %s\n" "PHP_DISPLAY_ERRORS            :" "$(PHP_DISPLAY_ERRORS)"
	@printf "\033[34m%-15s\033[0m %s\n" "PHP_LOG_ERRORS                :" "$(PHP_LOG_ERRORS)"
	@printf "\033[34m%-15s\033[0m %s\n" "XDEBUG_MODE                   :" "$(XDEBUG_MODE)"
	@printf "\033[34m%-15s\033[0m %s\n" "XDEBUG_START_WITH_REQUEST     :" "$(XDEBUG_START_WITH_REQUEST)"
	@printf "\033[34m%-15s\033[0m %s\n" "XDEBUG_CLIENT_HOST            :" "$(XDEBUG_CLIENT_HOST)"
	@printf "\033[34m%-15s\033[0m %s\n" "XDEBUG_CLIENT_PORT            :" "$(XDEBUG_CLIENT_PORT)"
	@printf "\033[34m%-15s\033[0m %s\n" "XDEBUG_LOG_LEVEL              :" "$(XDEBUG_LOG_LEVEL)"
.PHONY: info

# ---------------------------------------------------------------------------
# Hilfe-Target (farbig & rubriziert)
# ---------------------------------------------------------------------------
help:
	@echo ""
	@printf "\033[1mUsage:\033[0m\n"
	@echo "  make <target>"
	@awk '\
		BEGIN { cols = "\033[36m%-28s\033[0m" } \
		/^##@ / {                                       \
			sub(/^##@ /,"");                             \
			printf "\n\033[1m%s\033[0m\n", $$0; next }   \
		/^[A-Za-z0-9_.-]+:.*##/ {                       \
			split($$0, a, ":"); tgt = a[1];             \
			sub(/^.*## /,"");                           \
			printf "  " cols " %s\n", tgt, $$0 }        \
	' $(MAKEFILE_LIST)
.PHONY: help
