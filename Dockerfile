ARG PHP_VERSION=8.3
ARG DEBIAN_RELEASE=trixie

FROM php:${PHP_VERSION}-fpm-${DEBIAN_RELEASE}

RUN apt-get update && apt-get install -y --no-install-recommends \
    libmemcached-dev \
    libmcrypt-dev \
    libreadline-dev \
    libgmp-dev \
    libzip-dev \
    libz-dev \
    libpq-dev \
    libjpeg-dev \
    libwebp-dev \
    libpng-dev \
    libfreetype6-dev \
    libssl-dev \
    libonig-dev\
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libbz2-dev \
    libxml2-dev \
    libicu-dev \
    libevent-dev \
    libev-dev \
    locales \
    gnupg \
    ca-certificates \
    cron \
    procps \
    unixodbc \
    unixodbc-dev \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && MS_DEBIAN_VERSION="$(. /etc/os-release && echo "$VERSION_ID")" \
    && if ! curl -fsSL "https://packages.microsoft.com/config/debian/${MS_DEBIAN_VERSION}/packages-microsoft-prod.deb" -o /tmp/packages-microsoft-prod.deb; then \
        echo "Microsoft repo for Debian ${MS_DEBIAN_VERSION} unavailable, falling back to Debian 12"; \
        curl -fsSL "https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb" -o /tmp/packages-microsoft-prod.deb; \
      fi \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && rm -f /tmp/packages-microsoft-prod.deb \
    && apt-get update && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
    msodbcsql18 mssql-tools18 unixodbc-dev \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/*

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Install additional extensions
RUN docker-php-ext-install \
    exif \
    pcntl \
    intl \
    gmp \
    bcmath \
    opcache \
    sockets \
    pdo_mysql \
    pdo_pgsql \
    && docker-php-ext-configure gd --with-freetype --with-webp --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Install required dependencies
RUN pecl install \
#    sqlsrv pdo_sqlsrv \
    igbinary msgpack \
    zip \
    redis \
    memcached \
    # Install event extensions
    event ev \
    # Install the php apfd extension to allow multi-part/form-data on PUT/PATCH
    apfd \
    && docker-php-ext-enable \
    intl \
    gmp \
    bcmath \
    opcache \
    pdo_mysql \
    pdo_pgsql \
#    sqlsrv pdo_sqlsrv \
    igbinary msgpack \
    zip \
    redis \
    memcached \
    event ev \
    apfd \
    # Hacky workaround to make sure event loads after sockets to avoid socket_ce error (Sockets needs to be loaded first)
    && mv /usr/local/etc/php/conf.d/docker-php-ext-event.ini /usr/local/etc/php/conf.d/docker-php-ext-z-event.ini

# Install composer and add its bin to the PATH.
RUN curl -s http://getcomposer.org/installer | php \
    && echo "export PATH=${PATH}:/var/www/vendor/bin" >> ~/.bashrc \
    && mv composer.phar /usr/local/bin/composer \
    && . ~/.bashrc

#
#--------------------------------------------------------------------------
# Final Touch
#--------------------------------------------------------------------------
#

ADD ./php-conf.d/* "$PHP_INI_DIR/conf.d/"

# Clear out the local repository of retrieved package files
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN usermod -u 1000 www-data

# Set working directory
WORKDIR /var/www

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]
