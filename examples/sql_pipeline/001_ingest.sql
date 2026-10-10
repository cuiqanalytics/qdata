-- Ingest raw data from CSV
-- This step loads raw transaction data and creates the raw_data table
CREATE OR REPLACE TABLE raw_data AS
SELECT 
  id,
  date,
  amount,
  category,
  description
FROM read_csv_auto('./data/raw_transactions.csv');
