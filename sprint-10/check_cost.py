import json
import sys
import math

# Read Infracost JSON report
file_path = sys.argv[1] if len(sys.argv) > 1 else "infracost-diff.json"

with open(file_path) as file:
    data = json.load(file)

# Get cost information
baseline = float(data.get("pastTotalMonthlyCost") or 0)
increase = float(data.get("diffTotalMonthlyCost") or 0)
new_total = float(data.get("totalMonthlyCost") or 0)

# Calculate percentage increase
if baseline > 0:
    percentage = (increase / baseline) * 100
else:
    percentage = math.inf if increase > 0 else 0

print("===== INFRACOST COST GATE =====")
print(f"Original monthly cost: ${baseline:.2f}")
print(f"New monthly cost:      ${new_total:.2f}")
print(f"Monthly increase:      ${increase:.2f}")
print(f"Percentage increase:   {percentage:.2f}%")

# Apply thresholds
failed = increase > 100 or percentage > 20

if failed:
    print("\nCOST GATE FAILED!")
    print("Monthly cost increase exceeds the allowed threshold.")
    sys.exit(1)

print("\nCOST GATE PASSED!")
sys.exit(0)
