#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTICLES_DIR="$SCRIPT_DIR/articles"
IMAGES_DIR="$SCRIPT_DIR/images"
GITHUB_RAW_BASE="https://raw.githubusercontent.com/orlandoburli/blog-articles/main/images"

usage() {
  cat <<EOF
Usage: $0 <article.md> [--platform devto|hashnode|all] [--publish]

Flags:
  --platform   Target platform (default: devto). Use "all" for every supported platform.
  --publish    Publish immediately instead of creating a draft.
  --dry-run    Print the payload without sending.

Environment variables:
  DEVTO_API_KEY     Required for dev.to publishing.
  HASHNODE_TOKEN    Required for Hashnode publishing.
  HASHNODE_PUB_ID   Required for Hashnode publishing (publication ID).

Examples:
  $0 articles/11-introducing-feature-bacon.md --platform devto
  $0 articles/11-introducing-feature-bacon.md --platform all --publish
EOF
  exit 1
}

parse_front_matter() {
  local file="$1"
  local key="$2"
  sed -n "s/^${key}: *\"\(.*\)\"/\1/p" "$file" | head -1
}

get_body() {
  local file="$1"
  awk '/^---$/{c++; next} c>=2' "$file"
}

rewrite_image_urls() {
  local body="$1"
  echo "$body" | sed "s|\.\./images/|${GITHUB_RAW_BASE}/|g"
}

publish_devto() {
  local file="$1" publish="$2"
  local title tags canonical cover body

  title=$(parse_front_matter "$file" "title")
  tags=$(parse_front_matter "$file" "tags")
  canonical=$(parse_front_matter "$file" "canonical_url")
  cover=$(parse_front_matter "$file" "cover_image")
  body=$(get_body "$file")
  body=$(rewrite_image_urls "$body")

  if [ -z "${DEVTO_API_KEY:-}" ]; then
    echo "Error: DEVTO_API_KEY not set. Get one at https://dev.to/settings/extensions"
    exit 1
  fi

  local published="false"
  [ "$publish" = "true" ] && published="true"

  local json
  json=$(jq -n \
    --arg title "$title" \
    --arg body "$body" \
    --arg tags "$tags" \
    --argjson published "$published" \
    --arg canonical "$canonical" \
    --arg cover "$cover" \
    '{
      article: {
        title: $title,
        body_markdown: $body,
        published: $published,
        tags: ($tags | split(", ")),
        canonical_url: (if $canonical != "" then $canonical else null end),
        main_image: (if $cover != "" then $cover else null end)
      }
    }')

  if [ "${DRY_RUN:-}" = "true" ]; then
    echo "=== dev.to payload ==="
    echo "$json" | jq .
    return
  fi

  local response http_code resp_body
  response=$(curl -s -w "\n%{http_code}" -X POST "https://dev.to/api/articles" \
    -H "Content-Type: application/json" \
    -H "api-key: $DEVTO_API_KEY" \
    -d "$json")

  http_code=$(echo "$response" | tail -1)
  resp_body=$(echo "$response" | sed '$d')

  if [ "$http_code" = "201" ]; then
    local url
    url=$(echo "$resp_body" | jq -r '.url')
    echo "[dev.to] Created (published=$published): $url"
  else
    echo "[dev.to] Failed ($http_code):"
    echo "$resp_body" | jq . 2>/dev/null || echo "$resp_body"
    exit 1
  fi
}

publish_hashnode() {
  local file="$1" publish="$2"
  local title tags body

  title=$(parse_front_matter "$file" "title")
  tags=$(parse_front_matter "$file" "tags")
  body=$(get_body "$file")
  body=$(rewrite_image_urls "$body")

  if [ -z "${HASHNODE_TOKEN:-}" ] || [ -z "${HASHNODE_PUB_ID:-}" ]; then
    echo "Error: HASHNODE_TOKEN and HASHNODE_PUB_ID must be set."
    echo "Get a token at https://hashnode.com/settings/developer"
    exit 1
  fi

  local tags_array
  tags_array=$(echo "$tags" | jq -R 'split(", ") | map({slug: ., name: .})')

  local query
  query=$(jq -n \
    --arg title "$title" \
    --arg body "$body" \
    --arg pubId "$HASHNODE_PUB_ID" \
    --argjson tags "$tags_array" \
    '{
      query: "mutation PublishPost($input: PublishPostInput!) { publishPost(input: $input) { post { url } } }",
      variables: {
        input: {
          title: $title,
          contentMarkdown: $body,
          publicationId: $pubId,
          tags: $tags
        }
      }
    }')

  if [ "${DRY_RUN:-}" = "true" ]; then
    echo "=== Hashnode payload ==="
    echo "$query" | jq .
    return
  fi

  local response
  response=$(curl -s -X POST "https://gql.hashnode.com" \
    -H "Content-Type: application/json" \
    -H "Authorization: $HASHNODE_TOKEN" \
    -d "$query")

  local url
  url=$(echo "$response" | jq -r '.data.publishPost.post.url // empty')

  if [ -n "$url" ]; then
    echo "[hashnode] Published: $url"
  else
    echo "[hashnode] Failed:"
    echo "$response" | jq . 2>/dev/null || echo "$response"
    exit 1
  fi
}

# --- Main ---

[ $# -lt 1 ] && usage

ARTICLE="$1"
shift

PLATFORM="devto"
PUBLISH="false"
DRY_RUN="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --platform) PLATFORM="$2"; shift 2 ;;
    --publish)  PUBLISH="true"; shift ;;
    --dry-run)  DRY_RUN="true"; shift ;;
    *) echo "Unknown flag: $1"; usage ;;
  esac
done

if [ ! -f "$ARTICLE" ]; then
  ARTICLE="$ARTICLES_DIR/$(basename "$ARTICLE")"
fi

if [ ! -f "$ARTICLE" ]; then
  echo "Error: Article not found: $ARTICLE"
  exit 1
fi

echo "Article: $ARTICLE"
echo "Platform: $PLATFORM"
echo "Publish: $PUBLISH"
echo ""

case "$PLATFORM" in
  devto)    publish_devto "$ARTICLE" "$PUBLISH" ;;
  hashnode) publish_hashnode "$ARTICLE" "$PUBLISH" ;;
  all)
    publish_devto "$ARTICLE" "$PUBLISH"
    publish_hashnode "$ARTICLE" "$PUBLISH"
    ;;
  *) echo "Unknown platform: $PLATFORM"; usage ;;
esac
