# bin

Standalone tools. Put this directory on your `PATH` to run them by name.

## substack-mirror

Mirror a Substack publication's posts to Markdown files, one per post, with YAML front matter. Handy for keeping a plain-text, diffable archive of a newsletter in git.

It uses Substack's public, undocumented JSON endpoints, so no login is needed for public posts:
- `/api/v1/archive?sort=new&offset=N&limit=50` lists the posts.
- `/api/v1/posts/<slug>` returns each one, with the text in `body_html`.

Paid-only posts come back truncated, since the tool doesn't log in.

## Requirements

- Python 3.11+ (standard library only)
- [pandoc](https://pandoc.org) 3.x

## Usage

```bash
bin/substack-mirror https://example.substack.com posts/ --dry-run
bin/substack-mirror https://example.substack.com posts/
```

| Option | What it does |
|---|---|
| `--dry-run` | Report `new` and `changed` posts without writing anything |
| `--only SLUG …` | Limit to these slugs |
| `--cache DIR` | Save each post's raw JSON in `DIR` |

- A file is rewritten only when the post's front matter (other than `fetched`) or its body has changed, so `fetched` records when a change was last picked up.
- Requests are paced 1.5 s apart, and a 429 is retried with backoff (Substack rate-limits after about 30 quick calls).
- It never deletes files. A post that's unpublished or renamed on Substack stays until you remove it.

## Output

```yaml
---
title: "My Post"
subtitle: "…"
slug: "my-post"
url: "https://example.substack.com/p/my-post"
published: "2026-01-04T15:00:00.000Z"
updated: "2026-01-05T09:30:00.000Z"
wordcount: 1200
audience: "everyone"
source: "Substack API /api/v1/posts/my-post (body_html converted with pandoc)"
fetched: "2026-01-05"
---
```

The body is GitHub-flavored Markdown, converted with `pandoc -f html -t gfm --wrap=none --lua-filter substack.lua` (the filter lives next to the script). The filter:
- turns YouTube, Vimeo, TikTok and Instagram embeds and embedded Substack posts into `▶` link lines, built from each widget's `data-attrs`;
- turns captioned images into plain images and drops inline SVG icons;
- turns pull quotes into blockquotes;
- drops subscribe widgets and buttons;
- keeps colored and highlighted text as raw `<span style="…">` HTML and unwraps spans that have no attributes.
