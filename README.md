# qdata

**SQL pipelines on your laptop. Scrape, transform, validate, export.**

`qdata` runs a folder of numbered SQL files, or a `pipeline.toml`, as a pipeline on an embedded
DuckDB engine. Each step is cached and logged, so after a fix you re-run from that step instead of
from the start. It can also fetch web pages and crawl sites, then parse them with XPath in plain
SQL. There is no Airflow, no Python environment and no server.

```bash
qdata demo && qdata run demo/sql
```

---

## Install

**Linux (x86_64):**

```bash
curl -fsSL https://cuiqanalytics.github.io/qdata/install.sh | sh
```

No root is needed. It unpacks to `~/.local/lib/qdata` and links `qdata` at
`~/.local/bin/qdata`. Re-run it to upgrade in place.

To install by hand instead:

```bash
curl -fsSL https://github.com/cuiqanalytics/qdata/releases/latest/download/qdata-cli-linux-x86_64.tar.gz | tar xz
cd qdata-cli-linux-x86_64
./qdata --version
```

`./qdata` is a small launcher that points the binary at the bundled DuckDB and SQLite
libraries. **Run the launcher, not `bin/qdata`**, and keep `bin/` and `extensions/` together.
The DuckDB extensions (webbed, excel, mysql, postgres, httpfs and others) ship in the tarball,
so pipelines run offline.

---

## Docker

**This is how to run qdata on macOS and Windows.**

```bash
docker pull ghcr.io/cuiqanalytics/qdata
docker run --rm -v "$PWD:/work" ghcr.io/cuiqanalytics/qdata run my_pipeline
```

A shell function makes it feel native:

```bash
qdata() { docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" ghcr.io/cuiqanalytics/qdata "$@"; }
```

- **Apple Silicon (M1–M4):** the image is `linux/amd64`, so add `--platform linux/amd64`.
- **Pro license:** add `-v ~/.cuiq:/home/qdata/.cuiq:ro`.
- **Scheduler and API:** run `docker run -d -p 5000:5000 -v "$PWD:/work" -v ~/.cuiq:/home/qdata/.cuiq:ro ghcr.io/cuiqanalytics/qdata scheduler 0.0.0.0 5000`. The browser UI is then at http://localhost:5000/ui.

---

## Quickstart

```
my_pipeline/
├── 001_ingest.sql       CREATE OR REPLACE TABLE orders AS SELECT * FROM read_csv('data/orders.csv');
├── 002_clean.sql        CREATE OR REPLACE TABLE clean AS SELECT * FROM orders WHERE amount > 0;
├── 003_validate.sql     SELECT * FROM clean WHERE customer_id IS NULL;   -- any row fails the run
└── 004_export.sql       COPY clean TO 'output/clean.parquet' (FORMAT PARQUET);
```

```bash
qdata run my_pipeline                                  # run it
qdata run --dry-run --preview 5 my_pipeline            # look before you write
qdata run --cache cache.db --start-step 3 my_pipeline  # replay from step 3
qdata exec "SUMMARIZE FROM 'my_pipeline/output/clean.parquet'"
```

**Flags go before the pipeline path** (`qdata run --dry-run x`, not `qdata run x --dry-run`).

Need HTTP fetches, database connectors or a crawl? Use a TOML pipeline. See
**[QUICK_REFERENCE.md](QUICK_REFERENCE.md)**.

---

## Scrape a website

The [webbed](https://duckdb.org/community_extensions/extensions/webbed) extension is loaded on
every run, so you can parse HTML with XPath right in SQL.

```toml
[[steps]]
name = "crawl"
type = "scrape"                     # Pro; a single page is free with type = "ingest"
output_table = "raw_pages"
urls = ["https://books.toscrape.com/catalogue/page-1.html"]
follow = { xpath = "//li[@class='next']/a/@href", max_depth = 4 }
rate_limit = "2/s"
cache = "12h"

[[steps]]
name = "extract"
type = "transform"
output_table = "books"
query = """
CREATE OR REPLACE TABLE books AS
SELECT unnest(xpath_all(body, '//article/h3/a/@title'))                   AS title,
       unnest(xpath_all(body, '//article//p[@class="price_color"]'))      AS price
FROM raw_pages WHERE status = 200
"""
```

The crawler respects robots.txt and rate-limits each host. It retries 429 and 5xx responses
with backoff and caches pages between runs, and a failed page becomes a row with an `error`
instead of aborting the run. It reads server-rendered HTML and does not run JavaScript.
See [`examples/web_scraping`](examples/web_scraping).

---

## Browser UI (Pro)

```bash
qdata server start           # then open http://127.0.0.1:5000/ui
```

Build a pipeline by dragging input, transform, validate and output steps onto a canvas and
writing each step's SQL. Switch to Monitor and press Run to watch each step go from pending to
running, completed or cached. Click a failed step to see the error. Each step is saved as a
numbered `.sql` file in the pipeline folder, so `qdata run` and git work on the same files.

---

## Use it with Claude Code

```bash
./install-skills.sh          # from the unpacked release (or ~/.local/lib/qdata)
```

Then ask: *"scrape the job listings on example.com/careers into a parquet file, every page"*.
Claude writes the pipeline, runs it and checks the output.

## Free and Pro

The CLI is free with no pipeline limits. Pro is $49 one-time and includes a year of updates.
It adds the crawler, the background scheduler, REST API and browser UI, any DuckDB extension, and lifts the
free tier's DuckDB resource caps. Write to rodrigo.abt@gmail.com to buy it.

© 2026 cuiqanalytics. See [LICENSE](LICENSE).
