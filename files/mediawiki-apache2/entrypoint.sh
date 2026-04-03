#!/bin/bash

# When the container runs as a non-root user (e.g. via docker-compose user:),
# Apache cannot chown socket files to www-data. Set the run user/group to
# match the actual process identity so no chown is attempted.
# If running as root, leave the defaults so Apache drops privileges to www-data normally.
if [ "$(id -u)" != "0" ]; then
    export APACHE_RUN_USER="#$(id -u)"
    export APACHE_RUN_GROUP="#$(id -g)"
fi

/usr/sbin/apache2ctl -D FOREGROUND
