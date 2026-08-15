# Deploy Wirebound on a home server + domain

## Your setup (Linux + Cloudflare Tunnel)

Namecheap holds the domain. Cloudflare tunnels traffic to the house, so you do **not** open ports 80/443 on the router.

### On the Linux home server

1. Copy this project onto the server (USB, `scp`, or git).
2. Install Node 18+ if needed: `sudo apt install nodejs`
3. Run:

```bash
chmod +x deploy/cloudflare-tunnel.sh
sudo ./deploy/cloudflare-tunnel.sh play.yourdomain.com
```

4. Edit `/etc/cloudflared/config.yml` and add **above** the 404 catch-all:

```yaml
ingress:
  - hostname: play.yourdomain.com
    service: http://127.0.0.1:5177
  - service: http_status:404
```

5. Restart the tunnel:

```bash
sudo systemctl restart cloudflared
```

6. In Cloudflare DNS you should see a **CNAME**: `play` → `<tunnel-id>.cfargotunnel.com` (proxied / orange cloud is fine).

Then open `https://play.yourdomain.com`.

If `cloudflared tunnel route dns` was not run yet:

```bash
cloudflared tunnel list
cloudflared tunnel route dns YOUR_TUNNEL_NAME play.yourdomain.com
```

---

## Alternative: Caddy + port forward (no tunnel)

Only if you are not using a Cloudflare Tunnel. See `windows-caddy.ps1` / `linux-install.sh`.

