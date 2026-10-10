# Web scraping

qdata fetches pages and the [webbed](https://duckdb.org/community_extensions/extensions/webbed)
DuckDB extension parses them with XPath, so a scraper is just SQL. webbed is loaded on every
run, free tier included. It reads server-rendered HTML; pages that build their content with
JavaScript are not supported.

## Offline: saved pages (SQL mode)

```bash
qdata run sql
cat sql/output/products.csv
```

`001_ingest_pages.sql` loads `pages/*.html` with `read_text`, and the following steps extract,
validate and export.

## Live: one page (TOML mode)

```bash
qdata run books.toml
```

A TOML `ingest` step with an `https://` source downloads the page (with `user_agent`, `headers`,
`retries`, `tls_verify` and `ca_bundle` options; certificates are verified by default) into a table with columns `url, status, content_type, fetched_at, body,
body_hash`. JSON, CSV and Parquet responses load as regular tables instead.

## Crawl: many pages (TOML mode, Pro)

```bash
qdata run books_crawl.toml
```

A `type = "scrape"` step takes seed URLs (`urls`, `{page}` with `pages = { from, to }`, or
`urls_query`) and optionally follows links matched by an XPath (`follow`). It respects
robots.txt, rate-limits each host, fetches `concurrency` pages at a time, and keeps 2xx pages
in a cache (`cache = "12h"`) so re-runs skip the network. Failed pages become rows with an
`error`; the step fails only above `max_error_pct`.

## Helpers

| Macro | What it does |
| --- | --- |
| `xpath_all(html, xpath)` | every match, as a list (`unnest` it for one row per match) |
| `xpath_first(html, xpath)` | first match, whitespace-cleaned |
| `page_links(html)` | `html_extract_links`: list of `{text, href, title, line_number}` |
| `abs_url(page_url, href)` | resolve a relative link |
| `clean_text(s)` | collapse whitespace and `&nbsp;`, `''` → NULL |

Everything else from webbed works too: `html_extract_tables`, `html_extract_images`,
`read_html`, `xml_extract_text`, `read_xml`.

Be a good citizen: identify yourself in `user_agent`, check the site's terms and robots.txt.
