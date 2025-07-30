#!/bin/bash
ENV=$1
VERSION=$2

APP_DIR="/home/ubuntu/my_app"
RELEASE_DIR="$APP_DIR/releases/$VERSION"
CURRENT_DIR="$APP_DIR/current"

echo "Creating backup..."
cp -r "$CURRENT_DIR" "$APP_DIR/backup_$(date +%s)"

echo "Deploying version $VERSION..."
rm -rf "$CURRENT_DIR"
cp -r "$RELEASE_DIR" "$CURRENT_DIR"

echo "Restarting the app..."
pm2 restart app.js || systemctl restart myapp
