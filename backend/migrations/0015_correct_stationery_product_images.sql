-- Replace unrelated photos on the four affected stationery products.
UPDATE Product p
JOIN Category c ON c.category_id = p.category_id
JOIN (
    SELECT 'Stationery & Office' AS category_name, 'Ruled Notebook 3 pack' AS product_name,
        'https://i5.walmartimages.com/seo/FIVE-STAR-SMALL-MARBLE-NOTEBOOKS-3-PACK_cdfe5ff1-1680-45b6-9e48-c438f08befc1.5859c2ee92193990116c6b465433fd14.jpeg?odnBg=FFFFFF&odnHeight=576&odnWidth=576' AS image_url UNION ALL
    SELECT 'Stationery & Office', 'Blue Ballpoint Pens 10 pack',
        'https://www.dollarsense.au/cdn/shop/files/9311192567242.jpg?v=1781926329&width=2000' UNION ALL
    SELECT 'Stationery & Office', 'Colour Marker Set 6 pack',
        'https://www.officeandmore.rs/files/images/slike_proizvoda/1701500000125.jpg' UNION ALL
    SELECT 'Stationery & Office', 'A5 Sketchbook 40 sheets',
        'https://down-id.img.susercontent.com/file/id-11134207-82250-mg7iu4yleexa65'
) AS intended ON intended.category_name = c.category_name
    AND intended.product_name = p.product_name
SET p.image_url = intended.image_url;
