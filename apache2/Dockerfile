FROM docker-registry.wikimedia.org/bookworm:latest

RUN apt-get update && apt-get install -yq apache2 \
    && rm /var/www/html/index.html \
    && a2enmod proxy_fcgi \
    && a2enmod mpm_event \
    && a2enmod rewrite \
    && a2enmod http2 \
    && a2enmod cache \
    && rm -rf /var/lib/apt/lists/*

# Apache configuration:
COPY ../files/mediawiki-apache2/ports.conf /etc/apache2/ports.conf
COPY ../files/mediawiki-apache2/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ../files/mediawiki-apache2/apache2.conf /etc/apache2/apache2.conf
COPY ../files/mediawiki-apache2/envvars /etc/apache2/envvars

EXPOSE 8080
# EXPOSE 443

WORKDIR "/var/www/html/w"

COPY ../files/mediawiki-apache2/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
