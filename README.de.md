# Lane4 Digital PHP CLI

![Build Status](https://github.com/lane4app/phpcli/actions/workflows/ci.yml/badge.svg)
[![Docker Image Version](https://img.shields.io/docker/v/lane4app/phpcli?sort=semver)](https://hub.docker.com/r/lane4app/phpcli)

### Versionierte, Multi-Arch PHP CLI Images für schnelle, reproduzierbare Konsolenanwendungen

Unsere Images unterstützen **PHP 8.1 – 8.4**, laufen auf **linux/amd64** und **linux/arm64** und sind optimiert für stabile, produktionsreife CLI-Workloads.

---

## ✨ Was ist neu (Highlights)

- **Konsistente Multi-Arch Builds** (AMD64 + ARM64) via `buildx`.
- **OPcache standardmäßig auf allen Plattformen aktiviert**, **JIT deaktiviert** für Stabilität.
- **PECL-Extensions festgesetzt** für reproduzierbare Builds: `apcu`, `redis`, `xdebug`.
- **Production-first Runtime**: Zwei-Stage-Build, minimale Runtime-Dependencies, Non‑Root User.
- **Laufzeit-konfigurierbares PHP** über ENV und ein Entrypoint, der beim Containerstart eine dedizierte `99-runtime-config.ini` erzeugt.
- **Composer vorinstalliert** und sofort nutzbar.

---

## 🔑 Fundamentale Vorteile

- **Reproduzierbarkeit:** Fixierte PECL-Versionen + kontrolliertes Alpine-Base = stabile, wiederholbare Builds.
- **Performance & Stabilität:** OPcache an; JIT aus (weniger Edge-Case-Crashes, besonders auf ARM).
- **Schlanke Runtime:** Voller Toolchain nur im Build-Stage; Runtime bleibt minimal.
- **Security by default:** Non‑Root `appuser`, Healthchecks und klare Konfigurationsgrenzen.
- **Multi-Version-Strategie:** Ein einziges Dockerfile baut 8.1/8.2/8.3/8.4 mit identischem Verhalten.

---

## Architekturen & Tags

- Architekturen: **linux/amd64**, **linux/arm64**
- Tags: `8.1`, `8.2`, `8.3`, `8.4` und `latest` → verweist auf die höchste deklarierte Version

Images werden auf Docker Hub veröffentlicht: https://hub.docker.com/r/lane4app/phpcli/tags

---

## ⚠️ OPcache & JIT

- ✅ **OPcache** ist **aktiviert** für CLI und FPM Kontexte.
- 🚫 **JIT** ist **deaktiviert** auf allen Plattformen für Kompatibilität und Stabilität.

Dies bietet die beste Zuverlässigkeit in realen CLI-Workloads bei gleichzeitiger Nutzung der Bytecode-Caching-Vorteile.

---

## Features

- **Erweiterungen (gebaut/installiert):**
  - Core DB: `pdo`, `pdo_mysql`, `mysqli`
  - Caching: `apcu` (PECL), `redis` (PECL)
  - Web/IO: `curl`, `soap`
  - Daten: `dom`, `zip`
  - i18n: `mbstring`, `intl`
  - Prozesse: `pcntl`
  - Mathematik: `bcmath`
  - Bilder & Metadaten: `gd` (mit FreeType/JPEG), `exif`
  - Networking: `sockets`
  - Debug: `xdebug` (PECL)
  - Performance: `opcache` (built-in)
- **Runtime:**
  - **Alpine Linux** Base, produktives `php.ini`
  - **Non-root User** (`appuser`), **Healthcheck**, **Composer** vorinstalliert
  - Entrypoint generiert `99-runtime-config.ini` aus ENV

---

## 🔧 Konfigurierbare Parameter (komplett)

### Build-Argumente (werden zu Runtime-Defaults)
| ARG | Standard | Beschreibung |
|---|---:|---|
| `PHP_VERSION` | `8.3` | PHP Minor Version zum Bauen (`8.1`, `8.2`, `8.3`, `8.4`). |
| `ALPINE_VERSION` | `3.20` | Alpine Base Tag genutzt von `php:<PHP_VERSION>-cli-alpine<ALPINE_VERSION>`. |
| `APCU_VERSION` | `5.1.27` | PECL apcu Version (fixiert). |
| `REDIS_VERSION` | `6.2.0` | PECL redis Version (fixiert). |
| `XDEBUG_VERSION` | `3.4.5` | PECL xdebug Version (fixiert). |
| `PHP_MEMORY_LIMIT` | `512M` | Standard Memory Limit. |
| `PHP_MAX_EXECUTION_TIME` | `0` | Standard Max Execution Time (0 = unbegrenzt). |
| `PHP_TIMEZONE` | `UTC` | Standard Zeitzone. |
| `APCU_SHM_SIZE` | `64M` | Standard APCu Shared Memory Size. |
| `OPCACHE_MEMORY_CONSUMPTION` | `128` | OPcache Speicher in MB. |
| `OPCACHE_MAX_ACCELERATED_FILES` | `4000` | OPcache max gecachte Dateien. |
| `OPCACHE_REVALIDATE_FREQ` | `2` | OPcache Revalidate Intervall (Sek.). |
| `PHP_ERROR_REPORTING` | `E_ALL & ~E_DEPRECATED & ~E_STRICT` | PHP Error Level. |
| `PHP_DISPLAY_ERRORS` | `Off` | PHP Display Errors. |
| `PHP_LOG_ERRORS` | `On` | PHP Log Errors. |

> Diese ARGs werden im Runtime-Stage in `ENV` kopiert und dienen als Standardwerte. Alle können via `docker run ... -e VAR=...` überschrieben werden.

### Runtime-Umgebung (PHP Core / Entrypoint-gesteuert)
| ENV | Typ | Standard | Hinweise |
|---|---|---:|---|
| `PHP_MEMORY_LIMIT` | string | `512M` | `memory_limit` |
| `PHP_MAX_EXECUTION_TIME` | int | `0` | `max_execution_time` |
| `PHP_TIMEZONE` | string | `UTC` | `date.timezone` |
| `PHP_ERROR_REPORTING` | string | `E_ALL & ~E_DEPRECATED & ~E_STRICT` | |
| `PHP_DISPLAY_ERRORS` | `On/Off` | `Off` | |
| `PHP_LOG_ERRORS` | `On/Off` | `On` | |
| `APCU_SHM_SIZE` | string | `64M` | `apc.shm_size`, `apc.enable_cli=1` fixiert |
| `OPCACHE_MEMORY_CONSUMPTION` | int | `128` | |
| `OPCACHE_MAX_ACCELERATED_FILES` | int | `4000` | |
| `OPCACHE_REVALIDATE_FREQ` | int | `2` | |
| *(durch Entrypoint fixiert)* | — | — | `opcache.enable=1`, `opcache.enable_cli=1`, `opcache.jit=off`, `opcache.jit_buffer_size=0`, `expose_php=Off`. |

### Runtime-Umgebung (Xdebug)
| ENV | Standard | Beschreibung |
|---|---:|---|
| `XDEBUG_MODE` | `off` | z.B. `debug`, `develop`, `trace`, `coverage` (kommagetrennt). |
| `XDEBUG_START_WITH_REQUEST` | *(unset)* | `yes`/`no`. |
| `XDEBUG_CLIENT_HOST` | *(unset)* | Typischerweise `host.docker.internal` (macOS/Windows) oder Host-IP. |
| `XDEBUG_CLIENT_PORT` | `9003` | Client Port. |
| `XDEBUG_IDEKEY` | *(unset)* | IDE Key. |
| `XDEBUG_LOG_LEVEL` | `0` | 0–10 (Verbose). |

> Xdebug ist installiert und aktiviert; Verhalten wird über obige ENV-Variablen gesteuert. Wenn `XDEBUG_MODE=off`, lädt Xdebug, bleibt aber inaktiv.

---

## Verwendung

### Build (einzelne Version)
```bash
docker build -t lane4app/phpcli:8.3   --build-arg PHP_VERSION=8.3   --build-arg ALPINE_VERSION=3.20   --build-arg APCU_VERSION=5.1.27   --build-arg REDIS_VERSION=6.2.0   --build-arg XDEBUG_VERSION=3.4.5   ./src
```

### Run
```bash
# PHP Info anzeigen
docker run --rm lane4app/phpcli:8.3 php -i | less

# Runtime-PHP-Einstellungen überschreiben
docker run --rm -e PHP_MEMORY_LIMIT=1G -e PHP_TIMEZONE=Europe/Berlin lane4app/phpcli:8.3 php -r 'echo ini_get("memory_limit"),"\n",ini_get("date.timezone"),"\n";'

# Xdebug bei Bedarf aktivieren
docker run --rm -e XDEBUG_MODE=debug -e XDEBUG_START_WITH_REQUEST=yes   -e XDEBUG_CLIENT_HOST=host.docker.internal -e XDEBUG_CLIENT_PORT=9003   lane4app/phpcli:8.3 php dein-script.php
```

### Hinweise zur Größe
- Runtime-Stage enthält nur, was zum **Ausführen** deiner App und **Composer** benötigt wird.
- Build-Toolchain existiert nur im Build-Stage.
- `mysql-client`) ist standardmäßig nicht installiert

---

## Healthcheck

Das Image enthält einen Healthcheck, der PHP und Composer validiert:
```
php --version >/dev/null && composer --version >/dev/null
```

---

## Makefile Targets (optional)

Wenn du unser `support/docker.mk` nutzt, erhältst du Helfer für lokale und Remote-Multi-Arch-Builds, Cache-Backends und Tests. Siehe Kommentare in dieser Datei für Beispiele:

- `make build` – baut den Compose-Service lokal
- `make build-all` – baut alle PHP-Versionen lokal (native Arch)
- `make build-test-images` – baut amd64/arm64 Test-Tags lokal (mit optionalem Caching)
- `make build-remote-all` – pusht Multi-Arch-Tags für alle PHP-Versionen
- `make test-all` – führt OPcache/JIT und Extension-Checks auf beiden Architekturen aus

---

## Lizenz

MIT © Lane4 Digital GmbH
