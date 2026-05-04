# Dokploy Monitoring Stack

Grafana + Loki + Tempo + Mimir + Alloy as a single Dokploy Compose service.

## Setup in Dokploy

1. **Create Service → Compose**
   - Provider: Git
   - Repository: this repo (or your fork)
   - Branch: `main`
   - Compose path: `docker-compose.yml`

2. **Domains** — open the **Domains** tab and add each entry below with **Create Domain**. Replace `<your-domain>` with your real domain. All entries: HTTPS on, Certificate = Let's Encrypt.

   | Host                    | Path                    | Service   | Container Port |
   | ----------------------- | ----------------------- | --------- | -------------- |
   | `grafana.<your-domain>` | `/`                     | `grafana` | `3000`         |
   | `alloy.<your-domain>`   | `/v1`                   | `alloy`   | `4318`         |
   | `alloy.<your-domain>`   | `/loki`                 | `alloy`   | `3500`         |
   | `alloy.<your-domain>`   | `/api/v1/metrics/write` | `alloy`   | `9090`         |

   The four `alloy.<your-domain>` entries share one host so a single TLS cert covers all routes.

3. **Protect Alloy with basic auth** (Traefik middleware)

   **a. Generate a hashed credential**

   ```bash
   htpasswd -nb admin 'password'
   # → admin:$apr1$G3T3XOqn$6JGifVcvveyWFg7gYWZjH0
   ```

   **b. Create the middleware** in Dokploy: go to **Dokploy → Settings → Traefik** (or the **Traefik** tab on the server) and open the dynamic config file editor. Add a new file `middlewares.yml` (or append to an existing one):

   ```yaml
   http:
     middlewares:
       alloy-auth:
         basicAuth:
           users:
             - "admin:$apr1$G3T3XOqn$6JGifVcvveyWFg7gYWZjH0"
   ```

   **c. Attach it to each Alloy domain.** In the service's **Domains** tab, edit each `alloy.<your-domain>` row:

   ```
   alloy-auth@file
   ```

   Now every request to `https://alloy.<your-domain>/*` requires the `admin` credentials. Senders must include them, e.g.:

   ```
   Authorization: Basic <base64(admin:password)>
   ```
