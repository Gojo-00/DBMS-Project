-- Use product photos that match the dal and salt catalog entries.
UPDATE Product p
JOIN Category c ON c.category_id = p.category_id
JOIN (
    SELECT 'Groceries' AS category_name, 'Toor Dal 1 kg' AS product_name,
        'https://www.mystore.in/s/62ea2c599d1398fa16dbae0a/g/69e219159d716e14c959086d/img_20260415_173817-1024x1024.jpg' AS image_url UNION ALL
    SELECT 'Groceries', 'Iodized Salt 1 kg',
        'https://s7ap1.scene7.com/is/image/itcportalprod/aashirvaad%20salt-1?fmt=webp-alpha'
) AS intended ON intended.category_name = c.category_name
    AND intended.product_name = p.product_name
SET p.image_url = intended.image_url;
