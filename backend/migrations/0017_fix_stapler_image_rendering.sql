-- Use the shop's existing Unsplash image host for reliable browser rendering.
UPDATE Product p
JOIN Category c ON c.category_id = p.category_id
SET p.image_url = 'https://images.unsplash.com/photo-1764025851210-9ad5ed83e01f?auto=format&fit=crop&w=800&q=80'
WHERE c.category_name = 'Stationery & Office'
  AND p.product_name = 'Desk Stapler with Pins';
