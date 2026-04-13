# Blog Articles

Technical articles on software engineering, cloud architecture, and AI/ML.

## Structure

```
articles/     # Markdown articles with front matter
images/       # Shared images and diagrams
publish.sh    # CLI tool for cross-platform publishing
```

## Publishing

### Automated (GitHub Actions)

Pushing a new or changed article to `articles/` on the `main` branch triggers the dev.to workflow. Articles are created as **drafts** by default — review and publish them from the dev.to dashboard.

Required secret: `DEVTO_API_KEY` (set in repo Settings > Secrets).

### Manual (CLI)

```bash
# Publish as draft to dev.to
DEVTO_API_KEY=your_key ./publish.sh articles/11-introducing-feature-bacon.md --platform devto

# Publish immediately
DEVTO_API_KEY=your_key ./publish.sh articles/11-introducing-feature-bacon.md --platform devto --publish

# Dry run (print payload without sending)
./publish.sh articles/11-introducing-feature-bacon.md --platform devto --dry-run

# Publish to all platforms
DEVTO_API_KEY=your_key HASHNODE_TOKEN=your_token HASHNODE_PUB_ID=your_id \
  ./publish.sh articles/11-introducing-feature-bacon.md --platform all --publish
```

### Supported platforms

| Platform | Env vars needed | Status |
|----------|----------------|--------|
| **dev.to** | `DEVTO_API_KEY` | Ready |
| **Hashnode** | `HASHNODE_TOKEN`, `HASHNODE_PUB_ID` | Ready |
| **Medium** | N/A | Manual (API tokens discontinued) |

## Front matter format

Each article uses YAML front matter compatible with multiple platforms:

```yaml
---
title: "Article Title"
tags: "tag1, tag2, tag3"
canonical_url: ""
cover_image: ""
published: false
series: ""
---
```
