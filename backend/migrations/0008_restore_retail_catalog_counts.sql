-- Restore the original three seeded products per retail department.
-- 0004_product_catalog_images.sql added two sample products to each of
-- these departments. Keep any added item that is already referenced by an
-- order or wishlist so existing customer records remain intact.

DELETE p
FROM Product p
JOIN Category c ON c.category_id = p.category_id
WHERE (c.category_name, p.product_name) IN (
    ('Groceries', 'Toor Dal 1 kg'),
    ('Groceries', 'Iodized Salt 1 kg'),
    ('Fruits', 'Green Seedless Grapes 500 g'),
    ('Fruits', 'Alphonso Mangoes 1 kg'),
    ('Vegetables', 'Fresh Carrots 1 kg'),
    ('Vegetables', 'Baby Spinach 250 g'),
    ('Dairy & Bakery', 'Salted Butter 200 g'),
    ('Dairy & Bakery', 'Butter Croissants 2 pack'),
    ('Snacks & Beverages', 'Dark Chocolate 100 g'),
    ('Snacks & Beverages', 'Butter Popcorn 100 g'),
    ('Cosmetics & Personal Care', 'Nourishing Day Moisturizer 100 g'),
    ('Cosmetics & Personal Care', 'Matte Lipstick 4 g'),
    ('Toys & Games', 'Jigsaw Puzzle 100 pieces'),
    ('Toys & Games', 'Family Board Game'),
    ('Home & Kitchen', 'Non-stick Frying Pan 24 cm'),
    ('Home & Kitchen', 'Three-section Stainless Lunch Box'),
    ('Cleaning & Household', 'Multi-surface Scrub Brush'),
    ('Cleaning & Household', 'Scented Garbage Bags 30 count'),
    ('Stationery & Office', 'A5 Sketchbook 40 sheets'),
    ('Stationery & Office', 'Desk Stapler with Pins'),
    ('Baby Care', 'Baby Bottle 240 ml'),
    ('Baby Care', 'Tear-free Baby Shampoo 200 ml'),
    ('Pet Supplies', 'Adjustable Dog Leash'),
    ('Pet Supplies', 'Cat Scratching Post')
)
AND NOT EXISTS (
    SELECT 1 FROM Order_Item oi WHERE oi.product_id = p.product_id
)
AND NOT EXISTS (
    SELECT 1 FROM Wishlist w WHERE w.product_id = p.product_id
);
