#!/usr/bin/env bash
# Vitamin G AI Proxy — smoke-test script for manual Worker validation
#
# Usage:
#   ./test-worker.sh <WORKER_URL> <SHARED_TOKEN>
#
# Example:
#   ./test-worker.sh "https://vg-ai-proxy.kyleharrington.workers.dev/ai" "8F3A2D1B-9C4E-4F5A-B6D7-1A2B3C4D5E6F"
#
# Expected results:
#   Test 1 (motivation): HTTP 200 with {"text":"..."}
#   Test 2 (suggestions): HTTP 200 with {"suggestions":["...","...","..."]}
#   Test 3 (bad token): HTTP 401

set -euo pipefail

WORKER_URL="${1:-}"
SHARED_TOKEN="${2:-}"

if [[ -z "$WORKER_URL" || -z "$SHARED_TOKEN" ]]; then
  echo "Usage: $0 <WORKER_URL> <SHARED_TOKEN>"
  echo "Example: $0 'https://vg-ai-proxy.kyleharrington.workers.dev/ai' 'YOUR-UUID-HERE'"
  exit 1
fi

PASS=0
FAIL=0

assert_status() {
  local test_name="$1"
  local expected_status="$2"
  local actual_status="$3"
  local response_body="$4"

  if [[ "$actual_status" == "$expected_status" ]]; then
    echo "  PASS: $test_name (HTTP $actual_status)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name — expected HTTP $expected_status, got HTTP $actual_status"
    echo "        Response: $response_body"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "Vitamin G AI Proxy — Smoke Tests"
echo "URL: $WORKER_URL"
echo "-----------------------------------"

# Test 1: POST with valid token + type=motivation — expect HTTP 200 + .text
echo ""
echo "Test 1: motivation (valid token)"
MOTIVATION_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$WORKER_URL" \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"motivation\",\"token\":\"$SHARED_TOKEN\",\"goals\":[{\"title\":\"Exercise daily\",\"category\":\"body\"}],\"streak\":7}")
MOTIVATION_STATUS=$(echo "$MOTIVATION_RESPONSE" | tail -n1)
MOTIVATION_BODY=$(echo "$MOTIVATION_RESPONSE" | sed '$d')

assert_status "motivation endpoint" "200" "$MOTIVATION_STATUS" "$MOTIVATION_BODY"

if [[ "$MOTIVATION_STATUS" == "200" ]]; then
  TEXT_VALUE=$(echo "$MOTIVATION_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('text','MISSING'))" 2>/dev/null || echo "PARSE_ERROR")
  if [[ "$TEXT_VALUE" == "MISSING" || "$TEXT_VALUE" == "PARSE_ERROR" ]]; then
    echo "  WARN: .text field missing or unparseable — body: $MOTIVATION_BODY"
  else
    echo "  body.text: $TEXT_VALUE"
  fi
fi

# Test 2: POST with valid token + type=suggestions — expect HTTP 200 + .suggestions length == 3
echo ""
echo "Test 2: suggestions (valid token)"
SUGGESTIONS_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$WORKER_URL" \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"suggestions\",\"token\":\"$SHARED_TOKEN\",\"goals\":[{\"title\":\"Read more\",\"category\":\"mind\"},{\"title\":\"Walk daily\",\"category\":\"body\"}],\"streak\":3}")
SUGGESTIONS_STATUS=$(echo "$SUGGESTIONS_RESPONSE" | tail -n1)
SUGGESTIONS_BODY=$(echo "$SUGGESTIONS_RESPONSE" | sed '$d')

assert_status "suggestions endpoint" "200" "$SUGGESTIONS_STATUS" "$SUGGESTIONS_BODY"

if [[ "$SUGGESTIONS_STATUS" == "200" ]]; then
  SUGGESTIONS_COUNT=$(echo "$SUGGESTIONS_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('suggestions',[])))" 2>/dev/null || echo "PARSE_ERROR")
  if [[ "$SUGGESTIONS_COUNT" == "3" ]]; then
    echo "  PASS: .suggestions | length == 3"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: .suggestions | length == $SUGGESTIONS_COUNT (expected 3)"
    echo "        Response: $SUGGESTIONS_BODY"
    FAIL=$((FAIL + 1))
  fi
fi

# Test 3: POST with bad token — expect HTTP 401
echo ""
echo "Test 3: bad token (expect 401)"
BADTOKEN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$WORKER_URL" \
  -H "Content-Type: application/json" \
  -d '{"type":"motivation","token":"wrong-token","goals":[],"streak":0}')
BADTOKEN_STATUS=$(echo "$BADTOKEN_RESPONSE" | tail -n1)
BADTOKEN_BODY=$(echo "$BADTOKEN_RESPONSE" | sed '$d')

assert_status "bad token rejection" "401" "$BADTOKEN_STATUS" "$BADTOKEN_BODY"

# Test 4: Rate limit — fire 12 rapid POSTs, assert at least one 429
echo ""
echo "Test 4: rate limit (12 rapid requests — expect at least one 429)"
GOT_429=0
for i in $(seq 1 12); do
  RL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WORKER_URL" \
    -H "Content-Type: application/json" \
    -d "{\"type\":\"motivation\",\"token\":\"$SHARED_TOKEN\",\"goals\":[{\"title\":\"Run\",\"category\":\"body\"}],\"streak\":1}")
  if [[ "$RL_STATUS" == "429" ]]; then
    GOT_429=$((GOT_429 + 1))
  fi
done

if [[ "$GOT_429" -gt 0 ]]; then
  echo "  PASS: rate limiter triggered ($GOT_429/12 requests returned 429)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: no 429 returned after 12 rapid requests — rate limiter may not be deployed"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "-----------------------------------"
echo "Results: $PASS passed, $FAIL failed"

if [[ "$FAIL" -gt 0 ]]; then
  echo "SMOKE TEST FAILED — review output above"
  exit 1
else
  echo "SMOKE TEST PASSED"
  exit 0
fi
