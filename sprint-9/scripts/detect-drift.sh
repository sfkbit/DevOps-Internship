
#!/usr/bin/env bash

set -u

PROJECT_DIR="$(cd "$(dirname "$0")/../terraform" && pwd)"
PROOF_DIR="$(cd "$(dirname "$0")/../proof" && pwd)"
REPORT="$PROOF_DIR/drift-report.txt"
PLAN="$PROOF_DIR/drift.tfplan"
JSON_PLAN="$PROOF_DIR/drift-plan.json"
RESPONSE="$PROOF_DIR/webhook-response.txt"

mkdir -p "$PROOF_DIR"
rm -f "$REPORT" "$PLAN" "$JSON_PLAN" "$RESPONSE"

cd "$PROJECT_DIR" || exit 1

echo "Checking Terraform infrastructure..."

terraform plan -no-color -out="$PLAN" > "$REPORT" 2>&1
RESULT=$?

if [ "$RESULT" -ne 0 ]; then
  echo "ERROR: Terraform plan failed."
  cat "$REPORT"
  exit 1
fi

terraform show -json "$PLAN" > "$JSON_PLAN" || exit 1

CHANGES=$(python3 -c '
import json, sys
plan = json.load(open(sys.argv[1]))
changes = [
    r for r in plan.get("resource_changes", [])
    if r.get("change", {}).get("actions") != ["no-op"]
]
print(len(changes))
' "$JSON_PLAN") || exit 1

echo "Resources with proposed changes: $CHANGES"

if [ "$CHANGES" -eq 0 ]; then
  echo "No changes detected."
  cat "$REPORT"
  exit 0
fi

echo "Changes detected. Preparing webhook alert..."

cat "$REPORT"

if [[ -z "${WEBHOOK_URL:-}" ]]; then
  echo "ERROR: WEBHOOK_URL is not set."
  exit 1
fi

PAYLOAD=$(python3 -c '
import json, pathlib, sys
print(json.dumps({
    "project": "sprint-9",
    "event": "terraform_changes_detected",
    "resources_with_changes": int(sys.argv[2]),
    "report": pathlib.Path(sys.argv[1]).read_text()
}))
' "$REPORT" "$CHANGES") || exit 1

HTTP_CODE=$(curl -sS --connect-timeout 10 --max-time 30 \
  -o "$RESPONSE" -w "%{http_code}" \
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

