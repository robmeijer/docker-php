ARG PHP_VERSION=7.4

FROM php:${PHP_VERSION}-fpm-alpine AS php-fpm

CMD ["php-fpm"]
