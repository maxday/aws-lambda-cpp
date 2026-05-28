#!/bin/bash
set -euo pipefail

FUNCTION_NAME=$1
PAYLOAD=${2:-}

aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --invocation-type RequestResponse \
  --log-type Tail \
  --cli-read-timeout 30 \
  ${PAYLOAD:+--payload "$PAYLOAD"} \
  /tmp/response_payload > /tmp/invoke_result.json

echo "Status code: $(jq '.StatusCode' /tmp/invoke_result.json)"
echo "Function error: $(jq -r '.FunctionError // empty' /tmp/invoke_result.json)"
