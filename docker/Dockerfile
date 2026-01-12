FROM php:8.4-fpm-bookworm

# Install dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmagickwand-dev \
    libonig-dev \
    libpng-dev \
    libxslt1-dev \
    libzip-dev \
    git \
    unzip \
    libcurl4-openssl-dev \
    libedit-dev \
    libreadline-dev \
    libsnmp-dev \
    libxml2-dev \
    libsodium-dev \
    netcat-openbsd \
    curl \
    msmtp \
    && curl -L https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64 -o /usr/local/bin/mkcert \
    && chmod +x /usr/local/bin/mkcert \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        ctype \
        curl \
        dom \
        ftp \
        gd \
        gettext \
        intl \
        mbstring \
        mysqli \
        opcache \
        pdo_mysql \
        simplexml \
        soap \
        sockets \
        sodium \
        xsl \
        zip

# Install Imagick
# For PHP 8.4, we might need a specific version or install from source if PECL package isn't updated yet.
# However, standard practice is to try pecl first.
RUN pecl install imagick && docker-php-ext-enable imagick

# Install Redis extension (works with Valkey)
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:2.9 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# PHP configuration
RUN echo "memory_limit=2G" > /usr/local/etc/php/conf.d/magento.ini \
    && echo "max_execution_time=3600" >> /usr/local/etc/php/conf.d/magento.ini \
    && echo "zlib.output_compression=On" >> /usr/local/etc/php/conf.d/magento.ini \
    && echo "upload_max_filesize=100M" >> /usr/local/etc/php/conf.d/magento.ini \
    && echo "post_max_size=100M" >> /usr/local/etc/php/conf.d/magento.ini

# Configure msmtp
RUN echo "account default" > /etc/msmtprc \
    && echo "host mailpit" >> /etc/msmtprc \
    && echo "port 1025" >> /etc/msmtprc \
    && echo "from magento@magento.test" >> /etc/msmtprc \
    && echo "sendmail_path = /usr/bin/msmtp -t" > /usr/local/etc/php/conf.d/mail.ini \
    && ln -s /usr/bin/msmtp /usr/sbin/sendmail

# Fix permissions and create Composer directories
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN if [ ${USER_ID} -ne 33 ]; then usermod -u ${USER_ID} www-data; fi && \
    if [ ${GROUP_ID} -ne 33 ]; then \
        if getent group ${GROUP_ID}; then \
            group_name=$(getent group ${GROUP_ID} | cut -d: -f1); \
            usermod -g ${group_name} www-data; \
        else \
            groupmod -g ${GROUP_ID} www-data; \
        fi; \
    fi && \
    mkdir -p /var/www/.composer /var/www/.cache /var/www/.config && \
    chown -R www-data:www-data /var/www

USER www-data
