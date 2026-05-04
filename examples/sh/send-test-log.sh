#!/usr/bin/env bash
# Send a sample log line to Alloy (forwarded to Loki) for testing

ALLOY_ENDPOINT="${ALLOY_ENDPOINT:-https://alloy.example.com}"
ALLOY_USER="${ALLOY_USER:-admin}"
ALLOY_PASSWORD="${ALLOY_PASSWORD:-password}"

NOW_NS=$(python3 -c "import time; print(int(time.time() * 1e9))")
MESSAGE="${1:-hello from send-test-log.sh}"

curl -s -u "${ALLOY_USER}:${ALLOY_PASSWORD}" -X POST "${ALLOY_ENDPOINT}/loki/api/v1/push" \
  -H "Content-Type: application/json" \
  -d "{
  \"streams\": [
    {
      \"stream\": {
        \"service_name\": \"test-service\",
        \"level\": \"info\",
        \"source\": \"send-test-log.sh\"
      },
      \"values\": [
        [\"${NOW_NS}\", \"${MESSAGE}\"]
      ]
    }
  ]
}"

echo ""
echo "Log sent. Query in Grafana (Loki datasource): {service_name=\"test-service\"}"
echo "Message: ${MESSAGE}"
