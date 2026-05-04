# Dokploy Monitoring Stack

A drop-in observability stack for [Dokploy](https://dokploy.com) servers. Deploys Grafana + Loki (logs) + Tempo (traces) + Mimir (metrics) + Alloy (collector) + node-exporter (host metrics) as a single Compose service.

## What you get

| Service | Purpose | Internal port |
| --- | --- | --- |
| **Grafana** | Dashboards & UI | 3000 |
| **Mimir** | Metrics storage (Prometheus-compatible) | 9009 |
| **Loki** | Log storage | 3100 |
| **Tempo** | Trace storage | 3200 |
| **Alloy** | Ingest collector (OTLP, Prom remote_write, Loki push) | 12345, 4317, 4318, 9090, 3500 |
| **node-exporter** | Host metrics | 9100 |

Grafana datasources are pre-provisioned and the trace ↔ log ↔ metric correlation links are wired up.

## Deploy on Dokploy

### 1. Create a Compose service

In your Dokploy project: **Create Service → Compose**, then point it at this repo (or a fork).

- **Provider**: Git
- **Repository URL**: `<your fork>` (or this repo)
- **Branch**: `main`
- **Compose path**: `docker-compose.yml`

### 2. Set environment variables

In the service's **Environment** tab, paste the contents of [`.env.example`](./.env.example) and replace the placeholders:

```env
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=<a-strong-password>
```

### 3. Configure domains

Copy `domains.example.json` to `domains.json` and replace `example.com` with your real domains. Then in the service's **Domains** tab, click **Import** and upload your `domains.json`.

The example exposes:

- `grafana.example.com` → Grafana UI (port 3000)
- `alloy.example.com/` → Alloy UI (port 12345)
- `alloy.example.com/v1` → OTLP HTTP ingest (port 4318)
- `alloy.example.com/loki` → Loki push ingest (port 3500)
- `alloy.example.com/api/v1/metrics/write` → Prometheus remote_write ingest (port 9090)

> All routes need to share the same host so TLS only needs one cert. If you prefer separate hosts, edit the file before importing.

### 4. Deploy

Click **Deploy**. Dokploy will build the images from the `monitoring/*` Dockerfiles and start the stack on the `dokploy-network`.

Open `https://grafana.<your-domain>` and log in with the credentials you set.

## Sending data to the stack

Point your apps at the Alloy endpoints (or the internal service DNS if the app runs on the same Dokploy server).

### From outside the server

| Signal | Endpoint |
| --- | --- |
| OTLP/HTTP traces, logs, metrics | `https://alloy.<your-domain>/v1/{traces,logs,metrics}` |
| Prometheus remote_write | `https://alloy.<your-domain>/api/v1/metrics/write` |
| Loki push | `https://alloy.<your-domain>/loki/api/v1/push` |

### From other services on the same Dokploy server

Use the internal hostnames (no TLS needed):

| Signal | Endpoint |
| --- | --- |
| OTLP/gRPC | `http://alloy:4317` |
| OTLP/HTTP | `http://alloy:4318` |
| Prometheus remote_write | `http://alloy:9090/api/v1/metrics/write` |
| Loki push | `http://alloy:3500/loki/api/v1/push` |

The other service must be attached to the `dokploy-network` (Dokploy does this by default).

## Customizing

| File | What to change |
| --- | --- |
| `monitoring/alloy/config.alloy` | Add/remove receivers, scrape jobs, change `external_labels` (cluster/namespace) |
| `monitoring/loki/loki.yml` | Retention period, ingestion limits |
| `monitoring/mimir/mimir.yml` | Metrics retention (default 720h / 30d) |
| `monitoring/tempo/tempo.yml` | Trace retention, metrics-generator processors |
| `monitoring/grafana/datasources.yml` | Default datasource, derived fields |

After editing, push to your branch and redeploy from Dokploy.

## Resource footprint

The Compose file declares conservative `deploy.resources` limits. Total memory ceiling is ~4 GB. Adjust the `limits` blocks in `docker-compose.yml` if your server is smaller.

## Storage

All data lives in named Docker volumes (`grafana-data`, `loki-data`, `tempo-data`, `mimir-data`, `alloy-data`). They survive redeploys. To wipe state, remove the volumes from Dokploy's volume manager.

For production at scale, switch the `*.yml` storage backends from `filesystem` to S3-compatible object storage.
