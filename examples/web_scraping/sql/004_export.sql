COPY (
  SELECT title, link,
         regexp_replace(price_text, '[^0-9.]', '', 'g')::DECIMAL(10, 2) AS price
  FROM products
) TO './output/products.csv' (FORMAT CSV, HEADER TRUE);
