# Offline Network System — Demo / Dev Stack

A lightweight, internet-connected twin of the production platform for **5–15
users**, on a single cloud VM. Same tools, wired for Single Sign-On behind
Caddy with automatic TLS. Production uses K3s + an internal registry; this
Compose stack is the demo/dev equivalent.

## Contents
| File | Purpose |
|---|---|
| `docker-compose.yml` | Core stack: Caddy, Postgres, Keycloak, Gitea, Guacamole, Wiki.js, Nextcloud, Prometheus, Grafana |
| `Caddyfile` | Reverse proxy + Let's Encrypt TLS, one subdomain per app |
| `.env.example` | Copy to `.env`, then set DOMAIN + secrets |
| `init-db.sh` | Creates one Postgres DB/user per app |
| `prometheus.yml` | Scrape config (host + container metrics) |
| `realm-export.json` | Keycloak realm `ons` with OIDC clients pre-defined |
| `compose.comms.yml` | Add-on: Jitsi (VoIP/VTC) |
| `compose.mail.yml` | Add-on: Roundcube webmail (point at Mailu / internal mail) |
| `../ansible/` | Playbook to install Docker + deploy the stack |

## Prerequisites
- A VM (~4 vCPU / 16 GB / 100 GB), Ubuntu 22.04+, Docker Engine + Compose v2.
- A domain with a **wildcard** `*.DOMAIN` A-record pointing at the VM's IP.
- Open ports 80/443 (and UDP 10000 if using Jitsi).

## Quick start
```bash
cp .env.example .env          # edit DOMAIN, ACME_EMAIL, and every secret
# secrets in realm-export.json (DOMAIN + client secrets) must match .env

docker compose up -d

# One-time: load the Guacamole DB schema (the image ships the SQL)
docker compose exec -T guacamole /opt/guacamole/bin/initdb.sh --postgresql \
  | docker compose exec -T postgres psql -U guacamole -d guacamole
docker compose restart guacamole
```

Add real-time comms:
```bash
docker compose -f docker-compose.yml -f compose.comms.yml up -d
```

## URLs (after DNS + TLS settle)
- `id.DOMAIN` — Keycloak (SSO)        · `git.DOMAIN` — Gitea (source + IaC)
- `remote.DOMAIN` — Guacamole         · `wiki.DOMAIN` — Wiki.js
- `files.DOMAIN` — Nextcloud / WebDAV · `grafana.DOMAIN` — dashboards
- `meet.DOMAIN` — Jitsi (with comms add-on)

## SSO notes
Keycloak imports realm `ons` on first boot. For each app, finish the OIDC
binding in its admin UI (Gitea, Wiki.js, Nextcloud `user_oidc`), or rely on the
pre-wired env (Guacamole, Grafana). Replace every `change-me-*` secret and the
`DOMAIN` placeholders in `realm-export.json` before going live.

> This stack is for demo/dev on the open internet. It is **not** the air-gapped
> production design — see the project plan document for that.
