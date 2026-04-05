#!/bin/bash
set -e

SITE_NAME="stelvis.local"
DB_ROOT_PASSWORD="stelvis2024"
ADMIN_PASSWORD="admin2024"
CONFIG_FILE="/home/frappe/frappe-bench/sites/common_site_config.json"
SITE_DIR="/home/frappe/frappe-bench/sites/${SITE_NAME}/site_config.json"

echo ">>> Waiting for services..."
sleep 10

echo ">>> Writing site config..."
cat > "$CONFIG_FILE" <<'JSONEOF'
{
  "db_host": "mariadb",
  "db_port": 3306,
  "redis_cache": "redis://redis-cache:6379",
  "redis_queue": "redis://redis-queue:6379",
  "redis_socketio": "redis://redis-queue:6379",
  "socketio_port": 9000
}
JSONEOF

if [ -f "$SITE_DIR" ]; then
  echo ">>> Site already exists. Skipping creation."
else
  echo ">>> Creating site ${SITE_NAME}..."
  echo ">>> This takes 5-10 minutes on first run. Please wait..."
  bench new-site "$SITE_NAME" \
    --mariadb-root-password "$DB_ROOT_PASSWORD" \
    --admin-password "$ADMIN_PASSWORD" \
    --install-app erpnext \
    --set-default
  bench --site "$SITE_NAME" set-config developer_mode 0
  bench --site "$SITE_NAME" set-config server_script_enabled 1
  bench --site "$SITE_NAME" scheduler enable

  # Fix DB user to allow connections from any container in the network
  echo ">>> Fixing database access..."
  DB_USER=$(python3 -c "import json; print(json.load(open('$SITE_DIR'))['db_name'])" 2>/dev/null)
  if [ -n "$DB_USER" ]; then
    # Get current host for this user
    CURRENT_HOST=$(mysql -h mariadb -uroot -p"$DB_ROOT_PASSWORD" -N -e \
      "SELECT Host FROM mysql.global_priv WHERE User='${DB_USER}' LIMIT 1;" 2>/dev/null)
    if [ -n "$CURRENT_HOST" ] && [ "$CURRENT_HOST" != "%" ]; then
      mysql -h mariadb -uroot -p"$DB_ROOT_PASSWORD" -e \
        "RENAME USER '${DB_USER}'@'${CURRENT_HOST}' TO '${DB_USER}'@'%'; FLUSH PRIVILEGES;" 2>/dev/null || true
    fi
    echo ">>> Database access fixed for user ${DB_USER}."
  fi

  echo ">>> Site created successfully!"
fi

echo ">>> Done! ERPNext is ready."
