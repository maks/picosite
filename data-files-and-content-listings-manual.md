# Picosite Data files and content listings Usage Guide

This document describes the new features added to Picosite to allow using structured data files and content listings.

## 1. JSON Data File Access (`_data`)

JSON files in the `site/data/` directory are automatically loaded and accessible in templates via `{{_data.filename.key}}`.

### Setup

Create a JSON file in `site/data/`:
```
site/data/
└── talks.json
```

With contents like:
```json
{
  "items": [
    {
      "title": "My Talk",
      "date": "2024-09-15",
      "url": "https://example.com"
    }
  ],
  "name": "My site name"
}
```

### Usage in Templates

```html
<!-- Access top-level keys -->
<p>Sitename: {{_data.talks.name}}</p>

<!-- Access array elements -->
{{#_data.talks.items}}
  <li>{{ title }} ({{#_data.talks}}{{@index}}{{/ _data.talks}})</li>
{{/_data.talks.items}}
```

## 2. Content Listings (`_lists`)

YAML files in `_listings/` define collections of content files that can be iterated in templates.

### Setup

Create a YAML file in `_listings/`:
```
_listings/
└── blog_posts.yaml
```

With contents like:
```yaml
path: "site/pages/blog/posts"
filter: "*.md"
sort_by: date DESC
```

### Supported Config Fields

- `path`: Directory to scan for content files (relative to CWD)
- `filter`: Glob pattern to match files (e.g., `*.md`)
- `sort_by`: Field to sort by, optionally with direction (e.g., `date DESC`)

### Usage in Templates

```html
<h2>Blog Posts</h2>
<ol>
{{#_lists.blog_posts}}
  <li>
    <a href="/blog/{{title}}.html">{{ title }}</a>
    - {{ date_iso }} ({{ date_long }})
  </li>
{{/_lists.blog_posts}}
</ol>
```

### Automatic Date Formatting

Listing items with a `date` field in their frontmatter automatically get:
- `date_iso`: ISO format (e.g., `2024-09-15`)
- `date_long`: Long format (e.g., `September 15, 2024`)

## 3. Date Formatting (per-page)

Pages with `date` in their frontmatter automatically get:
- `date_iso`
- `date_long`

### Example Frontmatter

```yaml
---
title: "My Post"
date: 2024-09-15
---
```

### Usage

```html
<h1>{{ title }}</h1>
<p>Published: {{ date_long }}</p>
```

## Test Site

A test site is available in `picosite-test/` demonstrating all features:
- `picosite-test/site/data/test.json` — Test JSON data
- `picosite-test/_listings/blog_posts.yaml` — Test listing config 
- `picosite-test/site/pages/posts/` — Test blog posts
- `picosite-test/site/templates/test_list.html` — Test template

Run test:
```bash
dart run picosite/bin/picosite.dart -s picosite-test/site -o picosite-test/output
```
