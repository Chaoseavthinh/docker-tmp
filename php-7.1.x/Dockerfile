# Use a custom Red Hat UBI base image from an internal registry
FROM --platform=linux/amd64 redhat/ubi8

# Define build arguments
ARG USERNAME=www-data
ARG USER_UID=1001

# Install system packages
RUN microdnf install dnf -y && \
    dnf remove -y php-* && \
    dnf clean all

# Install build dependencies
RUN dnf install -y \
    postgresql-devel \
    dnf-utils \
    gcc \
    make \
    autoconf \
    curl \
    nginx \
    libxml2-devel \
    zlib-devel \
    bzip2-devel \
    libcurl-devel \
    libjpeg-turbo-devel \
    libpng-devel \
    freetype-devel \
    libzip-devel \
    openssl-devel \
    tar \
    tzdata \
    libwebp-devel \
    libicu-devel \
    libxslt-devel \
    libedit-devel \
    libffi-devel \
    which && \
    dnf clean all

# Set timezone
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Copy and build PHP from source
COPY php-7.1.33.tar.gz /
RUN mkdir -p /usr/src/php && \
    tar -xzf /php-7.1.33.tar.gz -C /usr/src/php --strip-components=1 && \
    cd /usr/src/php && \
    ./configure \
    --prefix=/usr/local/php \
    --with-curl \
    --with-zlib \
    --enable-mbstring \
    --with-openssl \
    --with-gd \
    --with-jpeg-dir=/usr \
    --with-png-dir=/usr \
    --with-freetype-dir=/usr \
    --enable-zip \
    --with-libzip \
    --enable-fpm \
    --with-pdo-mysql \
    --with-pdo-pgsql \
    --with-pdo-pgsql=/usr/pgsql-13 \ 
    --with-pgsql=/usr/pgsql-13 \
    --with-fpm-user=${USERNAME} \
    --with-fpm-group=${USERNAME} && \
    make -j"$(nproc)" && \
    make install

# Create PHP symlinks
RUN ln -s /usr/local/php/bin/php /usr/local/bin/php && \
    ln -s /usr/local/php/sbin/php-fpm /usr/local/sbin/php-fpm && \
    ln -s /usr/local/php/bin/php-config /usr/local/bin/php-config && \
    ln -s /usr/local/php/bin/phpize /usr/local/bin/phpize

ENV PATH="/usr/local/php/bin:/usr/local/php/sbin:${PATH}"

# Create application user
RUN id -u "$USERNAME" &>/dev/null || useradd -u "$USER_UID" -ms /bin/bash "$USERNAME"

# Set up Laravel directory structure
RUN mkdir -p /var/www/html && \
    mkdir -p /var/www/html/storage/{app,framework,logs} && \
    mkdir -p /var/www/html/storage/framework/{cache,sessions,views} && \
    mkdir -p /var/www/html/bootstrap/cache && \
    chown -R ${USERNAME}:${USERNAME} /var/www/html && \
    chmod -R 775 /var/www/html/storage && \
    chmod -R 775 /var/www/html/bootstrap/cache

# Configure PHP-FPM logging
RUN mkdir -p /usr/local/php/var/log && \
    touch /usr/local/php/var/log/php-fpm.log && \
    chown -R ${USERNAME}:${USERNAME} /usr/local/php/var/log && \
    chmod 755 /usr/local/php/var && \
    chmod 664 /usr/local/php/var/log/php-fpm.log

# Configure PHP and PHP-FPM
RUN cp /usr/src/php/php.ini-production /usr/local/php/lib/php.ini && \
    mkdir -p /usr/local/php/etc/php-fpm.d && \
    cp /usr/src/php/sapi/fpm/php-fpm.conf /usr/local/php/etc/ && \
    cp /usr/src/php/sapi/fpm/www.conf /usr/local/php/etc/php-fpm.d/

# Configure PHP-FPM pool settings
RUN sed -i \
    -e "s/^user =.*/user = ${USERNAME}/" \
    -e "s/^group =.*/group = ${USERNAME}/" \
    -e "s/^listen =.*/listen = \/run\/php-fpm\/php-fpm.sock/" \
    -e "s/^;listen.owner =.*/listen.owner = ${USERNAME}/" \
    -e "s/^;listen.group =.*/listen.group = ${USERNAME}/" \
    -e "s/^;listen.mode =.*/listen.mode = 0660/" \
    -e "s|^;error_log =.*|error_log = /usr/local/php/var/log/php-fpm.log|" \
    /usr/local/php/etc/php-fpm.d/www.conf

# Set up runtime directories
RUN mkdir -p \
    /run/php-fpm \
    /data/log/nginx \
    /var/lib/nginx/tmp/client_body \
    /var/log/nginx \
    /var/log/php-fpm \
    /run/nginx && \
    touch \
    /data/log/nginx/laravel-access.log \
    /var/log/php-fpm/error.log \
    /run/nginx.pid && \
    chown -R ${USERNAME}:${USERNAME} \
    /run/php-fpm \
    /data/log/nginx \
    /var/log/nginx \
    /var/lib/nginx \
    /var/log/php-fpm \
    /run/nginx && \
    chmod 755 /run/php-fpm && \
    chmod 644 /data/log/nginx/laravel-access.log && \
    chmod 664 /var/log/php-fpm/error.log

# Set PID file ownership
RUN chown ${USERNAME}:${USERNAME} /run/nginx.pid

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY --chown=${USERNAME}:${USERNAME} . /var/www/html/

# Install Composer dependencies
COPY composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer && \
    composer install --no-dev --optimize-autoloader

# Set up entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Verify PHP extensions
RUN /usr/local/php/bin/php -m | grep -E 'zip|mbstring|openssl|gd' || \
    (echo "Required extensions not loaded!" && exit 1)

# Switch to non-root user
USER "$USERNAME"

# Expose ports
EXPOSE 8080 9000

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]