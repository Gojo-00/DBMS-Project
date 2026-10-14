-- Add two more sample products per department and assign product-specific photos.
-- The catalog is demo data; prices and stock are illustrative.

INSERT INTO Product (product_name, price, stock_quantity, category_id, image_url)
SELECT seed.product_name, seed.price, seed.stock_quantity, c.category_id, seed.image_url
FROM (
    SELECT 'SQL & Database Design Textbook' AS product_name, 599.00 AS price, 20 AS stock_quantity, 'Books' AS category_name, 'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=800&q=80' AS image_url UNION ALL
    SELECT 'Rust Programming Handbook', 699.00, 16, 'Books', 'https://images.unsplash.com/photo-1532012197267-da84d127e765?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Cotton Pullover Hoodie', 799.00, 24, 'Clothing', 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Everyday White Sneakers', 1499.00, 18, 'Clothing', 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Portable Bluetooth Speaker', 1499.00, 22, 'Electronics', 'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT '20W USB-C Fast Charger', 899.00, 28, 'Electronics', 'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Pop-up Toaster', 1999.00, 14, 'Home Appliances', 'https://images.unsplash.com/photo-1585659722983-3a675dabf23d?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Induction Cooktop 1600 W', 2499.00, 12, 'Home Appliances', 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Toor Dal 1 kg', 179.00, 40, 'Groceries', 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Iodized Salt 1 kg', 25.00, 55, 'Groceries', 'https://images.unsplash.com/photo-1620706857370-e1b9770e8bb1?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Green Seedless Grapes 500 g', 99.00, 28, 'Fruits', 'https://images.unsplash.com/photo-1596363505729-4190a9506133?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Alphonso Mangoes 1 kg', 199.00, 24, 'Fruits', 'https://images.unsplash.com/photo-1553279768-865429fa0078?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Fresh Carrots 1 kg', 55.00, 38, 'Vegetables', 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Baby Spinach 250 g', 65.00, 26, 'Vegetables', 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Salted Butter 200 g', 58.00, 30, 'Dairy & Bakery', 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Butter Croissants 2 pack', 99.00, 20, 'Dairy & Bakery', 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Dark Chocolate 100 g', 99.00, 34, 'Snacks & Beverages', 'https://images.unsplash.com/photo-1549007994-cb92caebd54b?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Butter Popcorn 100 g', 75.00, 28, 'Snacks & Beverages', 'https://images.unsplash.com/photo-1578849278619-e73505e9610f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Nourishing Day Moisturizer 100 g', 299.00, 22, 'Cosmetics & Personal Care', 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Matte Lipstick 4 g', 249.00, 19, 'Cosmetics & Personal Care', 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Jigsaw Puzzle 100 pieces', 249.00, 20, 'Toys & Games', 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Family Board Game', 599.00, 14, 'Toys & Games', 'https://images.unsplash.com/photo-1606509036992-44d9b8506a3f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Non-stick Frying Pan 24 cm', 599.00, 18, 'Home & Kitchen', 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Three-section Stainless Lunch Box', 449.00, 20, 'Home & Kitchen', 'https://images.unsplash.com/photo-1589365278144-c9e705f843ba?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Multi-surface Scrub Brush', 99.00, 32, 'Cleaning & Household', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Scented Garbage Bags 30 count', 129.00, 28, 'Cleaning & Household', 'https://images.unsplash.com/photo-1528740561666-dc2479dc08ab?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'A5 Sketchbook 40 sheets', 199.00, 24, 'Stationery & Office', 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Desk Stapler with Pins', 149.00, 20, 'Stationery & Office', 'https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Baby Bottle 240 ml', 299.00, 18, 'Baby Care', 'https://images.unsplash.com/photo-1519689680058-324335c77eba?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Tear-free Baby Shampoo 200 ml', 179.00, 22, 'Baby Care', 'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Adjustable Dog Leash', 349.00, 18, 'Pet Supplies', 'https://images.unsplash.com/photo-1450778869180-41d0601e046e?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Cat Scratching Post', 699.00, 12, 'Pet Supplies', 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?auto=format&fit=crop&w=800&q=80'
) AS seed
JOIN Category c ON c.category_name = seed.category_name
WHERE NOT EXISTS (
    SELECT 1 FROM Product existing
    WHERE existing.product_name = seed.product_name
      AND existing.category_id = c.category_id
);

UPDATE Product p
JOIN Category c ON c.category_id = p.category_id
JOIN (
    SELECT 'Baby Care' AS category_name, 'Baby Diapers Medium 32 count' AS product_name, 'https://images.unsplash.com/photo-1519689680058-324335c77eba?auto=format&fit=crop&w=800&q=80' AS image_url UNION ALL
    SELECT 'Baby Care', 'Baby Wipes 72 count', 'https://images.unsplash.com/photo-1604917877934-07d8d248d396?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Baby Care', 'Gentle Baby Lotion 200 ml', 'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Books', 'Data Structures Book', 'https://images.unsplash.com/photo-1532012197267-da84d127e765?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Books', 'DBMS Book', 'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Books', 'Python Book', 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Cleaning & Household', 'Laundry Detergent Powder 1 kg', 'https://images.unsplash.com/photo-1563453392212-326f5e854473?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Cleaning & Household', 'Dishwashing Liquid 500 ml', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Cleaning & Household', 'Floor Cleaner 1 L', 'https://images.unsplash.com/photo-1528740561666-dc2479dc08ab?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Clothing', 'T-Shirt', 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Clothing', 'Jeans', 'https://images.unsplash.com/photo-1542272604-787c3835535d?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Cosmetics & Personal Care', 'Gentle Face Wash 100 ml', 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Cosmetics & Personal Care', 'Daily Sunscreen SPF 50 50 g', 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Cosmetics & Personal Care', 'Nourishing Shampoo 340 ml', 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Dairy & Bakery', 'Toned Milk 1 L', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Dairy & Bakery', 'Brown Bread 400 g', 'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Dairy & Bakery', 'Farm Eggs 12 pack', 'https://images.unsplash.com/photo-1518569656558-1f25e69d93d7?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Electronics', 'Laptop', 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Electronics', 'Smartphone', 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Electronics', 'Wireless Mouse', 'https://images.unsplash.com/photo-1527814050087-3793815479db?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Electronics', 'Headphones', 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Fruits', 'Apples 1 kg', 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Fruits', 'Bananas 1 dozen', 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Fruits', 'Sweet Oranges 1 kg', 'https://images.unsplash.com/photo-1547514701-42782101795e?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Groceries', 'Premium Basmati Rice 5 kg', 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Groceries', 'Whole Wheat Atta 5 kg', 'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Groceries', 'Sunflower Oil 1 L', 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Home & Kitchen', 'Stainless Steel Water Bottle 750 ml', 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Home & Kitchen', 'Food Storage Container Set', 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Home & Kitchen', 'Non-stick Tawa 28 cm', 'https://images.unsplash.com/photo-1591331645356-1d8f9c0790a4?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Home Appliances', 'Mixer Grinder', 'https://images.unsplash.com/photo-1570222094114-d054a817e56b?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Home Appliances', 'Electric Kettle', 'https://images.unsplash.com/photo-1577733966973-d680bffd2e80?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Home Appliances', 'Air Fryer', 'https://images.unsplash.com/photo-1643271310975-83637b73a282?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Pet Supplies', 'Adult Dog Food 1 kg', 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Pet Supplies', 'Clumping Cat Litter 5 kg', 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Pet Supplies', 'Gentle Pet Shampoo 200 ml', 'https://images.unsplash.com/photo-1543852786-1cf6624b9987?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Snacks & Beverages', 'Classic Salted Chips 100 g', 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Snacks & Beverages', 'Digestive Biscuits 250 g', 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Snacks & Beverages', 'Orange Juice 1 L', 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Stationery & Office', 'Ruled Notebook 3 pack', 'https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Stationery & Office', 'Blue Ballpoint Pens 10 pack', 'https://images.unsplash.com/photo-1453738773917-9c3eff1db985?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Stationery & Office', 'Colour Marker Set 6 pack', 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Toys & Games', 'Creative Building Blocks 80 pieces', 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Toys & Games', 'Mini Toy Car', 'https://images.unsplash.com/photo-1594787318286-3d835c1d207f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Toys & Games', 'Soft Plush Teddy Bear', 'https://images.unsplash.com/photo-1559454403-b8fb88521f11?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Vegetables', 'Potatoes 1 kg', 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Vegetables', 'Onions 1 kg', 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Vegetables', 'Tomatoes 1 kg', 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=800&q=80'
) AS images ON images.category_name = c.category_name
    AND images.product_name = p.product_name
SET p.image_url = images.image_url;
