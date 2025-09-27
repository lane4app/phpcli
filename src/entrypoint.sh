#!/bin/bash
set -e

# =============================================================================
# Lane4 Digital PHP CLI - Runtime Configuration Script
# Generates PHP configuration based on environment variables at container startup
# =============================================================================

# Ensure the user config directory exists
mkdir -p /home/appuser/php-config

# Generate dynamic PHP configuration based on environment variables
cat > /home/appuser/php-config/99-runtime-config.ini << PHPINI
; =============================================================================
; Lane4 Digital PHP CLI Runtime Configuration
; Generated at container startup from environment variables
; Override any setting by setting the corresponding ENV variable
; =============================================================================

; Memory settings
memory_limit = ${PHP_MEMORY_LIMIT}
max_execution_time = ${PHP_MAX_EXECUTION_TIME}

; Date settings
date.timezone = ${PHP_TIMEZONE}

; Error handling
error_reporting = ${PHP_ERROR_REPORTING}
display_errors = ${PHP_DISPLAY_ERRORS}
log_errors = ${PHP_LOG_ERRORS}

; APCu configuration
apc.enabled = 1
apc.shm_size = ${APCU_SHM_SIZE}
apc.enable_cli = 1
apc.serializer = php

; OPcache configuration (enabled for both AMD64 and ARM64, JIT disabled)
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = ${OPCACHE_MEMORY_CONSUMPTION}
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = ${OPCACHE_MAX_ACCELERATED_FILES}
opcache.revalidate_freq = ${OPCACHE_REVALIDATE_FREQ}
opcache.fast_shutdown = 1

; JIT disabled for multi-platform compatibility and stability
opcache.jit = off
opcache.jit_buffer_size = 0

; Security settings
expose_php = Off
PHPINI

# Execute the original command
exec "$@"
