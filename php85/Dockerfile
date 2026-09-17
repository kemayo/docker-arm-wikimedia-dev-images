FROM docker-registry.wikimedia.org/dev/bookworm-php-sury:1.0.1-s4-arm1

ENV PHP_VERSION=8.5

# The upstream image takes PHP from the Wikimedia APT repository and keeps
# Sury at a low priority for php-ast only. The Wikimedia repository has no
# arm64 packages, so this image takes all of PHP from Sury.

# Not installing php-tidy here - see https://phabricator.wikimedia.org/T191771
RUN apt-get update && apt-get install -yq \
    php8.5 \
    php8.5-apcu \
    php8.5-ast \
    php8.5-bcmath \
    php8.5-cli \
    php8.5-curl \
    php8.5-excimer \
    php8.5-gd \
    php8.5-gmp \
    php8.5-intl \
    php8.5-mbstring \
    php8.5-sqlite3 \
    php8.5-xml \
    php8.5-zip \
    php8.5-redis \
    php8.5-dev \
    php8.5-ldap \
    php8.5-mysql \
    php8.5-pgsql \
    php8.5-xdebug \
    php8.5-xhprof \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --set php /usr/bin/php8.5

RUN cp -f /docker/xdebug.ini "/etc/php/$PHP_VERSION/cli/conf.d/20-xdebug.ini"

# Local addition: PHP tools for use inside the container.
RUN composer global require \
    "friendsofphp/php-cs-fixer" \
    "squizlabs/php_codesniffer" \
    "phpstan/phpstan" \
    "phpmd/phpmd" \
    "vimeo/psalm"
ENV PATH="/root/.composer/vendor/bin:$PATH"
