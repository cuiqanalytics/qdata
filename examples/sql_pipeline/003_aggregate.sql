-- Aggregate transactions by date and category
-- Create daily summary metrics
CREATE OR REPLACE TABLE daily_summary AS
SELECT 
  date,
  category,
  COUNT(*) as transaction_count,
  SUM(amount) as total_amount,
  AVG(amount) as avg_amount,
  MIN(amount) as min_amount,
  MAX(amount) as max_amount,
  COUNT(DISTINCT id) as unique_transactions
FROM cleaned_data
GROUP BY date, category
ORDER BY date DESC, category ASC;
