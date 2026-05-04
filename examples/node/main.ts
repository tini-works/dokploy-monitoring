// Send one OTLP trace, metric, and log to Alloy via HTTPS + basic auth.
// Run with: pnpm install && pnpm start  (or: npm i && npm start)

import { metrics, trace } from "@opentelemetry/api";
import { logs } from "@opentelemetry/api-logs";
import { OTLPLogExporter } from "@opentelemetry/exporter-logs-otlp-http";
import { OTLPMetricExporter } from "@opentelemetry/exporter-metrics-otlp-http";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { Resource } from "@opentelemetry/resources";
import {
  LoggerProvider,
  SimpleLogRecordProcessor,
} from "@opentelemetry/sdk-logs";
import {
  MeterProvider,
  PeriodicExportingMetricReader,
} from "@opentelemetry/sdk-metrics";
import { SimpleSpanProcessor } from "@opentelemetry/sdk-trace-base";
import { NodeTracerProvider } from "@opentelemetry/sdk-trace-node";

const ALLOY_ENDPOINT =
  process.env.ALLOY_ENDPOINT ?? "https://alloy.example.com";
const ALLOY_USER = process.env.ALLOY_USER ?? "admin";
const ALLOY_PASSWORD = process.env.ALLOY_PASSWORD ?? "password";
const SERVICE_NAME = process.env.SERVICE_NAME ?? "node-otel-test";

const authToken = Buffer.from(`${ALLOY_USER}:${ALLOY_PASSWORD}`).toString(
  "base64",
);
const headers = { Authorization: `Basic ${authToken}` };

const resource = new Resource({ "service.name": SERVICE_NAME });

const tracerProvider = new NodeTracerProvider({
  resource,
  spanProcessors: [
    new SimpleSpanProcessor(
      new OTLPTraceExporter({
        url: `${ALLOY_ENDPOINT}/v1/traces`,
        headers,
      }),
    ),
  ],
});
tracerProvider.register();

const meterProvider = new MeterProvider({
  resource,
  readers: [
    new PeriodicExportingMetricReader({
      exporter: new OTLPMetricExporter({
        url: `${ALLOY_ENDPOINT}/v1/metrics`,
        headers,
      }),
      exportIntervalMillis: 1_000,
    }),
  ],
});
metrics.setGlobalMeterProvider(meterProvider);

const loggerProvider = new LoggerProvider({
  resource,
  processors: [
    new SimpleLogRecordProcessor(
      new OTLPLogExporter({
        url: `${ALLOY_ENDPOINT}/v1/logs`,
        headers,
      }),
    ),
  ],
});
logs.setGlobalLoggerProvider(loggerProvider);

async function main() {
  const tracer = trace.getTracer(SERVICE_NAME);
  const meter = metrics.getMeter(SERVICE_NAME);
  const logger = logs.getLogger(SERVICE_NAME);

  const span = tracer.startSpan("correct-timestamp-test", {
    attributes: {
      "http.method": "GET",
      "http.url": "/api/now",
    },
  });
  await new Promise((r) => setTimeout(r, 100));
  span.end();

  const gauge = meter.createGauge("test_temperature");
  gauge.record(Number(process.env.METRIC_VALUE ?? 42), {
    source: SERVICE_NAME,
  });

  logger.emit({
    severityText: "INFO",
    body: process.env.LOG_MESSAGE ?? `hello from ${SERVICE_NAME}`,
    attributes: {
      "service.name": SERVICE_NAME,
      level: "info",
      source: "main.ts",
    },
  });

  await tracerProvider.forceFlush();
  await meterProvider.forceFlush();
  await loggerProvider.forceFlush();

  await tracerProvider.shutdown();
  await meterProvider.shutdown();
  await loggerProvider.shutdown();

  console.log(`Sent trace, metric, log to ${ALLOY_ENDPOINT}`);
  console.log(`  Tempo:  { .service.name = "${SERVICE_NAME}" }`);
  console.log(`  Mimir:  test_temperature{source="${SERVICE_NAME}"}`);
  console.log(`  Loki:   {service_name="${SERVICE_NAME}"}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
