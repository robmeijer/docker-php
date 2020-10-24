# The PHP version that will be built by default
ARG PHP_VERSION=7.4

# Base image
FROM php:${PHP_VERSION}-fpm-alpine

# Optionally rebuild OpCache on file changes
ENV OPCACHE_VALIDATE_TIMESTAMPS=0

# Enable APCU caching
ARG APCU_VERSION=5.1.19

# Optionally include MongoDB support
ARG WITH_MONGODB=false

# Install dependencies
RUN set -eux; \
    apk --update add --no-cache --virtual .build-deps \
        gmp-dev \
        icu-dev \
        libressl-dev \
        libxml2-dev \
        libzip-dev \
        zlib-dev \
        ${PHPIZE_DEPS} \
    ; \
    docker-php-ext-configure zip; \
    docker-php-ext-install \
        gmp \
        intl \
        pcntl \
        pdo_mysql \
        zip \
    ; \
    pecl install \
        apcu-${APCU_VERSION} \
    ; \
    if [ ${WITH_MONGODB} = true ]; then \
        pecl -q install mongodb; \
        docker-php-ext-enable mongodb; \
    fi; \
    pecl clear-cache; \
    docker-php-ext-enable \
        apcu \
        opcache \
    ; \
    RUNDEPS="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-cache --virtual .run-deps ${RUNDEPS}; \
    apk del .build-deps;

# Use the default production configuration
RUN ln -s ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini

# Copy default settings
COPY conf.d/robmeijer.ini ${PHP_INI_DIR}/conf.d/robmeijer.ini
COPY php-fpm.d/robmeijer.conf ${PHP_INI_DIR}/../php-fpm.d/robmeijer.conf

CMD ["php-fpm"]
