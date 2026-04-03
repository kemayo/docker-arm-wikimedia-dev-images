#!/bin/bash

# When running as a non-root user (e.g. via docker-compose user:), bypass
# apache2ctl entirely — it unconditionally shell-chowns the run directory, but
# the shell chown command doesn't understand Apache's #UID numeric user syntax.
# Instead: source envvars ourselves, override the run user/group, create the run
# directory, then exec apache2 directly.
if [ "$(id -u)" != "0" ]; then
    . /etc/apache2/envvars
    export APACHE_RUN_USER="#$(id -u)"
    export APACHE_RUN_GROUP="#$(id -g)"
    mkdir -p "$APACHE_RUN_DIR"
    exec /usr/sbin/apache2 -D FOREGROUND
fi

exec /usr/sbin/apache2ctl -D FOREGROUND
