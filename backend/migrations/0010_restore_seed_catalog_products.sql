-- Restore the complete two-product extension from the original catalog seed.
-- The prior cleanup removed unreferenced seeded rows; this idempotent insert
-- also fills the products for legacy departments that were created later.

INSERT INTO Product (product_name, price, stock_quantity, category_id, image_url)
SELECT seed.product_name, seed.price, seed.stock_quantity, c.category_id, seed.image_url
FROM (
    SELECT 'SQL & Database Design Textbook' AS product_name, 599.00 AS price,
        20 AS stock_quantity, 'Books' AS category_name,
        'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=800&q=80' AS image_url UNION ALL
    SELECT 'Rust Programming Handbook', 699.00, 16, 'Books',
        'https://images.unsplash.com/photo-1532012197267-da84d127e765?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Cotton Pullover Hoodie', 799.00, 24, 'Clothing',
        'https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Everyday White Sneakers', 1499.00, 18, 'Clothing',
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Portable Bluetooth Speaker', 1499.00, 22, 'Electronics',
        'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT '20W USB-C Fast Charger', 899.00, 28, 'Electronics',
        'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Pop-up Toaster', 1999.00, 14, 'Home Appliances',
        'https://images.unsplash.com/photo-1585659722983-3a675dabf23d?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Induction Cooktop 1600 W', 2499.00, 12, 'Home Appliances',
        'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Toor Dal 1 kg', 179.00, 40, 'Groceries',
        'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Iodized Salt 1 kg', 25.00, 55, 'Groceries',
        'https://images.unsplash.com/photo-1620706857370-e1b9770e8bb1?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Green Seedless Grapes 500 g', 99.00, 28, 'Fruits',
        'https://images.unsplash.com/photo-1596363505729-4190a9506133?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Alphonso Mangoes 1 kg', 199.00, 24, 'Fruits',
        'https://images.unsplash.com/photo-1553279768-865429fa0078?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Fresh Carrots 1 kg', 55.00, 38, 'Vegetables',
        'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Baby Spinach 250 g', 65.00, 26, 'Vegetables',
        'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Salted Butter 200 g', 58.00, 30, 'Dairy & Bakery',
        'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Butter Croissants 2 pack', 99.00, 20, 'Dairy & Bakery',
        'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Dark Chocolate 100 g', 99.00, 34, 'Snacks & Beverages',
        'https://images.unsplash.com/photo-1549007994-cb92caebd54b?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Butter Popcorn 100 g', 75.00, 28, 'Snacks & Beverages',
        'https://images.unsplash.com/photo-1578849278619-e73505e9610f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Nourishing Day Moisturizer 100 g', 299.00, 22, 'Cosmetics & Personal Care',
        'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Matte Lipstick 4 g', 249.00, 19, 'Cosmetics & Personal Care',
        'https://images.unsplash.com/photo-1586495777744-4413f21062fa?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Jigsaw Puzzle 100 pieces', 249.00, 20, 'Toys & Games',
        'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Family Board Game', 599.00, 14, 'Toys & Games',
        'https://images.unsplash.com/photo-1606509036992-44d9b8506a3f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Non-stick Frying Pan 24 cm', 599.00, 18, 'Home & Kitchen',
        'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Three-section Stainless Lunch Box', 449.00, 20, 'Home & Kitchen',
        'https://images.unsplash.com/photo-1589365278144-c9e705f843ba?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Multi-surface Scrub Brush', 99.00, 32, 'Cleaning & Household',
        'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Scented Garbage Bags 30 count', 129.00, 28, 'Cleaning & Household',
        'https://images.unsplash.com/photo-1528740561666-dc2479dc08ab?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'A5 Sketchbook 40 sheets', 199.00, 24, 'Stationery & Office',
        'https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Desk Stapler with Pins', 149.00, 20, 'Stationery & Office',
        'https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Baby Bottle 240 ml', 299.00, 18, 'Baby Care',
        'https://images.unsplash.com/photo-1519689680058-324335c77eba?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Tear-free Baby Shampoo 200 ml', 179.00, 22, 'Baby Care',
        'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Adjustable Dog Leash', 349.00, 18, 'Pet Supplies',
        'https://images.unsplash.com/photo-1450778869180-41d0601e046e?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Cat Scratching Post', 699.00, 12, 'Pet Supplies',
        'https://images.unsplash.com/photo-1573865526739-10659fec78a5?auto=format&fit=crop&w=800&q=80'
) AS seed
JOIN Category c ON c.category_name = seed.category_name
WHERE NOT EXISTS (
    SELECT 1 FROM Product existing
    WHERE existing.product_name = seed.product_name
      AND existing.category_id = c.category_id
);
