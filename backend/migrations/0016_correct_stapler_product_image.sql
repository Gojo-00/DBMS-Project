-- Replace the unrelated writing photo on the desk stapler product.
UPDATE Product p
JOIN Category c ON c.category_id = p.category_id
SET p.image_url = 'https://www.staples.ca/cdn/shop/products/5c08cd5ec9d628bb53c87057333a46cc551af833_square978089_1_1000x.jpg?v=1770527724'
WHERE c.category_name = 'Stationery & Office'
  AND p.product_name = 'Desk Stapler with Pins';
