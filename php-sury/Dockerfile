FROM docker-registry.wikimedia.org/bookworm:latest

# Adapted from https://packages.sury.org/php/README.txt
COPY ../files/mediawiki-php-sury/debsuryorg-archive-keyring.deb /tmp/
RUN dpkg -i /tmp/debsuryorg-archive-keyring.deb \
    && rm /tmp/debsuryorg-archive-keyring.deb \
    && echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ bookworm main" \
       > /etc/apt/sources.list.d/php.list
