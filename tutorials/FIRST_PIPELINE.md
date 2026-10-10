# Your First Pipeline

This walkthrough takes you from zero to a working data pipeline in about five minutes. You should already have qData installed. If you haven't done that yet, see the [Releases page](https://github.com/cuiqanalytics/qdata/releases).

Not familiar with the terminal? Read [Terminal Basics](TERMINAL_BASICS.md) first.

---

## Step 1: Create the Demo Project

Open a terminal and run:

```bash
qdata demo
cd demo
```

`qdata demo` creates a folder called `demo` with everything you need to try the tool:

```
demo
├── data/          # Sample input CSV files
├── output/        # Where results are written
└── sql/
    ├── 001_ingest.sql
    ├── 002_transform.sql
    └── 003_validate.sql
```

Each `.sql` file is one pipeline step. The numeric prefix controls execution order — `001` runs first, then `002`, then `003`.

---

## Step 2: Run the Pipeline

```bash
qdata run sql
```

You should see output like this:

```
✓ Ingesting data: ingest...
✓ Transforming: transform...
✓ Sinking data: validate...

✅ Pipeline completed in 399ms
   📊 3/3 steps executed (100%)
   ⏱️  Duration: 399ms
   📈 Total rows processed: 30
```

What each line means:

- The three checkmarks confirm each step ran successfully.
- `3/3 steps executed` means no steps were skipped.
- `Duration` is total wall-clock time.
- `Total rows processed` is the combined row count across all steps.

Results are saved to `output/results.csv`. Open it in any spreadsheet app or text editor.

---

## Step 3: Edit a Step and Re-run

Open `sql/002_transform.sql` in any text editor (Notepad, VSCode, Sublime, etc.).

Find the line that reads:

```sql
  username,
```

Replace it with:

```sql
  UPPER(username) as username_upper,
```

So the relevant part of the file looks like this:

```sql
CREATE OR REPLACE TABLE transform AS
SELECT
  id,
  UPPER(username) as username_upper,
  score,
  signup_date,
  CASE
    WHEN score >= 800 THEN 'platinum'
    WHEN score >= 600 THEN 'gold'
    WHEN score >= 400 THEN 'silver'
    ELSE 'bronze'
  END as tier,
  YEAR(signup_date) as signup_year
FROM ingest
```

`UPPER()` is a standard SQL function that converts text to uppercase. Save the file (make sure the extension stays `.sql`, not `.sql.txt`).

Now re-run:

```bash
qdata run sql
```

Open `output/results.csv` again — the username column is now uppercase.

---

## Step 4: Understanding Step Caching

Run the pipeline a second time without changing anything:

```bash
qdata run sql
```

Notice it is faster. qData hashes the SQL content of each step. When a step's SQL has not changed since the last run, qData skips re-executing it and loads the cached result instead.

In this example:
- `001_ingest.sql` is unchanged — qData skips it and uses the cached table.
- `002_transform.sql` was already re-run after your edit, so it is also cached now.
- `003_validate.sql` is unchanged — also cached.

This matters for real pipelines. If you have a slow ingestion step that pulls from a database, you only pay that cost when the SQL actually changes.

---

## Step 5: Replay from a Specific Step

Suppose you only changed `002_transform.sql` and want to re-run from step 2 onwards, skipping step 1 entirely:

```bash
qdata run --start-step 2 sql
```

qData loads the cached output from step 1 and picks up execution at step 2. This is useful when step 1 is expensive (a large file read or a database query) and you are iterating on the transformation logic.

---

## Next Steps

- Browse the `examples/` directory in this repo for real-world pipeline patterns (multi-source ingestion, date templating, CSV exports, and more).
- Try TOML mode for more control: `qdata init my_project && cd my_project && qdata run pipeline.toml`
- Read the full README for advanced features: caching flags, logging, the background scheduler (Pro), and HTML reports (Pro).
