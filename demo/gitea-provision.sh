#!/bin/sh
# Adds Keycloak as an OAuth2 source in Gitea using the Gitea CLI.
# Must run as the 'git' user inside a container sharing the gitea_data volume.
set -eu

printf 'Waiting for Gitea ...'
until wget -q -O/dev/null http://gitea:3000; do
  printf '.'
  sleep 5
done
echo ' ready'

# Delete existing source if present (idempotent)
EXISTING_ID=$(gitea admin auth list 2>/dev/null | awk '/Keycloak/{print $1}' | head -1)
if [ -n "$EXISTING_ID" ]; then
  gitea admin auth delete --id "$EXISTING_ID" 2>/dev/null || true
fi

gitea admin auth add-oauth \
  --name Keycloak \
  --provider openidConnect \
  --key gitea \
  --secret "$GITEA_OIDC_SECRET" \
  --auto-discover-url "http://keycloak:8080/realms/ons/.well-known/openid-configuration" \
  --scopes openid \
  --scopes email \
  --scopes profile

echo 'Gitea: Keycloak OAuth2 source configured'
