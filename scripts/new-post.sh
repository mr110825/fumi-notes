#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/new-post.sh <title> [--slug <slug>] [--type tech|idea]

Creates src/content/blog/YYYY-MM-DD-<slug>.md with minimal front matter
(draft: true). Date is taken from `date +%F`.

Options:
  --slug <slug>   Slug for filename (required if title contains non-ASCII).
  --type <type>   "idea" (default) or "tech".
EOF
}

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 1
fi

title=""
slug=""
type="idea"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --slug)
      slug="${2:-}"; shift 2 ;;
    --type)
      type="${2:-}"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    --)
      shift; break ;;
    -*)
      echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *)
      if [[ -z "$title" ]]; then
        title="$1"
      else
        echo "Unexpected argument: $1" >&2; exit 1
      fi
      shift ;;
  esac
done

if [[ -z "$title" ]]; then
  echo "Error: <title> is required." >&2
  usage >&2
  exit 1
fi

if [[ "$type" != "tech" && "$type" != "idea" ]]; then
  echo "Error: --type must be 'tech' or 'idea' (got: $type)" >&2
  exit 1
fi

if [[ -z "$slug" ]]; then
  if [[ "$title" =~ ^[A-Za-z0-9[:space:]_-]+$ ]]; then
    slug=$(echo "$title" \
      | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
  fi
  if [[ -z "$slug" ]]; then
    echo "Error: --slug is required when title contains non-ASCII characters." >&2
    exit 1
  fi
fi

date_str=$(date +%F)

repo_root=$(cd "$(dirname "$0")/.." && pwd)
target="$repo_root/src/content/blog/${date_str}-${slug}.md"

if [[ -e "$target" ]]; then
  echo "Error: file already exists: $target" >&2
  exit 1
fi

cat > "$target" <<EOF
---
title: "${title}"
pubDate: ${date_str}
type: "${type}"
draft: true
---



## 変更履歴

- ${date_str}: 初版公開
EOF

echo "Created: ${target#$repo_root/}"
