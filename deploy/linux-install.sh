#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEPLOY="$ROOT/deploy"
# shellcheck disable=SC1091
source "$DEPLOY/config.env"

if [[ -z "${DOMAIN:-}" || "$DOMAIN" == *yourdomain* ]]; then
  echo "Edit deploy/config.env and set DOMAIN and EMAIL first."
  exit 1
fi
if [[ -z "${EMAIL:-}" || "$EMAIL" == *yourdomain* ]]; then
  echo "Set EMAIL in deploy/config.env (Let's Encrypt)."
  exit 1
fi

if ! command -v caddy >/dev/null 2>&1; then
  echo "Install Caddy first: https://caddyserver.com/docs/install"
  exit 1
fi

sudo mkdir -p /opt/wirebound/public
sudo rsync -a --delete "$ROOT/public/" /opt/wirebound/public/
sudo chown -R caddy:caddy /opt/wirebound 2>/dev/null || sudo chown -R www-data:www-data /opt/wirebound

sudo tee /etc/caddy/Caddyfile >/dev/null <<EOF
{
	email ${EMAIL}
}

${DOMAIN} {
	encode gzip zstd
	root * /opt/wirebound/public
	try_files {path} /index.html
	file_server
	header {
		X-Content-Type-Options nosniff
		Referrer-Policy no-referrer
		X-Frame-Options SAMEORIGIN
	}
}
EOF

sudo systemctl enable --now caddy
sudo systemctl reload caddy
sudo systemctl status caddy --no-pager
echo
echo "Open https://${DOMAIN}"
