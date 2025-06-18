#!/bin/bash
set -e

# Start PHP-FPM in background
/usr/local/php/sbin/php-fpm --nodaemonize --fpm-config /usr/local/php/etc/php-fpm.conf &

# Wait for PHP-FPM socket to be ready
timeout=15
while [ ! -S /run/php-fpm/php-fpm.sock ]; do
    sleep 1
    timeout=$((timeout-1))
    if [ $timeout -le 0 ]; then
        echo "ERROR: PHP-FPM socket not found after 15 seconds"
        exit 1
    fi
done

# Set proper permissions on the socket
chown www-data:www-data /run/php-fpm/php-fpm.sock
chmod 660 /run/php-fpm/php-fpm.sock

# Start Nginx in foreground
exec nginx -g 'daemon off;'