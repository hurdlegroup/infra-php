ARG PHP_VERSION=8.2
ARG DEBIAN_RELEASE=bullseye

FROM php:${PHP_VERSION}-fpm-${DEBIAN_RELEASE}

RUN apt-get update && apt-get install -y --force-yes --no-install-recommends \
    libmemcached-dev \
    libmcrypt-dev \
    libreadline-dev \
    libgmp-dev \
    libzip-dev \
    libz-dev \
    libpq-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libssl-dev \
    libonig-dev\
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libbz2-dev \
    libxml2-dev \
    libevent-dev \
    libev-dev \
    software-properties-common \
    locales \
    gnupg \
    cron \
    procps \
    apt-transport-https \
    unixodbc \
    unixodbc-dev \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && apt-add-repository https://packages.microsoft.com/debian/$(cat /etc/debian_version | cut -d. -f1)/prod \
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
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
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
    apfd

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
