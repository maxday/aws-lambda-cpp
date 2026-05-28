#!/bin/bash
set -euo pipefail

ASSERTION=$1
TEST_NAME=$2
SNAPSHOTS_DIR="tests/snapshots"

case "$ASSERTION" in
  snapshot)
    EXPECTED=$(cat "$SNAPSHOTS_DIR/${TEST_NAME}.expected")
    ACTUAL=$(cat /tmp/response_payload)
    if [ "$EXPECTED" != "$ACTUAL" ]; then
      echo "::error::Snapshot mismatch for $TEST_NAME"
      echo "Expected: $EXPECTED"
      echo "Actual:   $ACTUAL"
      exit 1
    fi
    echo "Snapshot matched"
    ;;
  length)
    EXPECTED_LENGTH=$(cat "$SNAPSHOTS_DIR/${TEST_NAME}.expected_length")
    ACTUAL_LENGTH=$(wc -c < /tmp/response_payload)
    if [ "$EXPECTED_LENGTH" != "$ACTUAL_LENGTH" ]; then
      echo "::error::Length mismatch for $TEST_NAME"
      echo "Expected: $EXPECTED_LENGTH bytes"
      echo "Actual:   $ACTUAL_LENGTH bytes"
      exit 1
    fi
    echo "Length matched: $ACTUAL_LENGTH bytes"
    ;;
  contains)
    EXPECTED_SUBSTR=$(cat "$SNAPSHOTS_DIR/${TEST_NAME}.expected_contains")
    LOG_TAIL=$(jq -r '.LogResult' /tmp/invoke_result.json | base64 -d)
    FUNCTION_ERROR=$(jq -r '.FunctionError' /tmp/invoke_result.json)
    if [ "$FUNCTION_ERROR" != "Unhandled" ]; then
      echo "::error::Expected FunctionError=Unhandled, got: $FUNCTION_ERROR"
      exit 1
    fi
    if echo "$LOG_TAIL" | grep -qF "$EXPECTED_SUBSTR"; then
      echo "Log contains expected string"
    else
      echo "::error::Log does not contain expected string for $TEST_NAME"
      echo "Expected substring: $EXPECTED_SUBSTR"
      echo "Actual log tail: $LOG_TAIL"
      exit 1
    fi
    ;;
  *)
    echo "Unknown assertion type: $ASSERTION" && exit 1
    ;;
esac
