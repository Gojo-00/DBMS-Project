-- Replace catalog photos that clearly showed a different product.
-- Match products by department and name so cloud product IDs do not matter.
UPDATE Product p
JOIN Category c ON c.category_id = p.category_id
JOIN (
    SELECT 'Groceries' AS category_name, 'Whole Wheat Atta 5 kg' AS product_name,
        'https://images.unsplash.com/photo-1699315529894-402495fddb8b?auto=format&fit=crop&w=800&q=80' AS image_url UNION ALL
    SELECT 'Home & Kitchen', 'Food Storage Container Set',
        'https://www.pandaplast.com/cdn/shop/files/DEKUPE_94cfc0fb-044e-425e-8079-9fe860c440f5.jpg?v=1753865175' UNION ALL
    SELECT 'Home Appliances', 'Induction Cooktop 1600 W',
        'https://www.kitchenking.ae/images/products/hobs/SI2641D2.jpg' UNION ALL
    SELECT 'Baby Care', 'Baby Diapers Medium 32 count',
        'https://www.meijer.com/content/dam/meijer/product/0713/73/3235/22/0713733235228_2_A7C1_0600.jpg' UNION ALL
    SELECT 'Baby Care', 'Baby Bottle 240 ml',
        'https://creceseguro.cl/cdn/shop/products/2220.jpg?v=1686378237' UNION ALL
    SELECT 'Pet Supplies', 'Clumping Cat Litter 5 kg',
        'https://thehealthylitter.cl/cdn/shop/articles/shutterstock_600989276-min_f0df2167-4982-4a62-b616-39b564f0cb83.jpg?v=1742775689' UNION ALL
    SELECT 'Pet Supplies', 'Cat Scratching Post',
        'https://amanpetshop.com/cdn/shop/products/adidog-Cat-Scratching-Post---Medium_-Gray-AmazonBasics-1655831249.jpg'
) AS intended ON intended.category_name = c.category_name
    AND intended.product_name = p.product_name
SET p.image_url = intended.image_url;
