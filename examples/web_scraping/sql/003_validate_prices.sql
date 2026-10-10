-- Fail loudly if the page layout changed and prices stopped parsing.
SELECT * FROM products WHERE price_text IS NULL OR NOT regexp_matches(price_text, '\d');
