#!/bin/bash
ENV=$1

APP_DIR="/home/ubuntu/my_app"
CURRENT_DIR="$APP_DIR/current"

LATEST_BACKUP=$(ls -td $APP_DIR/backup_* | head -1)

if [ -d "$LATEST_BACKUP" ]; then
  echo "Rolling back to previous backup..."
  rm -rf "$CURRENT_DIR"
  cp -r "$LATEST_BACKUP" "$CURRENT_DIR"
  echo "Restarting the app..."
  pm2 restart app.js || systemctl restart myapp
else
  echo "No backup found. Rollback failed."
  exit 1
fi
