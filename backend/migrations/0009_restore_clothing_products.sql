-- Restore the two clothing products included in the original catalog seed.
INSERT INTO Product (product_name, price, stock_quantity, category_id, image_url)
SELECT seed.product_name, seed.price, seed.stock_quantity, c.category_id, seed.image_url
FROM (
    SELECT 'Cotton Pullover Hoodie' AS product_name, 799.00 AS price,
        24 AS stock_quantity, 'Clothing' AS category_name,
        'https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&w=800&q=80' AS image_url
    UNION ALL
    SELECT 'Everyday White Sneakers', 1499.00, 18, 'Clothing',
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=800&q=80'
) AS seed
JOIN Category c ON c.category_name = seed.category_name
WHERE NOT EXISTS (
    SELECT 1 FROM Product existing
    WHERE existing.product_name = seed.product_name
      AND existing.category_id = c.category_id
);
