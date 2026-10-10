# Template Variables Reference

## Template Syntax

Use `{{VARIABLE_NAME}}` in paths and SQL queries. Variables are substituted at execution time with their current values.

## Date/Time Variables

- `{{YYYYMMDD}}` - Date in YYYYMMDD format. Example: `20251208`
- `{{YYYY}}` - Year. Example: `2025`
- `{{MM}}` - Month (zero-padded). Example: `12`
- `{{DD}}` - Day (zero-padded). Example: `08`
- `{{HHMMSS}}` - Time in HHMMSS format. Example: `143045`
- `{{HH}}` - Hour (zero-padded). Example: `14`
- `{{TIMESTAMP}}` - Unix timestamp (seconds). Example: `1733676645`
- `{{ISO8601}}` - ISO 8601 format. Example: `2025-12-08T14:30:45Z`
- `{{YESTERDAY_YYYYMMDD}}` - Previous day in YYYYMMDD. Example: `20251207`

## System/Execution Variables

- `{{RUN_ID}}` - Unique pipeline run ID. Example: `550e8400-e29b-41d4-a716-446655440000`
- `{{PIPELINE_NAME}}` - Current pipeline name. Example: `daily_sync`
- `{{PIPELINE_ID}}` - Unique pipeline identifier. Example: `123abc-def456`
- `{{STEP_NAME}}` - Current step name. Example: `export_results`
- `{{USER}}` - Current system user. Example: `alice`
- `{{HOSTNAME}}` - Machine hostname. Example: `data-server-01`
- `{{CWD}}` - Current working directory. Example: `/home/user/qdata`
- `{{RANDOM}}` - Random UUID. Example: `a1b2c3d4-e5f6-47g8-h9i0-j1k2l3m4n5o6`

## Date Arithmetic Functions

Use `{{date_sub()}}` and `{{date_add()}}` to compute dates relative to now.

### Syntax

```
{{date_sub(FORMAT, OFFSET[, UNIT])}}
{{date_add(FORMAT, OFFSET[, UNIT])}}
```

### Parameters

- **FORMAT**: Output format. Options: `YYYYMMDD`, `YYYY-MM-DD`, `YYYY-MM`, `YYYY-MM-01`, `YYYY`, `TIMESTAMP`, `ISO8601`
- **OFFSET**: Number of units to add/subtract (must be an integer)
- **UNIT**: Time unit (optional, defaults to `days`). Options: `days`, `weeks`, `months`, `years`

### Examples

```sql
-- 7 days ago in YYYYMMDD format
WHERE date >= {{date_sub(YYYYMMDD, 7)}}

-- 30 days ago in YYYY-MM-DD format
WHERE created >= {{date_sub(YYYY-MM-DD, 30)}}

-- 3 months ago (YYYY-MM format)
WHERE month >= {{date_sub(YYYY-MM, 3, months)}}

-- Tomorrow (YYYYMMDD format)
WHERE date <= {{date_add(YYYYMMDD, 1)}}

-- Start of next month
WHERE month = {{date_add(YYYY-MM-01, 1, months)}}

-- 2 weeks ago
WHERE updated >= {{date_sub(YYYYMMDD, 2, weeks)}}

-- 1 year ago
WHERE year >= {{date_sub(YYYY, 1, years)}}
```

## Environment Variables

Use `{{ENV:VARIABLE_NAME}}` to access environment variables:

```toml
destination = "{{ENV:DATA_ROOT}}/{{YYYYMMDD}}/output.parquet"
```

Requires: `export DATA_ROOT=/mnt/warehouse`

### Default Values

Provide a default value if the environment variable is not set using `{{ENV:VARIABLE_NAME:default_value}}`:

```toml
destination = "{{ENV:DATA_ROOT:./output}}/{{YYYYMMDD}}/results.parquet"
```

If `DATA_ROOT` is not set, defaults to `./output`. If no default is provided and the variable is not set, an error is raised.

Examples:
- `{{ENV:DATABASE_URL:localhost:5432}}` - Allows colons in the default
- `{{ENV:S3_BUCKET:s3://my-bucket}}` - URI defaults
- `{{ENV:LOG_LEVEL:INFO}}` - Simple string defaults

## Variable Modifiers

Apply transformations to environment variable values using the pipe (`|`) operator. Modifiers are applied left-to-right.

### Supported Modifiers

- `upper` - Convert to uppercase
- `lower` - Convert to lowercase
- `trim` - Remove leading and trailing whitespace

### Syntax

```
{{ENV:VARIABLE_NAME|modifier}}
{{ENV:VARIABLE_NAME|modifier1|modifier2}}
{{ENV:VARIABLE_NAME:default_value|modifier}}
```

### Examples

**Single Modifier**:
```toml
query = "SELECT * FROM users WHERE status = '{{ENV:STATUS|upper}}'"
```
If `STATUS=active`, becomes: `SELECT * FROM users WHERE status = 'ACTIVE'`

**Chained Modifiers** (applied left-to-right):
```toml
destination = "./output/{{ENV:DATASET_NAME|trim|lower}}.csv"
```
If `DATASET_NAME="  MyData  "`, becomes: `./output/mydata.csv`

**With Default Value**:
```toml
query = "SELECT * FROM {{ENV:SCHEMA:public|lower}}.users"
```
If `SCHEMA` is not set, uses `public` then applies lowercase.

### Modifier Error Handling

If you use an unknown modifier, qData will return an error:
```
Error: Unknown template modifier: "invalid". Supported modifiers: upper, lower, trim
```

## Usage Examples

### Example 1: Daily Export

```toml
destination = "./output/daily_{{YYYYMMDD}}.parquet"
```

Output: `./output/daily_20251208.parquet`

### Example 2: Pipeline-Aware Archive

```toml
destination = "./archive/{{PIPELINE_NAME}}/run_{{RUN_ID}}/results.parquet"
```

Output: `./archive/daily_sync/run_550e8400.../results.parquet`

### Example 3: Nested Date Structure

```toml
destination = "/warehouse/{{YYYY}}/{{MM}}/{{DD}}/{{HH}}/data.parquet"
```

Output: `/warehouse/2025/12/08/14/data.parquet`

### Example 4: Environment-Based Path

```toml
destination = "{{ENV:S3_BUCKET}}/{{YYYY}}/{{MM}}/{{PIPELINE_NAME}}.parquet"
```

Requires: `export S3_BUCKET=s3://my-data-lake`

Output: `s3://my-data-lake/2025/12/daily_sync.parquet`

### Example 5: Multiple Variables in Query

```toml
query = """
  INSERT INTO audit_log (pipeline, run_id, step, timestamp)
  VALUES ('{{PIPELINE_NAME}}', '{{RUN_ID}}', '{{STEP_NAME}}', '{{ISO8601}}')
"""
```

### Example 6: Environment Variable with Modifiers

```toml
# Normalize schema and table names to lowercase
[transform]
query = """
  CREATE TABLE {{ENV:SCHEMA|lower}}.{{ENV:TABLE_NAME|lower}} AS
  SELECT * FROM source_data
  WHERE filter = '{{ENV:FILTER_VALUE|trim|upper}}'
"""
```

Input:
```
export SCHEMA="PUBLIC"
export TABLE_NAME="  MyTable  "
export FILTER_VALUE="  active  "
```

Output:
```sql
CREATE TABLE public.mytable AS
SELECT * FROM source_data
WHERE filter = 'ACTIVE'
```

## Notes

- Variables are **case-sensitive**
- Unset environment variables substitute as empty strings
- Template substitution happens before step execution
- All variables are evaluated with the **current** time
- Modifiers are applied to the final value (after defaults are resolved)
