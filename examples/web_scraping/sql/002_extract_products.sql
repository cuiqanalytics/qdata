-- One row per product card. xpath_all/xpath_first/abs_url/clean_text are built-in qdata macros.
CREATE OR REPLACE TABLE products AS
SELECT unnest(xpath_all(body, '//article/h3/a/@title'))                  AS title,
       abs_url(url, unnest(xpath_all(body, '//article/h3/a/@href')))      AS link,
       clean_text(unnest(xpath_all(body, '//p[@class="price"]')))         AS price_text
FROM raw_pages;
