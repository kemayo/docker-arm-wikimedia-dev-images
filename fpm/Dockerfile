FROM docker-registry.wikimedia.org/dev/bookworm-php83:1.0.0

ENV XDEBUG_MODE=off

# We don't want the default index.html for running PHP applications, and
# xdebug is a major performance drag, so disable it here (it's already
# been disabled for CLI PHP in bullseye-php81).

RUN apt-get update && apt-get install -yq php8.3-fpm php-pear \
    && rm -rf /var/lib/apt/lists/*

# php-fpm configuration:
COPY ../files/mediawiki-fpm/docker/20-xdebug.ini /docker/20-xdebug.ini
COPY ../files/mediawiki-fpm/php-fpm.conf /etc/php/8.3/fpm/php-fpm.conf
RUN cp /docker/www.conf /etc/php/8.3/fpm/pool.d/www.conf

# MediaWiki-specific php.ini settings
# upload_max_filesize and post_max_size here match production, per T246930
RUN echo 'opcache.file_update_protection=0\n\
opcache.memory_consumption=256\n\
opcache.max_accelerated_files=24000\n\
opcache.max_wasted_percentage=10\n\
opcache.fast_shutdown=1\n\
zlib.output_compression=On\n\
upload_max_filesize=100M\n\
post_max_size=100M\n\
extension=ast.so\n' | tee -a /etc/php/8.3/fpm/php.ini /etc/php/8.3/cli/php.ini

# Install PECL extensions: ast (for phan), xdebug, xhprof
RUN (test -f "/etc/php/8.3/fpm/conf.d/20-xdebug.ini" && rm "/etc/php/8.3/fpm/conf.d/20-xdebug.ini" || true) \
    && pecl install ast \
    && pecl install xdebug-3.4.5 \
    && curl "https://github.com/tideways/php-xhprof-extension/archive/v5.0.4.tar.gz" -fsL -o ./xhprof.tar.gz \
    && tar xf ./xhprof.tar.gz \
    && cd ./php-xhprof-extension-5.0.4 \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && cd .. && rm -rf ./xhprof.tar.gz ./php-xhprof-extension-5.0.4 \
    && ln -s /docker/20-xdebug.ini "/etc/php/$PHP_VERSION/fpm/conf.d/20-xdebug.ini" \
    && ln -s /docker/20-xdebug.ini "/etc/php/$PHP_VERSION/cli/conf.d/20-xdebug.ini"

EXPOSE 9000
EXPOSE 9003

WORKDIR "/var/www/html/w"

ENTRYPOINT ["/bin/bash", "/php_entrypoint.sh"]
