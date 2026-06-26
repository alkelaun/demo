#!/bin/sh
# Configures Wiki.js OIDC via direct Postgres.
# Gitea is handled by gitea-provisioner (uses gitea CLI for proper encryption).
set -eu

# Browser-facing (public HTTPS) — used for auth redirect and logout
PUB="https://id.${DOMAIN}/realms/ons/protocol/openid-connect"
# Server-side (internal Docker) — used for token exchange and userinfo
INT="http://keycloak:8080/realms/ons/protocol/openid-connect"

wait_table() {
  local db=$1 user=$2 pass=$3 table=$4
  printf 'Waiting for %s.%s ...' "$db" "$table"
  until PGPASSWORD="$pass" psql -h postgres -U "$user" -d "$db" \
      -c "SELECT 1 FROM \"$table\" LIMIT 1" >/dev/null 2>&1; do
    printf '.'
    sleep 5
  done
  echo ' ready'
}

# ── Wiki.js ────────────────────────────────────────────────────────────────
wait_table wikijs wikijs "$WIKIJS_DB_PASSWORD" authentication

WIKIJS_CFG='{"clientId":"wikijs","clientSecret":"'"$WIKIJS_OIDC_SECRET"'","authorizationURL":"'"$PUB/auth"'","tokenURL":"'"$INT/token"'","userInfoURL":"'"$INT/userinfo"'","issuer":"https://id.'"$DOMAIN"'/realms/ons","scope":"openid email profile","logoutEndpoint":"'"$PUB/logout"'","usernameClaim":"preferred_username","emailClaim":"email","displayNameClaim":"name","mappingGroups":""}'

PGPASSWORD="$WIKIJS_DB_PASSWORD" psql -h postgres -U wikijs -d wikijs -c \
  "INSERT INTO authentication (key, \"strategyKey\", \"displayName\", \"order\", \"isEnabled\", \"selfRegistration\", \"domainWhitelist\", \"autoEnrollGroups\", config)
   VALUES ('keycloak', 'oidc', 'Keycloak', 1, true, true, '[]', '[]', '$WIKIJS_CFG')
   ON CONFLICT (key) DO UPDATE SET config = EXCLUDED.config, \"isEnabled\" = true;"
echo 'Wiki.js: Keycloak OIDC strategy configured'

echo 'Provisioning complete.'
