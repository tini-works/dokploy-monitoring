# Dokploy Monitoring Stack

Grafana + Loki + Tempo + Mimir + Alloy as a single Dokploy Compose service.

## Setup in Dokploy

1. **Create Service → Compose**
   - Provider: Git
   - Repository: this repo (or your fork)
   - Branch: `main`
   - Compose path: `docker-compose.yml`

2. **Environment** — paste from `.env.example`:
   ```env
   GRAFANA_ADMIN_USER=admin
   GRAFANA_ADMIN_PASSWORD=<strong-password>
   ```

3. **Domains** — copy `domains.example.json` to `domains.json`, replace `example.com` with your domain, then **Import** it in the Domains tab.

4. **Deploy** — open `https://grafana.<your-domain>` and log in.
