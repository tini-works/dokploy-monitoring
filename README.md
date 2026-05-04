# Dokploy Monitoring Stack

Grafana + Loki + Tempo + Mimir + Alloy as a single Dokploy Compose service.

## Setup in Dokploy

1. **Create Service → Compose**
   - Provider: Git
   - Repository: this repo (or your fork)
   - Branch: `main`
   - Compose path: `docker-compose.yml`

2. **Domains** — open the **Domains** tab and add each entry below.

   | Host                    | Path                    | Service   | Container Port |
   | ----------------------- | ----------------------- | --------- | -------------- |
   | `grafana.<your-domain>` | `/`                     | `grafana` | `3000`         |
   | `alloy.<your-domain>`   | `/v1`                   | `alloy`   | `4318`         |
   | `alloy.<your-domain>`   | `/loki`                 | `alloy`   | `3500`         |
   | `alloy.<your-domain>`   | `/api/v1/metrics/write` | `alloy`   | `9090`         |

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
           # admin / password
           users:
             - "admin:$apr1$G3T3XOqn$6JGifVcvveyWFg7gYWZjH0"
   ```

   **c. Attach it to each Alloy domain.** In the service's **Domains** tab, edit each `alloy.<your-domain>` row:

   ```
   alloy-auth@file
   ```

## Commands

```bash
# bash (curl)
./examples/sh/send-test-log.sh "hello from devops"
./examples/sh/send-test-metric.sh 42
./examples/sh/send-test-trace.sh

# node
cd examples/node && pnpm start
```
