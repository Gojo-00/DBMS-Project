-- Correct three unrelated or broken photos in the Toys & Games catalog.
UPDATE Product p
JOIN Category c ON c.category_id = p.category_id
JOIN (
    SELECT 'Toys & Games' AS category_name, 'Creative Building Blocks 80 pieces' AS product_name,
        'https://images.unsplash.com/photo-1756405520788-9a0e2c4bacf7?auto=format&fit=crop&w=800&q=80' AS image_url UNION ALL
    SELECT 'Toys & Games', 'Jigsaw Puzzle 100 pieces',
        'https://images.unsplash.com/photo-1494059980473-813e73ee784b?auto=format&fit=crop&w=800&q=80' UNION ALL
    SELECT 'Toys & Games', 'Family Board Game',
        'https://images.unsplash.com/photo-1577896849786-738ed6c78bd3?auto=format&fit=crop&w=800&q=80'
) AS intended ON intended.category_name = c.category_name
    AND intended.product_name = p.product_name
SET p.image_url = intended.image_url;
