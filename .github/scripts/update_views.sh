#!/usr/bin/env bash
set -euo pipefail

TRACKING_FILE=".github/view-tracking.json"
README_FILE="README.md"
TODAY=$(date -u +%Y-%m-%d)

# --- 1. Make sure the tracking file exists ---
if [ ! -f "$TRACKING_FILE" ]; then
  echo '{"total": 0, "processedDates": {}}' > "$TRACKING_FILE"
fi

# --- 2. Call the GitHub Traffic API (last 14 days of daily view counts) ---
RESPONSE=$(curl -s \
  -H "Authorization: token ${TRAFFIC_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${REPO}/traffic/views")

if ! echo "$RESPONSE" | jq -e '.views' > /dev/null 2>&1; then
  echo "Traffic API did not return expected data. Response was:"
  echo "$RESPONSE"
  exit 1
fi

# --- 3. Add any completed day we haven't counted yet ---
CURRENT_TOTAL=$(jq -r '.total' "$TRACKING_FILE")

NEW_TRACKING=$(jq -n \
  --argjson current "$(cat "$TRACKING_FILE")" \
  --argjson views "$(echo "$RESPONSE" | jq '.views')" \
  --arg today "$TODAY" \
  '
  reduce $views[] as $day (
    $current;
    if ($day.timestamp | startswith($today)) then
      .   # skip today — it is not a completed day yet
    elif (.processedDates[$day.timestamp] // false) then
      .   # already counted this day
    else
      .total += $day.count
      | .processedDates[$day.timestamp] = true
    end
  )
  ')

echo "$NEW_TRACKING" > "$TRACKING_FILE"
FINAL_TOTAL=$(echo "$NEW_TRACKING" | jq -r '.total')

echo "Real cumulative profile views: $FINAL_TOTAL"

# --- 4. Update the badge in README.md between the markers ---
BADGE_URL="https://img.shields.io/badge/Real%20Profile%20Views-${FINAL_TOTAL}-0ea5e9?style=for-the-badge"
BADGE_LINE="<img src=\"${BADGE_URL}\" alt=\"real profile views\"/>"

python3 - "$README_FILE" "$BADGE_LINE" << 'PYEOF'
import re, sys

readme_path, badge_line = sys.argv[1], sys.argv[2]
with open(readme_path, "r", encoding="utf-8") as f:
    content = f.read()

pattern = re.compile(
    r"(<!--VIEWS-START-->)(.*?)(<!--VIEWS-END-->)",
    re.DOTALL,
)
replacement = r"\1\n" + badge_line.replace("\\", "\\\\") + r"\n\3"

if pattern.search(content):
    content = pattern.sub(replacement, content)
else:
    print("WARNING: VIEWS-START/VIEWS-END markers not found in README.md")

with open(readme_path, "w", encoding="utf-8") as f:
    f.write(content)
PYEOF

echo "README updated."
