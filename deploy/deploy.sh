#!/bin/bash

ENV=$1
VERSION=$2

APP_DIR="/home/ubuntu/my_app"
RELEASE_DIR="$APP_DIR/releases/$VERSION"
CURRENT_DIR="$APP_DIR/current"
BACKUP_DIR="$APP_DIR/backup_$(date +%Y%m%d%H%M%S)"

echo "Deploying version $VERSION to $ENV environment..."

# Backup current version
if [ -d "$CURRENT_DIR" ]; then
    cp -r "$CURRENT_DIR" "$BACKUP_DIR"
    echo "Backup created at $BACKUP_DIR"
fi

# Update current version
rm -rf "$CURRENT_DIR"
cp -r "$RELEASE_DIR" "$CURRENT_DIR"

# Restart application (adjust based on your app)
cd "$CURRENT_DIR"
pm2 restart app || pm2 start app.js || npm start &

echo "Deployment of version $VERSION completed."
