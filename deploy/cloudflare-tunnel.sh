#!/usr/bin/env bash
# Install Wirebound on Linux and hook it to an existing Cloudflare Tunnel.
# Usage:
#   sudo ./deploy/cloudflare-tunnel.sh play.yourdomain.com
set -euo pipefail

HOSTNAME="${1:-}"
if [[ -z "$HOSTNAME" ]]; then
  echo "Usage: sudo $0 play.yourdomain.com"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST=/opt/wirebound

if ! command -v node >/dev/null 2>&1; then
  echo "Install Node.js 18+ first (https://nodejs.org or: sudo apt install nodejs)"
  exit 1
fi
if ! command -v cloudflared >/dev/null 2>&1; then
  echo "cloudflared not found. Install: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/"
  exit 1
fi

sudo mkdir -p "$DEST"
sudo rsync -a --delete \
  --exclude node_modules \
  --exclude .git \
  "$ROOT/" "$DEST/"

NODE_BIN="$(command -v node)"
sudo sed -i "s|/usr/bin/node|$NODE_BIN|" "$DEST/deploy/wirebound-node.service"
sudo cp "$DEST/deploy/wirebound-node.service" /etc/systemd/system/wirebound.service
sudo systemctl daemon-reload
sudo systemctl enable --now wirebound
sudo systemctl restart wirebound

# Point this hostname at the local game. Safe if a tunnel already exists.
if cloudflared tunnel list >/dev/null 2>&1; then
  TUNNEL_NAME="$(cloudflared tunnel list -o json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['name'] if d else '')" || true)"
  if [[ -n "${TUNNEL_NAME:-}" ]]; then
    cloudflared tunnel route dns "$TUNNEL_NAME" "$HOSTNAME" || true
    echo "DNS route requested: $HOSTNAME -> tunnel $TUNNEL_NAME"
  fi
fi

echo
echo "Add this ingress rule to /etc/cloudflared/config.yml (or ~/.cloudflared/config.yml):"
echo
echo "  - hostname: $HOSTNAME"
echo "    service: http://127.0.0.1:5177"
echo
echo "Put it ABOVE the catch-all  http_status:404  line, then:"
echo "  sudo systemctl restart cloudflared"
echo
echo "Open https://$HOSTNAME"
sudo systemctl --no-pager --lines=8 status wirebound || true
