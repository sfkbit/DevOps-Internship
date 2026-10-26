
#!/usr/bin/env bash

set -u

PROJECT_DIR="$(cd "$(dirname "$0")/../terraform" && pwd)"
PROOF_DIR="$(cd "$(dirname "$0")/../proof" && pwd)"
REPORT="$PROOF_DIR/drift-report.txt"

cd "$PROJECT_DIR" || exit 1

echo "Checking Terraform infrastructure..."

terraform plan -detailed-exitcode -no-color > "$REPORT" 2>&1
RESULT=$?

case "$RESULT" in
  0)
    echo "No changes detected."
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

HTTP_CODE=$(curl -sS -o "$PROOF_DIR/webhook-response.txt" \
  -w "%{http_code}" \
  -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD") || {
    echo "ERROR: Failed to send webhook request."
    exit 1
  }

if [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
  echo "Webhook alert sent successfully (HTTP $HTTP_CODE)."
  echo "Check webhook.site to view the request."
else
  echo "ERROR: Webhook returned HTTP $HTTP_CODE."
  cat "$PROOF_DIR/webhook-response.txt"
  exit 1
fi

