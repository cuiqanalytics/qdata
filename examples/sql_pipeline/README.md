# SQL Pipeline Example

This directory demonstrates the SQL file sequence feature of qData.

## Structure

The pipeline consists of 5 sequential SQL files that are automatically discovered and chained:

1. **001_ingest.sql** - Load raw data from CSV
   - Type: Auto-detected as `ingest`
   - Output table: `0_ingest`

2. **002_clean.sql** - Clean and standardize data
   - Type: Auto-detected as `transform`
   - Input: `0_ingest` (from previous step)
   - Output table: `1_clean`

3. **003_aggregate.sql** - Create daily summary metrics
   - Type: Auto-detected as `transform`
   - Input: `1_clean`
   - Output table: `2_aggregate`

4. **004_validate.sql** - Quality checks
   - Type: Auto-detected as `validate`
   - Input: `2_aggregate`
   - Returns rows only if validation fails

5. **005_export.sql** - Export results
   - Type: Auto-detected as `sink` (last file)
   - Input: `2_aggregate`

## Optional Configuration

The `sql_pipeline.toml` file allows you to:
- Override the auto-detected pipeline name
- Set description and timeout
- Specify sink destinations

If not present, sensible defaults are used.

## Running the Pipeline

```bash
# From project root
qdata run examples/sql_pipeline
```

## Auto-Detection Rules

### Step Type Detection

Files are classified based on naming patterns:

- **ingest**: Contains "ingest" or "load", or is the first file
- **sink**: Contains "export" or "sink", or is the last file
- **validate**: Contains "validate" or "check"
- **transform**: Everything else

SQL files without a number are skipped.

### Step Ordering

Files are sorted alphabetically by filename, so the numbered prefix (NNN_) ensures correct execution order:
- 001_ → executed first
- 002_ → executed second
- etc.

### Adding More Steps

Simply add more SQL files following the naming convention:
```
006_archive.sql
007_cleanup.sql
```

## Notes

- All SQL is executed in DuckDB
- Each step's output becomes the next step's input (auto-chained)
- Validation steps that return no rows are considered "passed"
- Sink steps don't produce output tables