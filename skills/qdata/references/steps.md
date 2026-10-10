# Steps Overview

## Direct SQL Mode directory structure example

```
my_pipeline/
├── 001_load.sql
├── 002_transform.sql
├── 003_validate.sql
└── 004_export.sql
```

Files execute in order. Each step's output automatically feeds into the next.

---

## Step Types (Auto-Detected)

| Pattern                         | Type      | Purpose        |
| ------------------------------- | --------- | -------------- |
| "ingest", "load", or first file | ingest    | Load data      |
| "validate" or "check"           | validate  | Check quality  |
| "export", "sink", or last file  | sink      | Export results |
| Everything else                 | transform | Transform data |

---

## Examples

### Load Data
```sql
-- 001_load.sql
CREATE OR REPLACE TABLE raw_data AS
SELECT * FROM read_csv_auto('./data/input.csv');
```

### Transform Data
```sql
-- 002_transform.sql
CREATE OR REPLACE TABLE cleaned AS
SELECT
  UPPER(name) as name,
  CAST(amount as DECIMAL(10,2)) as amount
FROM raw_data
WHERE amount > 0;
```

### Validate Data
```sql
-- 003_validate.sql
SELECT * FROM cleaned
WHERE id IS NULL OR amount < 0;
```

Returns 0 rows = pass ✓. Returns any rows = fail ✗ and pipeline stops.

### Export Results
```sql
-- 004_export.sql
COPY cleaned TO './output/results.parquet' (FORMAT PARQUET);
```

---

## Skip Feature

Skip files in three ways:

### 1. Rename with `.skip.sql`
```bash
mv 003_slow_validation.sql 003_slow_validation.skip.sql
```

### 2. Add skip comment at the beginning of the file
```sql
-- skip
SELECT * FROM data WHERE id IS NULL;
```

### 3. Resume from specific step
```bash
qdata run --cache cache.db --start-step 3 my_pipeline
```

This skips steps 1-2 and runs from step 3 onward (uses cached intermediate results).

---

## Web Scraping

The [webbed](https://duckdb.org/community_extensions/extensions/webbed) extension is loaded on
every run, so you can parse HTML and XML with XPath. It reads server-rendered HTML only and
does not run JavaScript.

```sql
-- Saved pages, or a list of URLs (read_text fetches http(s) through httpfs)
CREATE OR REPLACE TABLE raw_pages AS
SELECT filename AS url, content::HTML AS body FROM read_text('./pages/*.html');

CREATE OR REPLACE TABLE products AS
SELECT unnest(xpath_all(body, '//article/h3/a/@title'))             AS title,
       abs_url(url, unnest(xpath_all(body, '//article/h3/a/@href'))) AS link
FROM raw_pages;
```

In TOML mode, an `ingest` step with an `https://` source downloads the page, with retries and
optional `user_agent`/`headers`/`retries`, into `(url, status, content_type, fetched_at, body, body_hash)`.

**Crawling (Pro)**: a `type = "scrape"` step fetches many pages into one table
`(url, depth, status, content_type, fetched_at, from_cache, error, body, body_hash)`:

```toml
[[steps]]
name = "crawl"
type = "scrape"
output_table = "raw_pages"
urls = ["https://example.com/list?page={page}"]   # or urls_query = "SELECT url FROM seeds"
pages = { from = 1, to = 20 }
follow = { xpath = "//a[@rel='next']/@href", max_depth = 3, same_host = true }
rate_limit = "2/s"      # per host
concurrency = 2
cache = "12h"           # re-runs reuse fresh pages
respect_robots = true
max_error_pct = 50
```

HTTPS certificates are verified against the system CA bundle (`SSL_CERT_FILE` overrides it); use
`ca_bundle = "/path/ca.pem"` for a private CA or `tls_verify = false` to skip verification.

Helpers: `xpath_all`, `xpath_first`, `page_links`, `abs_url`, `clean_text`. Add more extensions
with `[config] extensions = ["..."]`.

---

## Supported Formats 

Any DuckDB compatible format, for example: CSV, JSON, Parquet, Excel

```sql
-- Read
FROM read_csv_auto('./file.csv')
FROM read_parquet('./file.parquet')
FROM read_excel('./file.xlsx')

-- Write
COPY table TO './output.parquet' (FORMAT PARQUET);
COPY table TO './output.csv' (FORMAT CSV, HEADER TRUE);
COPY table TO './output.xlsx' (HEADER TRUE);
```

---

## Tips

- Files without numbered prefix are ignored
- Use numbered prefixes: `001_`, `002_`, `003_`, etc.
- Filename determines step name (e.g., `001_load.sql` → step "load")
- Each step output is automatically logged and tracked
- Use `--dry-run` to test without writing exports
- Use `--dry-run --preview 10` to see first 10 rows of results
