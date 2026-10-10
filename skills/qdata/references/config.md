# Pipeline Configuration Reference

## Pipeline Structure

A pipeline is defined in **TOML** format with metadata and steps.

### Prefer Direct SQL?

For simple pipelines, consider using **direct SQL** with numbered files (`001_*.sql`, `002_*.sql`) instead of TOML. See `qdata docs tutorial` for the quickest way to get started.

### Building Visually?

The **Visual Pipeline Editor** in `qdata server` (premium feature) generates TOML automatically from a visual interface, making configuration easier without manual TOML editing.

```toml
[pipeline]
name = string             # Required: Pipeline name (unique)
description = string      # Optional: What this pipeline does
schedule = string         # Optional: Cron expression (e.g., "0 8 * * *")
timeout_minutes = int     # Optional: Execution timeout (default: 120)
version = int             # Optional: Pipeline version (default: 1)
```

## Example Pipeline Definition

```toml
[pipeline]
name = "daily_sync"
description = "Sync data from CSV to warehouse daily"
schedule = "0 8 * * *"
timeout_minutes = 60
```

## Steps

Pipelines consist of multiple steps executed in order. Each step must have:

- **name** - Step identifier (string)
- **type** - Type: ingest, transform, validate, or sink
- **resource_uri** - Data source/destination path (via `source` or `destination`)
- **query** - SQL query (for transform/validate/sink)

## Step Configuration

```toml
[[steps]]
name = "load_data"
type = "ingest"
source = "./data/input.csv"
output_table = "raw_data"

[[steps]]
name = "clean_data"
type = "transform"
input_table = "raw_data"
output_table = "cleaned_data"
query = """
  SELECT
    id,
    name,
    UPPER(status) as status
  FROM raw_data
  WHERE id IS NOT NULL
"""

[[steps]]
name = "export"
type = "sink"
input_table = "cleaned_data"
destination = "./output/results_{{YYYYMMDD}}.parquet"
```

## Step Type Reference

- **ingest** - Load data from external source (CSV, JSON, Parquet)
- **transform** - Transform using SQL queries
- **validate** - Check data quality with validation queries
- **sink** - Export results to file/database

## Supported File Formats

- **Input**: CSV, JSON, Parquet, ORC, Excel
- **Output**: CSV, JSON, Parquet, ORC, DuckDB database

## Template Variables

Use `{{VARIABLE}}` syntax in paths and queries:

- `{{YYYYMMDD}}` - Current date (e.g., 20251208)
- `{{PIPELINE_NAME}}` - Pipeline name
- `{{RUN_ID}}` - Unique run identifier
- `{{ENV:VAR_NAME}}` - Environment variable

See `cuiq docs templating` for complete list.

## Example: Daily Export with Date

```toml
[pipeline]
name = "daily_export"

[[steps]]
name = "export"
type = "sink"
input_table = "results"
destination = "./output/daily_{{YYYYMMDD}}.parquet"
```

Result: `./output/daily_20251208.parquet`

## Example: Environment-Based Paths

```toml
[pipeline]
name = "warehouse_sync"

[[steps]]
name = "export_to_lake"
type = "sink"
input_table = "data"
destination = "{{ENV:DATA_LAKE}}/{{YYYY}}/{{MM}}/data.parquet"
```

Requires: `export DATA_LAKE=/mnt/data-warehouse`

## Shorthand: Direct SQL Pipelines

For pipelines that don't need scheduling or advanced features, you don't need TOML at all. Create a directory with numbered SQL files and qData will auto-detect and run them:

```bash
my_pipeline/
├── 001_load.sql
├── 002_transform.sql
└── 003_export.sql
```

Run: `qdata run my_pipeline`

See `qdata docs tutorial` for examples.
