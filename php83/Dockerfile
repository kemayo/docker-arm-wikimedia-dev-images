FROM docker-registry.wikimedia.org/bookworm:latest

ENV PHP_VERSION=8.3

# Note that WMF APT key is pre-installed.
# See: https://wikitech.wikimedia.org/wiki/APT_repository#Security

# Does not have arm images using 3rd party instead
#RUN echo "deb https://apt.wikimedia.org/wikimedia bookworm-wikimedia component/php83" \
#   > /etc/apt/sources.list.d/wikimedia-php83.list

RUN apt-get update && apt-get install -yq curl \
    wget \
    gnupg2 \
    ca-certificates \
    lsb-release \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*


RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://packages.sury.org/php/apt.gpg -o /etc/apt/keyrings/sury-php.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" \
       > /etc/apt/sources.list.d/php8.list

# Install PHP dependencies:
RUN apt-get update && apt-get install -yq php8.3 \
    php8.3-cli \
    php8.3-common \
    php8.3-apcu \
    php8.3-bcmath \
    php8.3-curl \
    php8.3-dba \
    php8.3-gd \
    php8.3-gmp \
    php8.3-intl \
    php8.3-ldap \
    php8.3-mbstring \
    php8.3-mysql \
    php8.3-pgsql \
    php8.3-sqlite3 \
    php8.3-xml \
    php8.3-zip \
    php8.3-redis \
    php8.3-dev \
    sed \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --set php /usr/bin/php8.3

# install composer
# see "command-line installation" https://getcomposer.org/download/
RUN curl -fsSL https://getcomposer.org/installer -o composer-setup.php \
    && php -r "if (hash_file('sha384', 'composer-setup.php') !== trim(file_get_contents('https://composer.github.io/installer.sig'))) { echo 'Installer corrupt'; exit(1); }" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php

# Install PHP tools globally
## Linters and Code Chekers
RUN composer global require "friendsofphp/php-cs-fixer"
RUN composer global require "squizlabs/php_codesniffer"

## Extra tools
### Static Code analyzers : finds bugs in PHP code
RUN composer global require "phpstan/phpstan"
RUN composer global require "phpmd/phpmd"
RUN composer global require "vimeo/psalm"
ENV PATH="/root/.composer/vendor/bin:$PATH"
