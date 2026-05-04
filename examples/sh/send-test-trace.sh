#!/usr/bin/env bash
# Send a sample OTLP trace to Alloy (forwarded to Tempo) for testing

ALLOY_ENDPOINT="${ALLOY_ENDPOINT:-https://alloy.example.com}"
ALLOY_USER="${ALLOY_USER:-admin}"
ALLOY_PASSWORD="${ALLOY_PASSWORD:-password}"

NOW_NS=$(python3 -c "import time; print(int(time.time() * 1e9))")
END_NS=$(python3 -c "import time; print(int((time.time() + 1) * 1e9))")

curl -s -u "${ALLOY_USER}:${ALLOY_PASSWORD}" -X POST "${ALLOY_ENDPOINT}/v1/traces" \
  -H "Content-Type: application/json" \
  -d "{
  \"resourceSpans\": [
    {
      \"resource\": {
        \"attributes\": [
          { \"key\": \"service.name\", \"value\": { \"stringValue\": \"test-service\" } }
        ]
      },
      \"scopeSpans\": [
        {
          \"scope\": { \"name\": \"test-scope\" },
          \"spans\": [
            {
              \"traceId\": \"DD11DD11DD11DD11DD11DD11DD11DD11\",
              \"spanId\": \"AABB001122334455\",
              \"name\": \"correct-timestamp-test\",
              \"kind\": 1,
              \"startTimeUnixNano\": \"${NOW_NS}\",
              \"endTimeUnixNano\": \"${END_NS}\",
              \"attributes\": [
                { \"key\": \"http.method\", \"value\": { \"stringValue\": \"GET\" } },
                { \"key\": \"http.url\", \"value\": { \"stringValue\": \"/api/now\" } }
              ],
              \"status\": { \"code\": 1 }
            }
          ]
        }
      ]
    }
  ]
}"

echo ""
echo "Trace sent. Search in Grafana (Tempo datasource) with: { .service.name = \"test-service\" }"
echo "Trace ID: DD11DD11DD11DD11DD11DD11DD11DD11"
