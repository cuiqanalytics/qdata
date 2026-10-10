-- Validation queries
-- Return rows only if validation fails (quality checks)
-- If no rows returned, all validations passed

-- Check for missing categories (to trigger error delete a category, i.e. FOOD)
SELECT 
  'missing_categories' as validation_type,
  COUNT(*) as failed_rows,
  'No transactions for expected categories' as message
FROM daily_summary
WHERE category NOT IN ('FOOD', 'TRANSPORT', 'UTILITIES', 'ENTERTAINMENT')
GROUP BY validation_type
HAVING COUNT(*) > 0

UNION ALL

-- Check for unusual amounts (to trigger error lower amount to 1000)
SELECT 
  'unusual_amount' as validation_type,
  COUNT(*) as failed_rows,
  'Average amount exceeds expected threshold' as message
FROM daily_summary
WHERE avg_amount > 10000
GROUP BY validation_type;
