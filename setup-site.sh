#!/bin/bash
# ============================================
# Stelvis ERPNext - First Time Site Setup
# Run this ONCE after docker compose up -d
# ============================================

set -e

SITE_NAME="${SITE_NAME:-stelvis.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin2024}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-stelvis2024}"

echo "============================================"
echo "  Stelvis ERPNext - Setting up site..."
echo "============================================"
echo ""

# Wait for containers to be ready
echo "[1/5] Waiting for services to be ready..."
sleep 10

# Create the site
echo "[2/5] Creating site: $SITE_NAME"
docker exec stelvis-erpnext bench new-site "$SITE_NAME" \
  --mariadb-root-password "$DB_ROOT_PASSWORD" \
  --admin-password "$ADMIN_PASSWORD" \
  --install-app erpnext \
  --set-default

# Enable POS
echo "[3/5] Configuring site..."
docker exec stelvis-erpnext bench --site "$SITE_NAME" set-config developer_mode 0
docker exec stelvis-erpnext bench --site "$SITE_NAME" set-config server_script_enabled 1

# Build assets
echo "[4/5] Building assets..."
docker exec stelvis-erpnext bench build

# Set site as default
echo "[5/5] Finalizing..."
docker exec stelvis-erpnext bench use "$SITE_NAME"

echo ""
echo "============================================"
echo "  Setup Complete!"
echo ""
echo "  Open your browser and go to:"
echo "  http://stelvis.local"
echo ""
echo "  Login with:"
echo "  Username: Administrator"
echo "  Password: $ADMIN_PASSWORD"
echo ""
echo "  To enable POS:"
echo "  1. Go to Setup Wizard and complete it"
echo "  2. Go to POS Profile and create one"
echo "  3. Open POS from the sidebar"
echo "============================================"
