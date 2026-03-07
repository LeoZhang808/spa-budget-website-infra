set -euo pipefail

BASE_URL="${1:?Usage: smoke-test.sh <base-url>}"
BASE_URL="${BASE_URL%/}"

MAX_RETRIES=5
RETRY_INTERVAL=10
PASSED=true

echo "=== Smoke Tests: $BASE_URL ==="

for attempt in $(seq 1 "$MAX_RETRIES"); do
  echo ""
  echo "--- Attempt $attempt/$MAX_RETRIES ---"
  ALL_OK=true

  if curl -sf "$BASE_URL/" -o /dev/null; then
    echo "[PASS] Frontend — $BASE_URL/ returned HTTP 200"
  else
    echo "[FAIL] Frontend — $BASE_URL/ did not return HTTP 200"
    ALL_OK=false
  fi

  HEALTH_RESPONSE=$(curl -sf "$BASE_URL/api/v1/health" 2>/dev/null || true)
  if [ -n "$HEALTH_RESPONSE" ]; then
    echo "[PASS] Backend health — $BASE_URL/api/v1/health returned HTTP 200"
  else
    echo "[FAIL] Backend health — $BASE_URL/api/v1/health did not return HTTP 200"
    ALL_OK=false
  fi

  if echo "$HEALTH_RESPONSE" | grep -q '"status":"ok"'; then
    echo "[PASS] Health body — response contains '\"status\":\"ok\"'"
  else
    echo "[FAIL] Health body — response does not contain '\"status\":\"ok\"'"
    ALL_OK=false
  fi

  if [ "$ALL_OK" = true ]; then
    echo ""
    echo "=== All smoke tests PASSED ==="
    exit 0
  fi

  if [ "$attempt" -lt "$MAX_RETRIES" ]; then
    echo "Retrying in ${RETRY_INTERVAL}s..."
    sleep "$RETRY_INTERVAL"
  fi
done

echo ""
echo "=== Smoke tests FAILED after $MAX_RETRIES attempts ==="
exit 1
