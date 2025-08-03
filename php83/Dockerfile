FROM docker-registry.wikimedia.org/bullseye:latest

ENV PHP_VERSION=8.3

# Note that WMF APT key is pre-installed.
# See: https://wikitech.wikimedia.org/wiki/APT_repository#Security

# Does not have arm images using 3rd party instead
#RUN echo "deb https://apt.wikimedia.org/wikimedia bullseye-wikimedia component/php83" \
#   > /etc/apt/sources.list.d/wikimedia-php83.list

RUN apt-get update && apt-get install -yq curl \
wget \
gnupg2 \
ca-certificates \
lsb-release \
apt-transport-https


RUN curl -s https://packages.sury.org/php/apt.gpg --output apt.gpg && APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add apt.gpg && rm apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php8.list

# Install PHP dependencies:
RUN apt-get update && apt-get install -yq php8.3 \
php8.3-cli \
php8.3-common \
php8.3-apcu \
php8.3-bcmath \
php8.3-cli \
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
php8.3-ldap \
php8.3-mysql \
php8.3-pgsql \
php8.3-dev \
sed \
build-essential

RUN update-alternatives --set php /usr/bin/php8.3

# install composer
# see "command-line installation" https://getcomposer.org/download/
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === file_get_contents('https://composer.github.io/installer.sig')) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"

RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN php -r "unlink('composer-setup.php');"

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
