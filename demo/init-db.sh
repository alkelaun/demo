#!/bin/bash
# Runs once on first Postgres start. Creates one owner + database per app.
set -e

create() {  # $1=user  $2=password  $3=database
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-SQL
    CREATE USER ${1} WITH PASSWORD '${2}';
    CREATE DATABASE ${3} OWNER ${1};
SQL
}

create keycloak  "$KC_DB_PASSWORD"        keycloak
create gitea     "$GITEA_DB_PASSWORD"     gitea
create guacamole "$GUAC_DB_PASSWORD"      guacamole
create wikijs    "$WIKIJS_DB_PASSWORD"    wikijs
create nextcloud "$NEXTCLOUD_DB_PASSWORD" nextcloud
