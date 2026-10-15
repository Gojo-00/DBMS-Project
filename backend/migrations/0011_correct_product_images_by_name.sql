-- Repair four image mismatches caused by an older correction migration that
-- assigned images by fixed product IDs. Match the intended image to each exact
-- product and department instead.
UPDATE Product p
JOIN Category c ON c.category_id = p.category_id
JOIN (
    SELECT 'Vegetables' AS category_name, 'Onions 1 kg' AS product_name,
        'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?auto=format&fit=crop&w=800&q=80' AS image_url UNION ALL
    SELECT 'Vegetables', 'Tomatoes 1 kg',
        'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Dairy & Bakery', 'Farm Eggs 12 pack',
        'https://images.unsplash.com/photo-1518569656558-1f25e69d93d7?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Stationery & Office', 'Colour Marker Set 6 pack',
        'https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Pet Supplies', 'Gentle Pet Shampoo 200 ml',
        'https://smytten-image.gumlet.io/shop_item/NGB0004AB11.jpg'
) AS intended ON intended.category_name = c.category_name
    AND intended.product_name = p.product_name
SET p.image_url = intended.image_url;
