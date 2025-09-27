# ---------------------------------------------------------------------------
# docker.mk – einheitliche Docker/Buildx Targets ohne Redundanz
# ---------------------------------------------------------------------------
##@ Docker

# ---------------------------------------------------------------------------
# Beispiele für Aufrufe
# ---------------------------------------------------------------------------
#
# ▶ Lokale Builds
#   make build                        # baut Image für PHP_VERSION aus .env (lokale Plattform)
#   PHP_VERSION=8.3 make build        # baut gezielt Version 8.3
#   make build-all                    # baut alle Versionen lokal (8.1–8.4)
#
# ▶ Multi-Arch Test Builds (lokal, mit :amd64-test und :arm64-test Tags)
#   make build-test-images
#
# ▶ Multi-Arch Push (CI/CD)
#   make build-remote-all             # baut & pusht alle Versionen (8.1–8.4) + latest-Tag
#   make build-remote-latest          # baut & pusht nur die "latest" Version (8.4)
#
# ▶ Cache steuern
#   make build-remote-all CACHE_BACKEND=gha
#   make build-remote-all CACHE_BACKEND=registry CACHE_REF=docker.io/ORG/phpcli:buildcache
#   make build-remote-all NO_CACHE=true
# ---------------------------------------------------------------------------

PLATFORMS       ?= linux/amd64 linux/arm64
PHP_VERSIONS    := 8.1 8.2 8.3 8.4
LATEST_VERSION  := $(word $(words $(PHP_VERSIONS)),$(PHP_VERSIONS))

CACHE_BACKEND   ?= auto          #  auto|none|local|registry|gha
CACHE_REF       ?=               # z.B. docker.io/yourorg/phpcli:buildcache (nur bei registry)
CACHE_DIR       ?= .buildx-cache # nur bei local

BUILD_ARGS = \
  --build-arg PHP_VERSION="$(PHP_VERSION)" \
  --build-arg PHP_MEMORY_LIMIT="$(PHP_MEMORY_LIMIT)" \
  --build-arg PHP_MAX_EXECUTION_TIME="$(PHP_MAX_EXECUTION_TIME)" \
  --build-arg PHP_TIMEZONE="$(PHP_TIMEZONE)" \
  --build-arg APCU_SHM_SIZE="$(APCU_SHM_SIZE)" \
  --build-arg OPCACHE_MEMORY_CONSUMPTION="$(OPCACHE_MEMORY_CONSUMPTION)" \
  --build-arg OPCACHE_MAX_ACCELERATED_FILES="$(OPCACHE_MAX_ACCELERATED_FILES)" \
  --build-arg OPCACHE_REVALIDATE_FREQ="$(OPCACHE_REVALIDATE_FREQ)" \
  --build-arg PHP_ERROR_REPORTING='$(PHP_ERROR_REPORTING)' \
  --build-arg PHP_DISPLAY_ERRORS="$(PHP_DISPLAY_ERRORS)" \
  --build-arg PHP_LOG_ERRORS="$(PHP_LOG_ERRORS)" \
  --build-arg ALPINE_VERSION="$(ALPINE_VERSION)" \
  --build-arg APCU_VERSION="$(APCU_VERSION)" \
  --build-arg REDIS_VERSION="$(REDIS_VERSION)" \
  --build-arg XDEBUG_VERSION="$(XDEBUG_VERSION)"

build: ## Build local native platform php image for .env PHP_VERSION
	$(DOCKER_COMPOSE) build $$( [ "$(NO_CACHE)" = "true" ] && echo "--no-cache" ) $(PHP_IMAGE_NAME)
	docker images --filter dangling=true -q | xargs -r docker rmi
.PHONY: build

build-all: ## Build local native platform php image for all defined PHP_VERSIONS
	@for version in $(PHP_VERSIONS); do \
		echo ">>> Building $(PHP_IMAGE_NAME) for PHP $$version ..."; \
		PHP_VERSION=$$version $(DOCKER_COMPOSE) build $$( [ "$(NO_CACHE)" = "true" ] && echo "--no-cache" ) $(PHP_IMAGE_NAME); \
		echo ">>> Created: $(PHP_IMAGE_NAME) (PHP $$version)"; \
	done
	docker images --filter dangling=true -q | xargs -r docker rmi
.PHONY: build-all

build-remote-all: .buildx-create
	@set -e; \
	$(call cache_flags) ; \
	PLATFORM_CSV="$$(printf '%s' "$(PLATFORMS)" | tr ' ' ',')"; \
	for version in $(PHP_VERSIONS); do \
	  echo ">>> Building $(DOCKER_HUB)/$(PHP_IMAGE_NAME):$$version (multi-arch: $$PLATFORM_CSV) ..."; \
	  tags="-t $(DOCKER_HUB)/$(PHP_IMAGE_NAME):$$version"; \
	  $(call buildx_one,$$PLATFORM_CSV,$$tags,--push --provenance=mode=max --attest=type=sbom,src/Dockerfile,./src); \
	  echo ">>> Pushed: $(DOCKER_HUB)/$(PHP_IMAGE_NAME):$$version"; \
	done; \
	echo ">>> Setting latest tag -> $(LATEST_VERSION)"; \
	docker buildx imagetools create \
	  --tag $(DOCKER_HUB)/$(PHP_IMAGE_NAME):latest \
	  $(DOCKER_HUB)/$(PHP_IMAGE_NAME):$(LATEST_VERSION)
.PHONY: build-remote-all

build-remote-version: .buildx-create
	@set -e; \
	$(call cache_flags) ; \
	PLATFORM_CSV="$$(printf '%s' "$(PLATFORMS)" | tr ' ' ',')"; \
	tags="-t $(DOCKER_HUB)/$(PHP_IMAGE_NAME):$(PHP_VERSION)"; \
	$(call buildx_one,$$PLATFORM_CSV,$$tags,--push --provenance=mode=max --attest=type=sbom,src/Dockerfile,./src); \
	if [ "$(PHP_VERSION)" = "$(LATEST_VERSION)" ]; then \
	  echo ">>> Setting latest tag -> $(LATEST_VERSION)"; \
	  docker buildx imagetools create \
	    --tag $(DOCKER_HUB)/$(PHP_IMAGE_NAME):latest \
	    $(DOCKER_HUB)/$(PHP_IMAGE_NAME):$(LATEST_VERSION); \
	fi
.PHONY: build-remote-version

build-remote-latest: .buildx-create
	@set -e; \
	$(call cache_flags) ; \
	PLATFORM_CSV="$$(printf '%s' "$(PLATFORMS)" | tr ' ' ',')"; \
	tags="-t $(DOCKER_HUB)/$(PHP_IMAGE_NAME):latest -t $(DOCKER_HUB)/$(PHP_IMAGE_NAME):$(LATEST_VERSION)"; \
	$(call buildx_one,$$PLATFORM_CSV,$$tags,--push --provenance=mode=max --attest=type=sbom,src/Dockerfile,./src)
.PHONY: build-remote-latest

build-test-images: .buildx-create ## Build multiplatform images for local testing (iteriert PLATFORMS; optional Cache)
	@set -e; \
	$(call cache_flags) ; \
	for arch in $(PLATFORMS); do \
	  tag="-t $(PHP_IMAGE_NAME):$${arch##*/}-test"; \
	  echo "Building test image for $$arch ..."; \
	  $(call buildx_one,$$arch,$$tag,--load,src/Dockerfile,./src); \
	done; \
	echo "Local multiplatform build completed. Use $(PHP_IMAGE_NAME):arm64-test and $(PHP_IMAGE_NAME):amd64-test"
.PHONY: build-test-images

clean: ## Stops and removes containers, images and caches
	$(DOCKER_COMPOSE) down --volumes --remove-orphans --rmi "all"
	@docker buildx prune -a -f
	docker images --filter dangling=true -q | xargs -r docker rmi
.PHONY: clean

shell: ## Run a shell inside the container (compose service)
	$(DOCKER_COMPOSE) run --rm -it $(PHP_IMAGE_NAME) sh
.PHONY: shell

# ---------------------------------------------------------------------------

.buildx-create:
	@docker buildx ls | grep -q 'multiarch-builder' || docker buildx create --name multiarch-builder --use
.PHONY: .buildx-create

define cache_flags
  set +u; \
  BACKEND="$${CACHE_BACKEND:-auto}"; \
  if [ -z "$$BACKEND" ] || [ "$$BACKEND" = "auto" ]; then \
    if [ "$${GITHUB_ACTIONS:-}" = "true" ]; then BACKEND="gha"; \
    elif [ "$${CI:-}" = "true" ]; then BACKEND="registry"; \
    else BACKEND="none"; fi; \
  fi; \
  case "$$BACKEND" in \
    gha)      CFROM="--cache-from=type=gha"; \
              CTO="--cache-to=type=gha,mode=max";; \
    registry) if [ -z "$(CACHE_REF)" ]; then echo "ERROR: CACHE_REF required for registry backend" >&2; exit 2; fi; \
              CFROM="--cache-from=type=registry,ref=$(CACHE_REF)"; \
              CTO="--cache-to=type=registry,ref=$(CACHE_REF),mode=max";; \
    local)    mkdir -p "$(CACHE_DIR)"; \
              CFROM="--cache-from=type=local,src=$(CACHE_DIR)"; \
              CTO="--cache-to=type=local,dest=$(CACHE_DIR),mode=max";; \
    none|"")  CFROM=""; CTO="";; \
    *)        echo "ERROR: unknown CACHE_BACKEND=$$BACKEND" >&2; exit 2;; \
  esac; \
  echo ">> Cache backend: $$BACKEND"
endef

define buildx_one
  docker buildx build \
    --platform $(1) \
    $$CFROM $$CTO \
    $(BUILD_ARGS) \
    $$( [ "$(NO_CACHE)" = "true" ] && echo "--no-cache" ) \
    $(2) \
    $(3) \
    -f $(4) \
    $(5)
endef
