-- Idempotent sample catalog for supermarket-style departments.
-- Run after the base schema exists. Product prices and stock are demo values.

INSERT INTO Category (category_name, description)
SELECT seed.category_name, seed.description
FROM (
    SELECT 'Groceries' AS category_name, 'Staples, rice, flour, oils and pantry essentials.' AS description UNION ALL
    SELECT 'Fruits', 'Fresh seasonal fruits and everyday produce.' UNION ALL
    SELECT 'Vegetables', 'Fresh vegetables and leafy greens for everyday cooking.' UNION ALL
    SELECT 'Dairy & Bakery', 'Milk, eggs, bread and fresh bakery essentials.' UNION ALL
    SELECT 'Snacks & Beverages', 'Chips, biscuits, juices and everyday refreshments.' UNION ALL
    SELECT 'Cosmetics & Personal Care', 'Skincare, haircare, beauty and daily hygiene essentials.' UNION ALL
    SELECT 'Toys & Games', 'Building toys, games and gifts for children of different ages.' UNION ALL
    SELECT 'Home & Kitchen', 'Cookware, storage and practical household kitchen essentials.' UNION ALL
    SELECT 'Cleaning & Household', 'Laundry, dishwashing and home cleaning supplies.' UNION ALL
    SELECT 'Stationery & Office', 'Notebooks, pens and supplies for study and work.' UNION ALL
    SELECT 'Baby Care', 'Diapers, wipes and gentle essentials for babies.' UNION ALL
    SELECT 'Pet Supplies', 'Food, grooming and everyday care for household pets.'
) AS seed
WHERE NOT EXISTS (
    SELECT 1 FROM Category existing WHERE existing.category_name = seed.category_name
);

INSERT INTO Product (product_name, price, stock_quantity, category_id)
SELECT seed.product_name, seed.price, seed.stock_quantity, c.category_id
FROM (
    SELECT 'Premium Basmati Rice 5 kg' AS product_name, 549.00 AS price, 40 AS stock_quantity, 'Groceries' AS category_name UNION ALL
    SELECT 'Whole Wheat Atta 5 kg', 265.00, 35, 'Groceries' UNION ALL
    SELECT 'Sunflower Oil 1 L', 149.00, 42, 'Groceries' UNION ALL
    SELECT 'Apples 1 kg', 189.00, 30, 'Fruits' UNION ALL
    SELECT 'Bananas 1 dozen', 65.00, 50, 'Fruits' UNION ALL
    SELECT 'Sweet Oranges 1 kg', 99.00, 35, 'Fruits' UNION ALL
    SELECT 'Potatoes 1 kg', 35.00, 60, 'Vegetables' UNION ALL
    SELECT 'Onions 1 kg', 49.00, 55, 'Vegetables' UNION ALL
    SELECT 'Tomatoes 1 kg', 39.00, 45, 'Vegetables' UNION ALL
    SELECT 'Toned Milk 1 L', 68.00, 40, 'Dairy & Bakery' UNION ALL
    SELECT 'Brown Bread 400 g', 45.00, 30, 'Dairy & Bakery' UNION ALL
    SELECT 'Farm Eggs 12 pack', 96.00, 36, 'Dairy & Bakery' UNION ALL
    SELECT 'Classic Salted Chips 100 g', 40.00, 45, 'Snacks & Beverages' UNION ALL
    SELECT 'Digestive Biscuits 250 g', 35.00, 50, 'Snacks & Beverages' UNION ALL
    SELECT 'Orange Juice 1 L', 110.00, 28, 'Snacks & Beverages' UNION ALL
    SELECT 'Gentle Face Wash 100 ml', 199.00, 24, 'Cosmetics & Personal Care' UNION ALL
    SELECT 'Daily Sunscreen SPF 50 50 g', 349.00, 20, 'Cosmetics & Personal Care' UNION ALL
    SELECT 'Nourishing Shampoo 340 ml', 249.00, 26, 'Cosmetics & Personal Care' UNION ALL
    SELECT 'Creative Building Blocks 80 pieces', 499.00, 18, 'Toys & Games' UNION ALL
    SELECT 'Mini Toy Car', 299.00, 25, 'Toys & Games' UNION ALL
    SELECT 'Soft Plush Teddy Bear', 399.00, 16, 'Toys & Games' UNION ALL
    SELECT 'Stainless Steel Water Bottle 750 ml', 299.00, 30, 'Home & Kitchen' UNION ALL
    SELECT 'Food Storage Container Set', 499.00, 22, 'Home & Kitchen' UNION ALL
    SELECT 'Non-stick Tawa 28 cm', 699.00, 15, 'Home & Kitchen' UNION ALL
    SELECT 'Laundry Detergent Powder 1 kg', 125.00, 35, 'Cleaning & Household' UNION ALL
    SELECT 'Dishwashing Liquid 500 ml', 99.00, 30, 'Cleaning & Household' UNION ALL
    SELECT 'Floor Cleaner 1 L', 145.00, 26, 'Cleaning & Household' UNION ALL
    SELECT 'Ruled Notebook 3 pack', 120.00, 40, 'Stationery & Office' UNION ALL
    SELECT 'Blue Ballpoint Pens 10 pack', 80.00, 38, 'Stationery & Office' UNION ALL
    SELECT 'Colour Marker Set 6 pack', 150.00, 24, 'Stationery & Office' UNION ALL
    SELECT 'Baby Diapers Medium 32 count', 449.00, 20, 'Baby Care' UNION ALL
    SELECT 'Baby Wipes 72 count', 149.00, 28, 'Baby Care' UNION ALL
    SELECT 'Gentle Baby Lotion 200 ml', 189.00, 18, 'Baby Care' UNION ALL
    SELECT 'Adult Dog Food 1 kg', 399.00, 22, 'Pet Supplies' UNION ALL
    SELECT 'Clumping Cat Litter 5 kg', 299.00, 16, 'Pet Supplies' UNION ALL
    SELECT 'Gentle Pet Shampoo 200 ml', 199.00, 18, 'Pet Supplies'
) AS seed
JOIN Category c ON c.category_name = seed.category_name
WHERE NOT EXISTS (
    SELECT 1 FROM Product existing
    WHERE existing.product_name = seed.product_name
      AND existing.category_id = c.category_id
);
