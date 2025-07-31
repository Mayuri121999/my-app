#!/bin/bash

ENV=$1
APP_DIR="/home/ubuntu/my_app"
CURRENT_DIR="$APP_DIR/current"

echo "Rolling back in $ENV environment..."

# Find latest backup
LATEST_BACKUP=$(ls -dt $APP_DIR/backup_* | head -n 1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "No backup found. Rollback failed."
    exit 1
fi

# Rollback
rm -rf "$CURRENT_DIR"
cp -r "$LATEST_BACKUP" "$CURRENT_DIR"

# Restart application
cd "$CURRENT_DIR"
pm2 restart app || pm2 start app.js || npm start &

echo "Rollback complete. Restored from $LATEST_BACKUP"
