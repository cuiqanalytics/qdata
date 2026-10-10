---
name: qdata
description: Use when the user wants a local SQL data pipeline — load CSV/Parquet/JSON/Excel or a MySQL/Postgres table, transform it, validate it and export it — or wants to scrape a website into a table (one page or a paginated/linked crawl, parsed with XPath), schedule a pipeline with cron, or mentions qdata, `qdata run`, a `pipeline.toml`, or a folder of numbered `.sql` files (`001_ingest.sql`, `002_transform.sql`).
---

# Building pipelines with qdata

qdata runs SQL pipelines on an embedded DuckDB engine. It ships as a single Linux binary or as the `ghcr.io/cuiqanalytics/qdata` Docker image. Each step's output becomes a DuckDB table that later steps can query. Every run is logged to `logs.db`, and `--cache cache.db` lets you replay a run from any step.

## Pick the mode first

| User wants | Use |
|---|---|
| Plain SQL steps over files | **SQL mode**: a folder of numbered `.sql` files, run with `qdata run <dir>` |
| HTTP fetch, a crawl, DB connectors, declarative ingest/sink | **TOML mode**: `pipeline.toml`, run with `qdata run pipeline.toml` |
| A quick look at a file or a query | `qdata exec "SELECT ... FROM 'file.csv'"` |

Prefer SQL mode unless a TOML-only feature is needed.

## SQL mode

- Files run in numeric order. Files without a number prefix are ignored, and a `.skip.sql` suffix skips a file.
- The step type is inferred from the file name:
  - a name containing `ingest` or `load`, or the first file → **ingest**
  - a name containing `validate` or `check` → **validate**
  - a name containing `export` or `sink`, or the last file → **sink**
  - anything else → **transform**
- Ingest and transform files must contain `CREATE OR REPLACE TABLE <name> AS ...`.
- A validate file is a `SELECT` that returns the *bad* rows. If it returns any rows, the step fails.
- Sink files use `COPY <table> TO './output/x.parquet' (FORMAT PARQUET);`.

## TOML mode

```toml
[config]
project_name = "orders"
extensions = ["spatial"]          # optional extra DuckDB extensions (free tier: allowlist only)

[pipeline]
name = "orders_daily"

[[steps]]
name = "load"
type = "ingest"                   # ingest | transform | validate | sink | scrape
source = "./data/orders.csv"      # file, https:// URL, or mysql:// / postgres:// URI
output_table = "orders"

[[steps]]
name = "clean"
type = "transform"
output_table = "orders_clean"
query = """
CREATE OR REPLACE TABLE orders_clean AS
SELECT * FROM orders WHERE amount > 0
"""

[[steps]]
name = "export"
type = "sink"                     # writes the previous step's table
destination = "./output/orders_{{YYYYMMDD}}.parquet"
```

- A transform `query` must create its own `output_table`. A bare `SELECT` fails.
- A sink always writes the table from the step right before it, so order the steps accordingly.
- Template variables work in paths and SQL: `{{YYYYMMDD}}`, `{{date_sub(YYYYMMDD, 7)}}`, `{{RUN_ID}}` and env vars. See `references/templating.md`.

## Web scraping

[webbed](https://duckdb.org/community_extensions/extensions/webbed) is loaded on every run, so HTML and XML are parsed with **XPath 1.0** in SQL. Only server-rendered pages are supported. If the data is built by JavaScript, look in the browser's network tab for the site's JSON API and ingest that instead.

**One page (free):**

```toml
[[steps]]
name = "fetch"
type = "ingest"
source = "https://example.com/products"
output_table = "raw_page"   # url, status, content_type, fetched_at, body (HTML), body_hash
user_agent = "my-team-bot (+mailto:me@example.com)"
```

A JSON, CSV or Parquet URL loads as a normal table instead. HTTPS certificates are verified against the system CA bundle. On a certificate error, `ca_bundle = "/path/ca.pem"` trusts a private CA; suggest `tls_verify = false` only when the user accepts skipping verification.

**Many pages (Pro):** use a `type = "scrape"` step. It produces `url, depth, status, content_type, fetched_at, from_cache, error, body, body_hash`.

```toml
[[steps]]
name = "crawl"
type = "scrape"
output_table = "raw_pages"
urls = ["https://example.com/list?page={page}"]   # or urls_query = "SELECT url FROM seeds"
pages = { from = 1, to = 20 }
follow = { xpath = "//a[@rel='next']/@href", max_depth = 3, same_host = true }
rate_limit = "2/s"
concurrency = 2
cache = "12h"
max_error_pct = 20
```

**Extract** in a transform. One row per match comes from `unnest`:

```sql
CREATE OR REPLACE TABLE items AS
SELECT unnest(xpath_all(body, '//div[@class="card"]/h2'))                 AS title,
       abs_url(url, unnest(xpath_all(body, '//div[@class="card"]/a/@href'))) AS link
FROM raw_pages WHERE status = 200;
```

Helpers:
- `xpath_all(html, xp)` returns a list.
- `xpath_first(html, xp)` returns the cleaned first match.
- `page_links(html)` returns a list of `{text, href, title, line_number}`.
- `abs_url(page_url, href)` and `clean_text(s)`.

Raw webbed functions also work: `html_extract_tables(body)`, `html_extract_images`, `xml_extract_text(xml, xp)`, `read_html('pages/*.html')`, `read_xml`.

When the cards are repeated blocks, unnest parallel lists only if each card always has every field. Otherwise the lists misalign. In that case extract per card instead, with an XPath that indexes the card (`(//div[@class="card"])[1]/h2`), or extract the card fragments with `html_extract_text` on `//div[@class="card"]` and parse each one.

## Workflow

1. Write the pipeline, then run it with `qdata run --dry-run --preview 5 <dir|file.toml>` to see outputs without writing exports. **Flags must come before the path**; flags after it are silently ignored.
2. Read the actual error (they include a 💡 Fix line) and iterate. After fixing one step, `qdata run --cache cache.db --start-step N x` resumes there. The first run needs `--cache cache.db` too.
3. Check the result: `qdata exec "SUMMARIZE FROM 'output/x.parquet'"`.
4. For scrapers, add a validate step so layout changes fail loudly, for example a SQL file that returns rows where the extracted field is NULL.

## Free vs Pro

| | Free | Pro |
|---|---|---|
| SQL/TOML pipelines, caching, replay, webbed, single-URL fetch, MySQL/Postgres, HTML reports | ✓ | ✓ |
| Row cap on validate/exec previews | 100k | — |
| `scrape` crawl step, scheduler (`qdata server start`, `schedule add`, `run --scheduler`), any DuckDB extension | — | ✓ |

The free tier also caps DuckDB at 2 threads and 2 GB and rejects recursive or very complex queries. If a request needs Pro, say so in one sentence and offer the free route when one exists, such as a list of single-page ingest steps instead of a crawl.

## Scraping etiquette

Set a `user_agent` that identifies the user, leave `respect_robots = true`, keep `rate_limit` modest, and use `cache` while iterating on extraction so the site isn't re-fetched. Remind the user to check the site's terms of use.
