#!/bin/bash
set -e

ENV=$1
VERSION=$2

NGINX_ROOT=/var/www/html
BACKUP_DIR=/home/ubuntu/backup_$(date +%Y%m%d%H%M%S)
TMP_DIR=/home/ubuntu/deploy_tmp

echo "Backing up existing site..."
if [ -d "$NGINX_ROOT" ]; then
  sudo cp -r "$NGINX_ROOT" "$BACKUP_DIR"
fi

echo "Deploying new build..."
sudo rm -rf "$NGINX_ROOT"/*
sudo cp -r "$TMP_DIR"/* "$NGINX_ROOT"/

echo "Fixing ownership..."
sudo chown -R www-data:www-data "$NGINX_ROOT"

echo "Reloading Nginx..."
sudo systemctl reload nginx

echo "Deployment complete. (ENV=$ENV, VERSION=$VERSION)"
