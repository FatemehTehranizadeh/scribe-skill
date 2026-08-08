#!/usr/bin/env bash
# ponytail: confluence export with macros, image uploads, and parent-child hierarchy support.
set -euo pipefail

FILE="${1:-}"
SPACE_KEY="${2:-}"
PARENT_ID="${3:-}"

if [[ -z "$FILE" || ! -f "$FILE" || -z "$SPACE_KEY" ]]; then
  echo "Usage: $0 <path-to-markdown-file> <space-key> [parent-page-id]"
  exit 1
fi

if [[ -z "${CONFLUENCE_URL:-}" || -z "${CONFLUENCE_PAT:-}" ]]; then
  echo "Error: Please set CONFLUENCE_URL and CONFLUENCE_PAT environment variables."
  exit 1
fi

TITLE=$(head -n 1 "$FILE" | sed 's/^# *//')
TITLE="${TITLE:-Generated Document $(date +%s)}"

echo "Converting Markdown to HTML..."
RAW_HTML=$(npx --yes marked < "$FILE")

echo "Processing Confluence Macros and Images..."
# Use an inline python script to convert blockquotes to Confluence macros and extract image paths
cat << 'EOF' > process_html.py
import sys, re

html = sys.stdin.read()

# Replace GitHub Alerts with Confluence Macros
pattern = re.compile(r'<blockquote>\s*<p>\[!(INFO|WARNING|ERROR|TIP|CAUTION)\](.*?)</p>\s*</blockquote>', re.DOTALL)
def alert_replacer(match):
    type_map = {'INFO': 'info', 'WARNING': 'warning', 'ERROR': 'error', 'TIP': 'tip', 'CAUTION': 'warning'}
    ac_name = type_map.get(match.group(1), 'info')
    content = re.sub(r'^\s*<br>\s*', '', match.group(2))
    return f'<ac:structured-macro ac:name="{ac_name}"><ac:rich-text-body><p>{content}</p></ac:rich-text-body></ac:structured-macro>'

html = pattern.sub(alert_replacer, html)

# Extract images and replace with Confluence image macros
image_pattern = re.compile(r'<img\s+[^>]*src="([^"]+)"[^>]*>')
images = image_pattern.findall(html)
with open("images_to_upload.txt", "w") as f:
    for img in images:
        f.write(img + "\n")

def image_replacer(match):
    src = match.group(1)
    filename = src.split("/")[-1]
    return f'<ac:image><ri:attachment ri:filename="{filename}" /></ac:image>'

html = image_pattern.sub(image_replacer, html)

sys.stdout.write(html)
EOF

HTML_CONTENT=$(python3 process_html.py <<< "$RAW_HTML")

# Auth setup
AUTH_HEADER="Authorization: Bearer ${CONFLUENCE_PAT}"
if [[ -n "${CONFLUENCE_EMAIL:-}" ]]; then
  AUTH_B64=$(echo -n "${CONFLUENCE_EMAIL}:${CONFLUENCE_PAT}" | base64)
  AUTH_HEADER="Authorization: Basic ${AUTH_B64}"
fi

# Build Payload
ANCESTORS_JSON=""
if [[ -n "$PARENT_ID" ]]; then
  ANCESTORS_JSON=', "ancestors": [{"id": "'"${PARENT_ID}"'"}]'
fi

PAYLOAD=$(jq -n \
  --arg title "$TITLE" \
  --arg space "$SPACE_KEY" \
  --arg html "$HTML_CONTENT" \
  '{
    type: "page",
    title: $title,
    space: { key: $space },
    body: {
      storage: { value: $html, representation: "storage" }
    }
  }')

# Inject ancestors array if needed
if [[ -n "$PARENT_ID" ]]; then
  PAYLOAD=$(echo "$PAYLOAD" | jq --argjson anc '[{"id": "'"${PARENT_ID}"'"}]' '. + {ancestors: $anc}')
fi

echo "Creating Confluence page '$TITLE' in space '$SPACE_KEY'..."
RESPONSE=$(curl -sS -X POST "${CONFLUENCE_URL}/wiki/rest/api/content" \
  -H "${AUTH_HEADER}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

PAGE_ID=$(echo "$RESPONSE" | jq -r '.id // empty')

if [[ -z "$PAGE_ID" ]]; then
  echo "Failed to create page. Response:"
  echo "$RESPONSE" | jq .
  exit 1
fi

echo "Successfully created page! Page ID: $PAGE_ID"

# Upload attachments
if [[ -f "images_to_upload.txt" ]]; then
  while read -r IMG_PATH; do
    if [[ -n "$IMG_PATH" && -f "$IMG_PATH" ]]; then
      echo "Uploading attachment: $IMG_PATH"
      curl -sS -X POST "${CONFLUENCE_URL}/wiki/rest/api/content/${PAGE_ID}/child/attachment" \
        -H "${AUTH_HEADER}" \
        -H "X-Atlassian-Token: nocheck" \
        -F "file=@${IMG_PATH}" > /dev/null
    else
      echo "Warning: Image not found at path '$IMG_PATH', skipping attachment upload."
    fi
  done < images_to_upload.txt
fi

# Cleanup
rm -f process_html.py images_to_upload.txt

echo
echo "Done! The Page ID is: $PAGE_ID"
