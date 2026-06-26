# Offline Network System — Demo / Dev Stack

A lightweight, internet-connected twin of the production platform for **5–15
users**, on a single cloud VM or local machine. Same tools, wired for Single
Sign-On behind Caddy with automatic TLS. Production uses K3s + an internal
registry; this Compose stack is the demo/dev equivalent.

## Services

| Subdomain | Service | Purpose |
|---|---|---|
| `home.DOMAIN` | Dashboard | Home page linking to all services |
| `id.DOMAIN` | Keycloak | Identity provider, SSO for every app |
| `git.DOMAIN` | Gitea | Git hosting, source code & IaC |
| `remote.DOMAIN` | Guacamole | Clientless remote desktop (SSH/RDP/VNC) |
| `wiki.DOMAIN` | Wiki.js | Collaborative knowledge base |
| `files.DOMAIN` | Nextcloud | File storage & WebDAV |
| `grafana.DOMAIN` | Grafana | Metrics dashboards (Prometheus) |
| `meet.DOMAIN` | Jitsi | VoIP/VTC (add-on, see below) |

## Files

| File | Purpose |
|---|---|
| `docker-compose.yml` | Core stack definition |
| `Caddyfile` | Reverse proxy + TLS, one subdomain per service |
| `.env.example` | Copy to `.env` and fill in secrets |
| `realm-export.json` | Keycloak realm `ons` with all OIDC clients pre-configured |
| `init-db.sh` | Creates one Postgres DB + user per app |
| `provisioner.sh` | One-shot container: configures Wiki.js OIDC via Postgres |
| `gitea-provision.sh` | One-shot container: configures Gitea OAuth2 via Gitea CLI |
| `nextcloud-oidc.sh` | Nextcloud before-starting hook: configures `user_oidc` app |
| `home/index.html` | Home dashboard static HTML |
| `prometheus.yml` | Prometheus scrape config |
| `compose.comms.yml` | Add-on: Jitsi VoIP/VTC |
| `compose.mail.yml` | Add-on: Roundcube webmail |

## Prerequisites

- Docker Engine + Compose v2
- For cloud/server use: a VM (~4 vCPU / 16 GB / 100 GB), Ubuntu 22.04+, open ports 80/443
- For local use: macOS or Linux with Docker Desktop (see **Local dev** below)

## Quick start

```bash
cp .env.example .env
# Edit .env: set DOMAIN and fill in all secrets (generate with openssl rand -base64 32)
```

The `realm-export.json` OIDC client secrets in `.env` must match what's in
`realm-export.json`. The default secrets in `.env.example` already match the
defaults in `realm-export.json` — only override them if you regenerate.

```bash
docker compose up -d

# One-time only: initialize the Guacamole database schema
docker compose exec -T guacamole /opt/guacamole/bin/initdb.sh --postgresql \
  | docker compose exec -T postgres psql -U guacamole -d guacamole
docker compose restart guacamole
```

That's it. Keycloak OIDC is **fully automated** for all other services:
- **Gitea** — `gitea-provisioner` container runs `gitea admin auth add-oauth` on startup
- **Nextcloud** — `nextcloud-oidc.sh` hook runs `occ user_oidc:provider` on every start
- **Wiki.js** — `provisioner` container inserts the OIDC strategy into Postgres
- **Guacamole / Grafana** — configured entirely via environment variables

## Local dev (no DNS, no public IP)

Use [nip.io](https://nip.io) as a zero-config wildcard DNS — no `/etc/hosts` editing required:

```bash
# In .env:
DOMAIN=127.0.0.1.nip.io
```

`*.127.0.0.1.nip.io` resolves to `127.0.0.1` via public DNS. Caddy uses
`local_certs` (its own internal CA) to issue self-signed TLS — your browser
will show a certificate warning the first time. To trust it permanently, import
Caddy's CA cert from the `caddy_data` volume.

## Cloud / production-like use

Point a wildcard `*.DOMAIN` A-record at the VM's public IP and set a real
`ACME_EMAIL`. Remove `local_certs` from the Caddyfile global block — Caddy
will obtain real Let's Encrypt certificates automatically.

## Add real-time comms (Jitsi)

```bash
docker compose -f docker-compose.yml -f compose.comms.yml up -d
```

Requires open UDP port 10000.

## Logins

| Service | Default credentials |
|---|---|
| Keycloak admin console | `admin` / `KC_ADMIN_PASSWORD` from `.env` (master realm) |
| All other services | SSO via Keycloak — login with the `demo` user in the `ons` realm |
| Nextcloud local admin | `admin` / `NEXTCLOUD_ADMIN_PASSWORD` from `.env` |

> This stack is for demo/dev. It is **not** the air-gapped production design —
> see the project plan for that.
