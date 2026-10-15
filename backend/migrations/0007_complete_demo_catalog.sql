-- Ensure the legacy storefront departments are present in a clean cloud DB.
INSERT INTO Category (category_name, description)
SELECT seed.category_name, seed.description
FROM (
    SELECT 'Books' AS category_name, 'Books for study, technology and reading.' AS description UNION ALL
    SELECT 'Clothing', 'Everyday clothing and footwear.' UNION ALL
    SELECT 'Electronics', 'Electronic devices and accessories.' UNION ALL
    SELECT 'Home Appliances', 'Useful appliances for the home and kitchen.'
) AS seed
WHERE NOT EXISTS (
    SELECT 1 FROM Category existing WHERE existing.category_name = seed.category_name
);

-- Match the products previously present on the storefront, without duplicating
-- items already supplied by a developer's existing catalog.
INSERT INTO Product (product_name, price, stock_quantity, category_id, image_url)
SELECT seed.product_name, seed.price, seed.stock_quantity, c.category_id, seed.image_url
FROM (
    SELECT 'DBMS Book' AS product_name, 499.00 AS price, 24 AS stock_quantity, 'Books' AS category_name,
        'https://www.db-book.com/images/db7-cover.jpg' AS image_url UNION ALL
    SELECT 'Data Structures Book', 599.00, 22, 'Books',
        'https://images.unsplash.com/photo-1532012197267-da84d127e765?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Python Book', 850.00, 35, 'Books',
        'https://www.ilmibookhouse.com/cdn/shop/files/python.jpg?v=1762500342' UNION ALL
    SELECT 'Laptop', 60000.00, 19, 'Electronics',
        'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Smartphone', 30000.00, 35, 'Electronics',
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Wireless Mouse', 1200.00, 50, 'Electronics',
        'https://images.unsplash.com/photo-1527814050087-3793815479db?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Headphones', 2500.00, 40, 'Electronics',
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'T-Shirt', 499.00, 30, 'Clothing',
        'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Jeans', 999.00, 26, 'Clothing',
        'https://images.unsplash.com/photo-1542272604-787c3835535d?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Mixer Grinder', 2499.00, 18, 'Home Appliances',
        'https://images.unsplash.com/photo-1570222094114-d054a817e56b?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Electric Kettle', 999.00, 28, 'Home Appliances',
        'https://images.unsplash.com/photo-1577733966973-d680bffd2e80?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Air Fryer', 4999.00, 12, 'Home Appliances',
        'https://images.unsplash.com/photo-1643271310975-83637b73a282?auto=format&fit=crop&w=800&q=80'
) AS seed
JOIN Category c ON c.category_name = seed.category_name
WHERE NOT EXISTS (
    SELECT 1 FROM Product existing
    WHERE existing.product_name = seed.product_name
      AND existing.category_id = c.category_id
);
