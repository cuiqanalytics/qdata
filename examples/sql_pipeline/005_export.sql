-- Export aggregated results to Parquet
-- This creates the final output artifact
COPY daily_summary 
TO './output/daily_summary_{{YYYYMMDD}}.parquet' 
(FORMAT PARQUET, COMPRESSION SNAPPY);

-- Also export as CSV for accessibility
COPY daily_summary 
TO './output/daily_summary_{{YYYYMMDD}}.csv' 
(FORMAT CSV, HEADER TRUE);
