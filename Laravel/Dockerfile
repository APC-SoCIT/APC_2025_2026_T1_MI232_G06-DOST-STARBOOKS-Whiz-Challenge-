# ============================================
# Stage 1: Install Composer Dependencies
# ============================================
FROM php:8.3-cli AS vendor

RUN apt-get update && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pecl install mongodb \
    && docker-php-ext-enable mongodb

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY composer.json composer.lock ./

RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --prefer-dist

COPY . .

RUN composer dump-autoload --optimize --classmap-authoritative

# ============================================
# Stage 2: Production Runtime
# ============================================
FROM php:8.3-fpm

RUN apt-get update && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pecl install mongodb \
    && docker-php-ext-enable mongodb

WORKDIR /var/www

COPY --from=vendor /app/vendor ./vendor
COPY . .

RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/bootstrap/cache

EXPOSE 9000

COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]