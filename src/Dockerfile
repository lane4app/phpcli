# Lane4 Digital PHP CLI – Multi-Stage
ARG ALPINE_VERSION=3.20

ARG APCU_VERSION=5.1.27
ARG REDIS_VERSION=6.2.0
ARG XDEBUG_VERSION=3.4.5

ARG INSTALL_MYSQL_CLIENT=false

ARG PHP_VERSION=8.3
ARG PHP_MEMORY_LIMIT=512M
ARG PHP_MAX_EXECUTION_TIME=0
ARG PHP_TIMEZONE=UTC
ARG APCU_SHM_SIZE=64M
ARG OPCACHE_MEMORY_CONSUMPTION=128
ARG OPCACHE_MAX_ACCELERATED_FILES=4000
ARG OPCACHE_REVALIDATE_FREQ=2
ARG PHP_ERROR_REPORTING="E_ALL & ~E_DEPRECATED & ~E_STRICT"
ARG PHP_DISPLAY_ERRORS=Off
ARG PHP_LOG_ERRORS=On

# --------------------
# Build stage
# --------------------
FROM php:${PHP_VERSION}-cli-alpine${ALPINE_VERSION} AS build
LABEL maintainer="Rolf Beab <rolf@lane4.digital>"

ARG APCU_VERSION
ARG REDIS_VERSION
ARG XDEBUG_VERSION

RUN apk add --no-cache \
      autoconf make g++ gcc libc-dev linux-headers libzip-dev libxml2-dev oniguruma-dev icu-dev curl-dev \
      libjpeg-turbo-dev libpng-dev freetype-dev pcre2-dev re2c pkgconf flex bison libxslt-dev python3 perl gperf \
      gawk sed grep findutils coreutils \
 && export LC_ALL=C \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" curl soap zip mbstring intl bcmath gd sockets exif pcntl pdo_mysql mysqli \
 && docker-php-ext-install -j1 dom \
 && pecl channel-update pecl.php.net \
 && pecl config-set preferred_state stable \
 && yes "" | pecl install -o -f \
      apcu-${APCU_VERSION} \
      redis-${REDIS_VERSION} \
      xdebug-${XDEBUG_VERSION} \
 && docker-php-ext-enable apcu redis xdebug \
 && docker-php-ext-enable opcache

# --------------------
# Runtime stage
# --------------------
FROM php:${PHP_VERSION}-cli-alpine${ALPINE_VERSION}
LABEL maintainer="Rolf Beab <rolf@lane4.digital>"

# dieselben ARGs im Stage sichtbar machen
ARG INSTALL_MYSQL_CLIENT
ARG PHP_MEMORY_LIMIT
ARG PHP_MAX_EXECUTION_TIME
ARG PHP_TIMEZONE
ARG APCU_SHM_SIZE
ARG OPCACHE_MEMORY_CONSUMPTION
ARG OPCACHE_MAX_ACCELERATED_FILES
ARG OPCACHE_REVALIDATE_FREQ
ARG PHP_ERROR_REPORTING
ARG PHP_DISPLAY_ERRORS
ARG PHP_LOG_ERRORS

ENV PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT} \
    PHP_MAX_EXECUTION_TIME=${PHP_MAX_EXECUTION_TIME} \
    PHP_TIMEZONE=${PHP_TIMEZONE} \
    APCU_SHM_SIZE=${APCU_SHM_SIZE} \
    OPCACHE_MEMORY_CONSUMPTION=${OPCACHE_MEMORY_CONSUMPTION} \
    OPCACHE_MAX_ACCELERATED_FILES=${OPCACHE_MAX_ACCELERATED_FILES} \
    OPCACHE_REVALIDATE_FREQ=${OPCACHE_REVALIDATE_FREQ} \
    PHP_ERROR_REPORTING=${PHP_ERROR_REPORTING} \
    PHP_DISPLAY_ERRORS=${PHP_DISPLAY_ERRORS} \
    PHP_LOG_ERRORS=${PHP_LOG_ERRORS}

# Runtime-Libs (MySQL-Client optional)
RUN set -eux; \
    PKGS="bash git unzip icu-libs libzip libxml2 oniguruma libjpeg-turbo libpng freetype"; \
    if [ "${INSTALL_MYSQL_CLIENT}" = "true" ]; then \
      PKGS="$PKGS mysql-client"; \
    fi; \
    apk add --no-cache $PKGS && \
    cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Gebaute Extensions & INIs übernehmen
COPY --from=build /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=build /usr/local/etc/php/conf.d/   /usr/local/etc/php/conf.d/

# OPcache-Ini früh laden (falls vorhanden)
RUN if [ -f /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini ]; then \
      mv /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini /usr/local/etc/php/conf.d/00-opcache.ini; \
    fi

# Konfiguration & Entrypoint
COPY xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Non-root user & runtime-config symlink
RUN addgroup -g 1001 appgroup \
 && adduser -G appgroup -u 1001 -D -s /bin/bash appuser \
 && mkdir -p /app /home/appuser/php-config \
 && chown -R appuser:appgroup /app /home/appuser \
 && : > /home/appuser/php-config/99-runtime-config.ini \
 && chown appuser:appgroup /home/appuser/php-config/99-runtime-config.ini \
 && ln -sf /home/appuser/php-config/99-runtime-config.ini /usr/local/etc/php/conf.d/99-runtime-config.ini

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD sh -c "php --version >/dev/null && composer --version >/dev/null"

USER appuser
WORKDIR /app
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php","--version"]
