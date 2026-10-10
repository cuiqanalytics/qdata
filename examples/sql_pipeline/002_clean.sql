-- Clean and validate raw data
-- Remove nulls, standardize types, apply business logic
CREATE OR REPLACE TABLE cleaned_data AS
SELECT 
  id,
  date,
  COALESCE(amount, 0)::DECIMAL(10,2) as amount,
  UPPER(TRIM(category)) as category,
  TRIM(description) as description,
  CURRENT_TIMESTAMP as processed_at
FROM raw_data
WHERE 
  date IS NOT NULL
  AND date >= CURRENT_DATE - INTERVAL 30 DAY
  AND COALESCE(amount, 0) != 0;
