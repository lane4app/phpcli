# ---------------------------------------------------------------------------
# Tests (Multi-Arch: amd64 & arm64)
# Erwartete Tags: $(PHP_IMAGE_NAME):amd64-test und :arm64-test
# ---------------------------------------------------------------------------
##@ Test

PHP_EXTENSIONS := apcu redis gd intl mbstring pcntl bcmath soap exif sockets dom zip mysqli curl pdo_mysql

test-opcache: build-test-images ## OPcache geladen + aktiv (enable & enable_cli) und JIT deaktiviert (0) auf beiden Archs
	@set -e; \
	for arch in amd64 arm64; do \
	  echo ">>> Prüfen: OPcache & JIT auf $$arch"; \
	  docker run --rm --platform=linux/$$arch $(PHP_IMAGE_NAME):$$arch-test php -r "\
if (!(extension_loaded('Zend OPcache') || extension_loaded('opcache'))) {fwrite(STDERR,'OPcache nicht geladen'); exit(1);} \
if (ini_get('opcache.enable')!=='1')     {fwrite(STDERR,'opcache.enable != '.ini_get('opcache.enable')); exit(1);} \
if (ini_get('opcache.enable_cli')!=='1') {fwrite(STDERR,'opcache.enable_cli != '.ini_get('opcache.enable_cli')); exit(1);} \
if (!in_array(strtolower((string)ini_get('opcache.jit')), ['', '0','off','disable','disabled'], true)) {fwrite(STDERR,'opcache.jit != '.ini_get('opcache.jit')); exit(1);} \
"; \
	  echo "✅ OPcache aktiv & JIT deaktiviert auf $$arch"; \
	done
.PHONY: test-opcache

test-extensions: build-test-images ## Alle gewünschten Erweiterungen geladen auf beiden Archs
	@set -e; \
	for arch in amd64 arm64; do \
	  echo ">>> Prüfen: PHP-Erweiterungen auf $$arch"; \
	  for ext in $(PHP_EXTENSIONS); do \
	    docker run --rm --platform=linux/$$arch $(PHP_IMAGE_NAME):$$arch-test php -r "\
if (!extension_loaded('$$ext')) {fwrite(STDERR,'Fehlt: $$ext'); exit(1);} \
"; \
	  done; \
	  echo "✅ Alle Extensions geladen auf $$arch"; \
	done
.PHONY: test-extensions

## Kombi
test-all: test-opcache test-extensions ## Alle Tests
	@echo "✅ Alle Tests für AMD64 und ARM64 bestanden!"
.PHONY: test-all
