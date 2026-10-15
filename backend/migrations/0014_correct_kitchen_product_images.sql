-- Replace broken or mismatched images for the affected kitchen catalog items.
UPDATE Product p
JOIN Category c ON c.category_id = p.category_id
JOIN (
    SELECT 'Home Appliances' AS category_name, 'Air Fryer' AS product_name,
        'https://judge.co.uk/media/catalog/product/cache/16e221375103be82e8a5bf95ad9bfb16/j/e/jea108_1_1.png' AS image_url UNION ALL
    SELECT 'Home Appliances', 'Electric Kettle',
        'https://ic4-a.wowma.net/mis/gr/135/image.wowma.jp/2539644/HK05/7272453-y.jpg' UNION ALL
    SELECT 'Home & Kitchen', 'Non-stick Tawa 28 cm',
        'https://www.vishalmegamart.com/dw/image/v2/BGHT_PRD/on/demandware.static/-/Sites-vmm-gm-master-catalog/default/dw8b211653/images/large/1210007512_3.jpg?sh=900&sw=900' UNION ALL
    SELECT 'Home & Kitchen', 'Non-stick Frying Pan 24 cm',
        'https://popularkitchenking.co.za/cdn/shop/files/131.png?v=1690053669&width=1946' UNION ALL
    SELECT 'Home & Kitchen', 'Three-section Stainless Lunch Box',
        'https://www.bamboobark.com/cdn/shop/files/LB-161-1.jpg?v=1752588411&width=1080'
) AS intended ON intended.category_name = c.category_name
    AND intended.product_name = p.product_name
SET p.image_url = intended.image_url;
