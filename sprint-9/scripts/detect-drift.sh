
#!/usr/bin/env bash

set -u

PROJECT_DIR="$(cd "$(dirname "$0")/../terraform" && pwd)"
PROOF_DIR="$(cd "$(dirname "$0")/../proof" && pwd)"
REPORT="$PROOF_DIR/drift-report.txt"
RESPONSE="$PROOF_DIR/webhook-response.txt"

mkdir -p "$PROOF_DIR"
rm -f "$REPORT" "$RESPONSE"

cd "$PROJECT_DIR" || exit 1

echo "Checking Terraform infrastructure..."

set +e
terraform plan -detailed-exitcode -no-color > "$REPORT" 2>&1
RESULT=$?
set -e

case "$RESULT" in
  0)
    echo "No changes detected in the current Terraform plan."
    cat "$REPORT"
    exit 0
    ;;
  1)
    echo "ERROR: Terraform plan failed."
    cat "$REPORT"
    exit 1
    ;;
  2)
    echo "Changes detected. Preparing webhook alert..."
    ;;
  *)
    echo "Unexpected Terraform exit code: $RESULT"
    cat "$REPORT"
    exit "$RESULT"
    ;;
esac

if [[ -z "${WEBHOOK_URL:-}" ]]; then
  echo "ERROR: WEBHOOK_URL is not set."
  exit 1
fi

PAYLOAD=$(python3 -c '
import json, pathlib, sys
print(json.dumps({
    "project": "sprint-9",
    "event": "terraform_changes_detected",
    "exit_code": 2,
    "report": pathlib.Path(sys.argv[1]).read_text()
}))
' "$REPORT") || exit 1

HTTP_CODE=$(curl -sS -o "$RESPONSE" \
  -w "%{http_code}" \
  -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD") || {
    echo "ERROR: Failed to send webhook request."
    exit 1
  }

if [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
  echo "Webhook alert sent successfully (HTTP $HTTP_CODE)."
else
  echo "ERROR: Webhook returned HTTP $HTTP_CODE."
  cat "$RESPONSE"
  exit 1
fi

