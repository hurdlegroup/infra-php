ARG PHP_VERSION=7.4

FROM php:${PHP_VERSION}-fpm-buster

# Install PHP and composer dependencies
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
    libmagickwand-dev \
    libxml2-dev \
    software-properties-common \
    locales \
    gnupg \
    vim \
    git \
    cron \
    curl \
    apt-transport-https \
    unixodbc \
    unixodbc-dev \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && apt-add-repository https://packages.microsoft.com/debian/10/prod \
    && apt-get update && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
    msodbcsql17 \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/*

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Install for image manipulation
RUN docker-php-ext-install exif

# Install the PHP pcntl extention
RUN docker-php-ext-install pcntl

# Install the PHP intl extention
RUN docker-php-ext-install intl

# Install the PHP gmp extention
#RUN docker-php-ext-install gmp

# Install the PHP bcmath extension
#RUN docker-php-ext-install bcmath

# Install the PHP opcache extention
#RUN docker-php-ext-install opcache

# Install the PHP pdo_mysql extention
#RUN docker-php-ext-install pdo_mysql

# Install the PHP pdo_pgsql extention
#RUN docker-php-ext-install pdo_pgsql

# Install required dependencies
RUN pecl install \
#    gmp \
#    bcmath \
#    opcache \
#    pdo_mysql \
#    pdo_pgsql \
    sqlsrv pdo_sqlsrv \
    igbinary msgpack \
    zip \
    redis \
    imagick \
    memcached \
    # Install the php apfd extension to allow multi-part/form-data on PUT/PATCH
    apfd \
    && docker-php-ext-enable \
    intl \
    gmp \
    bcmath \
    opcache \
    pdo_mysql \
    pdo_pgsql \
    sqlsrv pdo_sqlsrv \
    igbinary msgpack \
    zip \
    redis \
    imagick \
    memcached \
    apfd

#####################################
# GD:
#####################################

# Install the PHP gd library
RUN docker-php-ext-install gd && \
    docker-php-ext-configure gd \
        --with-jpeg=/usr/lib \
        --with-freetype=/usr/include/freetype2 && \
    docker-php-ext-install gd

#####################################
# Lumen Schedule Cron Job:
#####################################

RUN echo "* * * * * root /usr/local/bin/php /var/www/artisan schedule:run >> /dev/null 2>&1"  >> /etc/cron.d/lumen-scheduler
RUN chmod 0644 /etc/cron.d/lumen-scheduler

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
