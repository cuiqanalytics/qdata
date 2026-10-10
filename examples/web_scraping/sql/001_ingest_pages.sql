-- Load saved HTML pages (one row per file). webbed's HTML type lets html_extract_* read the body.
-- Swap the glob for a list of URLs to fetch live: read_text(['https://...', 'https://...'])
CREATE OR REPLACE TABLE raw_pages AS
SELECT 'https://shop.example/catalog/' || parse_filename(filename) AS url,
       content::HTML AS body
FROM read_text('./pages/*.html');
