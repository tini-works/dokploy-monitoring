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

## Commands

Smoke-test the stack after deploy. Run any of the senders below — each will prompt for or read the Alloy endpoint and credentials. After each, confirm the signal lands in Grafana.

### Bash (curl)

The scripts prompt interactively for endpoint, user, and password (password is hidden).

```bash
./examples/sh/send-test-log.sh "hello from devops"
./examples/sh/send-test-metric.sh 42
./examples/sh/send-test-trace.sh
```

### Node (OpenTelemetry + tsx)

Configure once via `.env`, then run.

```bash
cd examples/node
cp .env.example .env       # then edit ALLOY_* values
pnpm install               # or: npm install
pnpm start                 # or: npm start
```

### Verify in Grafana

Open `https://grafana.<your-domain>` and check each datasource:

| Signal | Datasource | Query                                                                |
| ------ | ---------- | -------------------------------------------------------------------- |
| Logs   | Loki       | `{service_name="test-service"}` or `{service_name="node-otel-test"}` |
| Metric | Mimir      | `test_temperature`                                                   |
| Trace  | Tempo      | `{ .service.name = "test-service" }` or `"node-otel-test"`           |
