FROM docker-registry.wikimedia.org/dev/bookworm-php85:1.0.0-arm1

ENV XDEBUG_MODE=off

# We don't want the default index.html for running PHP applications, and
# xdebug is a major performance drag, so disable it here (it's already
# been disabled for CLI PHP in bookworm-php85).

RUN apt-get update && apt-get install -yq php8.5-fpm \
    && rm -rf /var/lib/apt/lists/*

# php-fpm configuration:
COPY ../files/mediawiki-fpm/php-fpm.conf /etc/php/8.5/fpm/php-fpm.conf
RUN cp /docker/www.conf /etc/php/8.5/fpm/pool.d/www.conf

# MediaWiki-specific php.ini settings
# upload_max_filesize and post_max_size here match production, per T246930
RUN echo 'opcache.file_update_protection=0\n\
opcache.memory_consumption=256\n\
opcache.max_accelerated_files=24000\n\
opcache.max_wasted_percentage=10\n\
zlib.output_compression=On\n\
upload_max_filesize=100M\n\
post_max_size=100M\n' | tee -a /etc/php/8.5/fpm/php.ini /etc/php/8.5/cli/php.ini

RUN cp --force /docker/xdebug.ini "/etc/php/$PHP_VERSION/fpm/conf.d/20-xdebug.ini"

EXPOSE 9000
EXPOSE 9003

WORKDIR "/var/www/html/w"

ENTRYPOINT ["/bin/bash", "/php_entrypoint.sh"]
