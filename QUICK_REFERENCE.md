# qdata quick reference

## Commands

| Command | What it does |
|---|---|
| `qdata demo` | Create a `demo/` project with sample data |
| `qdata init <name>` | Scaffold a project with a template pipeline and docs |
| `qdata run <dir\|file.toml>` | Run a pipeline |
| `qdata exec "<sql>" [dir]` | Run ad-hoc SQL, against `dir/cache.db` when present |
| `qdata docs` | Built-in documentation |
| `qdata report <pipeline>` | HTML run report |
| `qdata server start` / `stop` | Background scheduler, REST API and browser UI (`/ui`) on 127.0.0.1:5000 (Pro) |
| `qdata schedule add\|list\|remove\|update` | Cron schedules (Pro) |
| `qdata license install <KEY>` / `status` | Manage the license |

### `run` flags

Flags go **before** the pipeline path: `qdata run --dry-run --preview 5 my_pipeline`.

| Flag | Meaning |
|---|---|
| `-d, --dry-run` | Execute queries but skip writes |
| `-p, --preview N` | With `--dry-run`, show N rows per step |
| `-c, --cache FILE` | Keep step outputs in a DuckDB file |
| `-s, --start-step N` | Replay from step N (needs `--cache`) |
| `--list-steps` | Show steps of the latest run |
| `--scheduler now\|"<cron>"` | Queue to the scheduler (Pro) |

## SQL mode

Numbered files (`001_*.sql`, `002_*.sql`, …) run in order. Type comes from the name:
`ingest`/`load`/first file → ingest, `validate`/`check` → validate (returning any rows fails it),
`export`/`sink`/last file → sink, everything else → transform. `x.skip.sql` is skipped.

## TOML mode

| Step `type` | Keys |
|---|---|
| `ingest` | `source` (path, `https://` URL, `mysql://` / `postgres://` URI), `output_table`, `source_fields`; for URLs: `user_agent`, `headers`, `retries`, `tls_verify`, `ca_bundle` |
| `transform` | `output_table`, `query` (must `CREATE OR REPLACE TABLE`), or `transforms = [{field, fn}]` |
| `validate` | `query` returning failing rows |
| `sink` | `destination` (format from extension, or a DB URI); writes the previous step's table |
| `scrape` (Pro) | `urls` / `urls_query`, `pages = {from, to}`, `follow = {xpath, max_depth, same_host}`, `max_pages`, `rate_limit`, `concurrency`, `respect_robots`, `cache`, `max_error_pct`, `user_agent`, `headers`, `retries`, `tls_verify`, `ca_bundle` |

HTTPS certificates are verified against the system CA bundle (`$SSL_CERT_FILE`, or the usual
`/etc/ssl/...` locations). Set `ca_bundle = "/path/ca.pem"` for a private CA, or `tls_verify = false`
to skip verification.

`[config]` keys: `project_name`, `db_path` (run log, default `./logs.db`), `extensions`.

## Scraping helpers

| Function | Returns |
|---|---|
| `xpath_all(html, xpath)` | `VARCHAR[]` of all matches |
| `xpath_first(html, xpath)` | first match, whitespace-cleaned |
| `page_links(html)` | `[{text, href, title, line_number}]` |
| `abs_url(page_url, href)` | absolute URL |
| `clean_text(s)` | trimmed text, `&nbsp;` and runs of whitespace collapsed, empty → NULL |
| `html_extract_tables(html)`, `html_extract_images(html)`, `read_html(glob)`, `xml_extract_text(xml, xpath)`, `read_xml(glob)` | webbed built-ins |

## Template variables

`{{YYYYMMDD}}`, `{{YYYY}}`, `{{MM}}`, `{{DD}}`, `{{HHMMSS}}`, `{{TIMESTAMP}}`, `{{ISO8601}}`,
`{{YESTERDAY_YYYYMMDD}}`, `{{date_sub(YYYYMMDD, 7)}}`, `{{date_add(YYYY-MM-01, 1, months)}}`,
`{{RUN_ID}}`, `{{PIPELINE_NAME}}`, `{{STEP_NAME}}`, and environment variables.
