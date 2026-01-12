#!/bin/bash

set -e

# Wait for DB
until nc -z db 3306; do
  echo "Waiting for database..."
  sleep 2
done

# Wait for OpenSearch
until curl -s http://opensearch:9200 > /dev/null; do
  echo "Waiting for OpenSearch..."
  sleep 2
done

# Check if composer.json exists, if not, create project
if [ ! -f composer.json ] || [ ! -d vendor ]; then
    EDITION=${1:-enterprise}
    SAMPLEDATA=${2:-false}
    VERSION="2.4.8-p3"

    if [ ! -f composer.json ]; then
        if [ "$EDITION" == "enterprise" ]; then
            PACKAGE="magento/project-enterprise-edition=$VERSION"
            echo "Installing Adobe Commerce Enterprise Edition $VERSION..."
        else
            PACKAGE="magento/project-community-edition=$VERSION"
            echo "Installing Adobe Commerce Open Source $VERSION..."
        fi

        if [ ! -f auth.json ]; then
            echo "Error: auth.json not found. Please provide Adobe Commerce credentials in auth.json."
            exit 1
        fi

        # Ensure Composer home and cache directories exist and auth.json is in place
        export COMPOSER_HOME=/var/www/.composer
        export COMPOSER_CACHE_DIR=/var/www/.cache

        if [ ! -d "$COMPOSER_HOME" ]; then
            mkdir -p "$COMPOSER_HOME"
        fi

        if [ ! -d "$COMPOSER_CACHE_DIR" ]; then
            mkdir -p "$COMPOSER_CACHE_DIR"
        fi

        cp auth.json $COMPOSER_HOME/auth.json

        echo "Creating project in a temporary directory..."
        rm -rf tmp_project
        composer create-project --repository-url=https://repo.magento.com/ "$PACKAGE" tmp_project --no-install --no-scripts

        echo "Moving files to project root..."
        cp -rn tmp_project/. .
        rm -rf tmp_project
    fi

    echo "Running composer install..."
    composer install

    if [ "$SAMPLEDATA" == "true" ]; then
        echo "Deploying sample data..."
        php bin/magento sampledata:deploy
        echo "Updating dependencies with sample data..."
        composer update --no-interaction
    fi
fi

# Check if Magento is already installed
if [ ! -f app/etc/env.php ]; then
    echo "Magento not installed. Starting installation..."

    # You might want to pass these as env variables
    bin/magento setup:install \
        --base-url=https://magento.test/ \
        --db-host=db \
        --db-name=magento \
        --db-user=magento \
        --db-password=magento \
        --admin-firstname=Admin \
        --admin-lastname=User \
        --admin-email=admin@example.com \
        --admin-user=admin \
        --admin-password=password123 \
        --language=en_US \
        --currency=USD \
        --timezone=America/Chicago \
        --use-rewrites=1 \
        --search-engine=opensearch \
        --opensearch-host=opensearch \
        --opensearch-port=9200 \
        --opensearch-index-prefix=magento2 \
        --opensearch-timeout=15 \
        --session-save=redis \
        --session-save-redis-host=valkey \
        --session-save-redis-log-level=3 \
        --session-save-redis-db=2 \
        --cache-backend=redis \
        --cache-backend-redis-server=valkey \
        --cache-backend-redis-db=0 \
        --page-cache=redis \
        --page-cache-redis-server=valkey \
        --page-cache-redis-db=1 \
        --amqp-host=rabbitmq \
        --amqp-port=5672 \
        --amqp-user=guest \
        --amqp-password=guest
fi

echo "Magento is ready!"
