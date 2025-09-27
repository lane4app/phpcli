
# Lane4 Digital PHP CLI

![Build Status](https://github.com/lane4app/phpcli/actions/workflows/ci.yml/badge.svg)
[![Docker Image Version](https://img.shields.io/docker/v/lane4app/phpcli?sort=semver)](https://hub.docker.com/r/lane4app/phpcli)

### Versioned, multi-arch PHP CLI images for fast, reproducible console apps

Our images target **PHP 8.1 – 8.4**, ship for **linux/amd64** and **linux/arm64**, and are tuned for stable, production-grade CLI workloads.

---

## ✨ What’s new (highlights)

- **Consistent multi-arch builds** (AMD64 + ARM64) via `buildx`.
- **OPcache enabled by default on all platforms**, **JIT disabled** for reliability.
- **PECL extensions pinned** for reproducible builds: `apcu`, `redis`, `xdebug`.
- **Production-first runtime**: two-stage build, minimal runtime deps, non‑root user.
- **Runtime-configurable PHP** via ENV and an entrypoint that generates a dedicated `99-runtime-config.ini` at container start.
- **Composer preinstalled** and ready to use.

---

## 🔑 Fundamental advantages

- **Reproducibility:** Pinned PECL versions + controlled Alpine base = stable, repeatable builds.
- **Performance & stability:** OPcache on; JIT off (fewer edge-case crashes, especially on ARM).
- **Lean runtime:** Full toolchain only in build stage; runtime stays slim.
- **Security by default:** Non‑root `appuser`, health checks, and clear configuration boundaries.
- **Multi-version strategy:** Single Dockerfile builds 8.1/8.2/8.3/8.4 with identical behavior.

---

## Architectures & Tags

- Architectures: **linux/amd64**, **linux/arm64**
- Tags: `8.1`, `8.2`, `8.3`, `8.4`, and `latest` → tracks the highest declared version

Images are published on Docker Hub: https://hub.docker.com/r/lane4app/phpcli/tags

---

## ⚠️ OPcache & JIT

- ✅ **OPcache** is **enabled** for CLI and FPM contexts.
- 🚫 **JIT** is **disabled** across all platforms for compatibility and stability.

This yields the best real-world reliability for CLI workloads while keeping bytecode caching benefits.

---

## Features

- **Extensions (built/installed):**
  - Core DB: `pdo`, `pdo_mysql`, `mysqli`
  - Caching: `apcu` (PECL), `redis` (PECL)
  - Web/IO: `curl`, `soap`
  - Data: `dom`, `zip`
  - i18n: `mbstring`, `intl`
  - Processes: `pcntl`
  - Math: `bcmath`
  - Images & metadata: `gd` (with FreeType/JPEG), `exif`
  - Networking: `sockets`
  - Debug: `xdebug` (PECL)
  - Performance: `opcache` (built-in)
- **Runtime:**
  - **Alpine Linux** base, production `php.ini`
  - **Non-root user** (`appuser`), **healthcheck**, **Composer** preinstalled
  - Entry-point generates `99-runtime-config.ini` from ENV

---

## 🔧 Configurable parameters (complete)

### Build arguments (become runtime defaults)
| ARG | Default | Description |
|---|---:|---|
| `PHP_VERSION` | `8.3` | PHP minor version to build (supports `8.1`, `8.2`, `8.3`, `8.4`). |
| `ALPINE_VERSION` | `3.20` | Alpine base tag used by `php:<PHP_VERSION>-cli-alpine<ALPINE_VERSION>`. |
| `APCU_VERSION` | `5.1.27` | PECL apcu version (pinned). |
| `REDIS_VERSION` | `6.2.0` | PECL redis version (pinned). |
| `XDEBUG_VERSION` | `3.4.5` | PECL xdebug version (pinned). |
| `PHP_MEMORY_LIMIT` | `512M` | Default memory limit. |
| `PHP_MAX_EXECUTION_TIME` | `0` | Default max execution time (0 = unlimited). |
| `PHP_TIMEZONE` | `UTC` | Default timezone. |
| `APCU_SHM_SIZE` | `64M` | Default APCu shared memory size. |
| `OPCACHE_MEMORY_CONSUMPTION` | `128` | OPcache memory in MB. |
| `OPCACHE_MAX_ACCELERATED_FILES` | `4000` | OPcache max cached files. |
| `OPCACHE_REVALIDATE_FREQ` | `2` | OPcache revalidate interval (sec). |
| `PHP_ERROR_REPORTING` | `E_ALL & ~E_DEPRECATED & ~E_STRICT` | PHP error level. |
| `PHP_DISPLAY_ERRORS` | `Off` | PHP display errors. |
| `PHP_LOG_ERRORS` | `On` | PHP log errors. |

> These ARGs are copied into `ENV` in the runtime stage to serve as sane defaults. All can be overridden at `docker run ... -e VAR=...`.

### Runtime environment (PHP core / entrypoint-driven)
| ENV | Type | Default | Notes |
|---|---|---:|---|
| `PHP_MEMORY_LIMIT` | string | `512M` | `memory_limit` |
| `PHP_MAX_EXECUTION_TIME` | int | `0` | `max_execution_time` |
| `PHP_TIMEZONE` | string | `UTC` | `date.timezone` |
| `PHP_ERROR_REPORTING` | string | `E_ALL & ~E_DEPRECATED & ~E_STRICT` | |
| `PHP_DISPLAY_ERRORS` | `On/Off` | `Off` | |
| `PHP_LOG_ERRORS` | `On/Off` | `On` | |
| `APCU_SHM_SIZE` | string | `64M` | `apc.shm_size`, `apc.enable_cli=1` fixed |
| `OPCACHE_MEMORY_CONSUMPTION` | int | `128` | |
| `OPCACHE_MAX_ACCELERATED_FILES` | int | `4000` | |
| `OPCACHE_REVALIDATE_FREQ` | int | `2` | |
| *(fixed by entrypoint)* | — | — | `opcache.enable=1`, `opcache.enable_cli=1`, `opcache.jit=off`, `opcache.jit_buffer_size=0`, `expose_php=Off`. |

### Runtime environment (Xdebug)
| ENV | Default | Description |
|---|---:|---|
| `XDEBUG_MODE` | `off` | e.g. `debug`, `develop`, `trace`, `coverage` (comma-separated). |
| `XDEBUG_START_WITH_REQUEST` | *(unset)* | `yes`/`no`. |
| `XDEBUG_CLIENT_HOST` | *(unset)* | Typically `host.docker.internal` (macOS/Windows) or host IP. |
| `XDEBUG_CLIENT_PORT` | `9003` | Client port. |
| `XDEBUG_IDEKEY` | *(unset)* | IDE key. |
| `XDEBUG_LOG_LEVEL` | `0` | 0–10 (verbose). |

> Xdebug is installed and enabled; behavior is controlled by the env vars above. If `XDEBUG_MODE=off`, Xdebug loads but stays inactive.

---

## Usage

### Build (single version)
```bash
docker build -t lane4app/phpcli:8.3   --build-arg PHP_VERSION=8.3   --build-arg ALPINE_VERSION=3.20   --build-arg APCU_VERSION=5.1.27   --build-arg REDIS_VERSION=6.2.0   --build-arg XDEBUG_VERSION=3.4.5   ./src
```

### Run
```bash
# Print PHP info
docker run --rm lane4app/phpcli:8.3 php -i | less

# Override runtime PHP settings
docker run --rm -e PHP_MEMORY_LIMIT=1G -e PHP_TIMEZONE=Europe/Berlin lane4app/phpcli:8.3 php -r 'echo ini_get("memory_limit"),"\n",ini_get("date.timezone"),"\n";'

# Enable Xdebug on-demand
docker run --rm -e XDEBUG_MODE=debug -e XDEBUG_START_WITH_REQUEST=yes   -e XDEBUG_CLIENT_HOST=host.docker.internal -e XDEBUG_CLIENT_PORT=9003   lane4app/phpcli:8.3 php your-script.php
```

### Notes on size
- Runtime stage contains only what’s needed to **run** your app and **Composer**.
- Build toolchain lives only in the build stage.
- `mysql-client`) is not installed by default

---

## Healthcheck

The image includes a healthcheck that validates PHP and Composer:
```
php --version >/dev/null && composer --version >/dev/null
```

---

## Makefile targets (optional)

If you use our `support/docker.mk`, you get helpers for local and remote multi-arch builds, cache backends, and tests. See comments in that file for examples:

- `make build` – build the compose service locally
- `make build-all` – build all PHP versions locally (native arch)
- `make build-test-images` – build amd64/arm64 test tags locally (with optional caching)
- `make build-remote-all` – push multi-arch tags for all PHP versions
- `make test-all` – run OPcache/JIT and extension checks on both arches

---

## License

MIT © Lane4 Digital GmbH
