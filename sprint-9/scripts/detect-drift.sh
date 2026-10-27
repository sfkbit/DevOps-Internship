
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

# Terraform exit codes:
# 0 = no changes
# 1 = error
# 2 = changes detected

set +e
terraform plan -input=false -detailed-exitcode -no-color \
  -out="$PLAN" > "$REPORT" 2>&1
RESULT=$?
set -e

if [ "$RESULT" -eq 1 ]; then
  echo "ERROR: Terraform plan failed."
  cat "$REPORT"
  exit 1
fi

if [ "$RESULT" -eq 0 ]; then
  echo "No changes detected."
  cat "$REPORT"
  exit 0
fi

if [ "$RESULT" -ne 2 ]; then
  echo "ERROR: Unexpected Terraform exit code: $RESULT"
  cat "$REPORT"
  exit 1
fi

# Convert the saved plan to JSON so resource changes can be counted.
if ! terraform show -json "$PLAN" > "$JSON_PLAN"; then
  echo "ERROR: Could not read the Terraform plan."
  exit 1
fi

CHANGES=$(python3 -c '
import json
import sys

with open(sys.argv[1], encoding="utf-8") as file:
    plan = json.load(file)

changes = [
    resource
    for resource in plan.get("resource_changes", [])
    if resource.get("change", {}).get("actions") != ["no-op"]
]

print(len(changes))
' "$JSON_PLAN") || {
  echo "ERROR: Could not count resource changes."
  exit 1
}

echo "Terraform exit code: $RESULT (changes detected)"
echo "Resources with proposed changes: $CHANGES"

if [ "$CHANGES" -eq 0 ]; then
  echo "ERROR: Exit code 2 but no resource changes were found."
  exit 1
fi

echo "Changes detected. Preparing webhook alert..."
cat "$REPORT"

if [ -z "${WEBHOOK_URL:-}" ]; then
  echo "ERROR: WEBHOOK_URL is not set."
  exit 1
fi

PAYLOAD=$(python3 -c '
import json
import pathlib
import sys

report = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")

print(json.dumps({
    "project": "sprint-9",
    "event": "terraform_changes_detected",
    "terraform_exit_code": 2,
    "resources_with_changes": int(sys.argv[2]),
    "report": report
}))
' "$REPORT" "$CHANGES") || {
  echo "ERROR: Could not prepare webhook payload."
  exit 1
}

HTTP_CODE=$(curl -sS --connect-timeout 10 --max-time 30 \
  -o "$RESPONSE" \
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

