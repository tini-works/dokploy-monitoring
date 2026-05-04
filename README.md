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

3. **Domains** — open the **Domains** tab and add each entry below with **Create Domain**. Replace `<your-domain>` with your real domain. All entries: HTTPS on, Certificate = Let's Encrypt.

   | Host | Path | Service | Container Port |
   | --- | --- | --- | --- |
   | `grafana.<your-domain>` | `/` | `grafana` | `3000` |
   | `alloy.<your-domain>` | `/` | `alloy` | `12345` |
   | `alloy.<your-domain>` | `/v1` | `alloy` | `4318` |
   | `alloy.<your-domain>` | `/loki` | `alloy` | `3500` |
   | `alloy.<your-domain>` | `/api/v1/metrics/write` | `alloy` | `9090` |

   The four `alloy.<your-domain>` entries share one host so a single TLS cert covers all routes.

4. **Protect Alloy with basic auth** (Traefik middleware)

   Alloy's UI and ingest endpoints have no built-in auth. Put a basic-auth middleware in front.

   **a. Generate a hashed credential** on any machine with `htpasswd`:
   ```bash
   htpasswd -nb monitor 'your-password'
   # → monitor:$apr1$abc123...$xyz...
   ```

   **b. Create the middleware** in Dokploy: go to **Dokploy → Settings → Traefik** (or the **Traefik** tab on the server) and open the dynamic config file editor. Add a new file `middlewares.yml` (or append to an existing one):
   ```yaml
   http:
     middlewares:
       alloy-auth:
         basicAuth:
           users:
             - "monitor:$apr1$abc123...$xyz..."
   ```
   Paste the full `htpasswd` output as one line inside `users:`. Save — Traefik picks it up automatically, no restart needed.

   **c. Attach it to each Alloy domain.** In the service's **Domains** tab, edit each `alloy.<your-domain>` row, open **Advanced**, and add to **Middlewares**:
   ```
   alloy-auth@file
   ```
   Apply it to all four `alloy.<your-domain>` entries. Leave `grafana.<your-domain>` alone — Grafana has its own login.

   Now every request to `https://alloy.<your-domain>/*` requires the `monitor` credentials. Senders must include them, e.g.:
   ```
   Authorization: Basic <base64(monitor:your-password)>
   ```
   Or for tools that accept it inline: `https://monitor:your-password@alloy.<your-domain>/...`.

5. **Deploy** — open `https://grafana.<your-domain>` and log in.
