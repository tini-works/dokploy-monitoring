#!/usr/bin/env bash
# Send a sample OTLP metric to Alloy (forwarded to Mimir) for testing

ALLOY_ENDPOINT="${ALLOY_ENDPOINT:-https://alloy.example.com}"
ALLOY_USER="${ALLOY_USER:-admin}"
ALLOY_PASSWORD="${ALLOY_PASSWORD:-password}"

NOW_NS=$(python3 -c "import time; print(int(time.time() * 1e9))")
VALUE="${1:-42.0}"

curl -s -u "${ALLOY_USER}:${ALLOY_PASSWORD}" -X POST "${ALLOY_ENDPOINT}/v1/metrics" \
  -H "Content-Type: application/json" \
  -d "{
  \"resourceMetrics\": [
    {
      \"resource\": {
        \"attributes\": [
          { \"key\": \"service.name\", \"value\": { \"stringValue\": \"curl-test\" } }
        ]
      },
      \"scopeMetrics\": [
        {
          \"scope\": { \"name\": \"test-scope\" },
          \"metrics\": [
            {
              \"name\": \"test_temperature\",
              \"gauge\": {
                \"dataPoints\": [
                  {
                    \"asDouble\": ${VALUE},
                    \"timeUnixNano\": \"${NOW_NS}\"
                  }
                ]
              }
            }
          ]
        }
      ]
    }
  ]
}"

echo ""
echo "Metric sent. Query in Grafana (Mimir datasource): test_temperature"
echo "Value: ${VALUE}"
