#!/bin/sh
# Runs inside the Nextcloud container on every start (before-starting hook).
# Enables the user_oidc app and upserts the Keycloak provider.
set -eu

# Skip if Nextcloud isn't installed yet (shouldn't happen in before-starting, but safe guard)
php /var/www/html/occ status --no-ansi 2>/dev/null | grep -q "installed: true" || exit 0

php /var/www/html/occ app:enable user_oidc --no-ansi
php /var/www/html/occ user_oidc:provider keycloak \
  --clientid=nextcloud \
  --clientsecret="${NEXTCLOUD_OIDC_SECRET}" \
  --discoveryuri="https://id.${DOMAIN}/realms/ons/.well-known/openid-configuration" \
  --unique-uid=1 \
  --mapping-uid=preferred_username \
  --mapping-email=email \
  --mapping-display-name=name \
  --no-ansi
echo 'Nextcloud: user_oidc configured with Keycloak'
