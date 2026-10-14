-- Replace reused/mismatched demo images with product-specific photos.
-- Product data remains unchanged; only image_url values are corrected.
UPDATE Product
SET image_url = CASE product_id
    WHEN 9 THEN 'https://www.ilmibookhouse.com/cdn/shop/files/python.jpg?v=1762500342'
    WHEN 8 THEN 'https://www.db-book.com/images/db7-cover.jpg'
    WHEN 12 THEN 'https://feeds.abplive.com/onecms/images/uploaded-images/2023/01/19/4e80116326d794a1cbd04339de4bfaf51674111511022256_original.jpg'
    WHEN 30 THEN 'https://images.meesho.com/images/products/698461429/riivy_512.jpg'
    WHEN 36 THEN 'https://i5.walmartimages.com/asr/2f410fcf-5cdf-46f8-8d1f-5d565abcc1cf.12e42cf16708e4baf8fdc4b434a629af.jpeg?odnBg=FFFFFF&odnHeight=768&odnWidth=768'
    WHEN 37 THEN 'https://www.bbassets.com/media/uploads/p/l/40302266_1-le-kaviraj-aluminium-tava-non-stick-coating-28-cm-3-mm-bakelite-handle.jpg'
    WHEN 40 THEN 'https://img.clevup.in/330294/1701170660607_SKU-0973_0.png?format=webp'
    WHEN 43 THEN 'https://omixcdn.com/img/cat/flomastery-2364.png'
    WHEN 44 THEN 'https://breadandbutterexpress.com/cdn/shop/products/img_8061_1024x1024.jpeg?v=1571438589'
    WHEN 46 THEN 'https://m237.apollo247.com/pub/media/catalog/product/J/O/JOH0030_1-AUG23_1.jpg'
    WHEN 48 THEN 'https://marltons.co.za/cdn/shop/products/ClumpingLitter.jpg'
    WHEN 38 THEN 'https://www.bbassets.com/media/uploads/p/xl/40271225_1-oswal-washing-powder-detergent-3x-more-power-low-foaming-saves-water.jpg'
    WHEN 39 THEN 'https://www.sunonline.lk/cdn/shop/products/Vim_PET_Core500ml_1200x1200.jpg?v=1597468156'
    WHEN 45 THEN 'https://images.apollo247.in/pub/media/catalog/product/H/I/HIM0124_1-JULY23_1.jpg?tr=q-80'
    WHEN 54 THEN 'https://images.squarespace-cdn.com/content/v1/60243009f9e8924a27ff4097/38ea4dff-6991-4bd3-888b-c14ac911751f/Cooper%2BBooks%2BRelational%2BDatabase%2BDesign%2Band%2BSQL.png'
    WHEN 55 THEN 'https://storage.ghost.io/c/32/5e/325efbcc-8053-45e0-9fa4-9b095e0643b0/content/images/size/w1200/2023/12/The-Rust-Programming-Language_Klabnik-and-Nichols_cover.jpeg'
    WHEN 57 THEN 'https://media.tatacroma.com/Croma%20Assets/Small%20Appliances/Stoves%20Cooktops/Images/309622_4_deusd0.png'
    WHEN 68 THEN 'https://www.mntcare.in/cdn/shop/files/61IpzNXxiYL._SL1500_1200x1200.jpg?v=1725956803'
    WHEN 70 THEN 'https://rachelellen.co.uk/cdn/shop/files/PUZ07_1c3a7828-2477-44eb-a980-ba2302c96061.jpg?v=1734617299'
    WHEN 71 THEN 'https://jumboplay.com/cdn/shop/files/1120100283_L_0_WEB.jpg?v=1755244957'
    WHEN 72 THEN 'https://popularkitchenking.co.za/cdn/shop/files/131.png?v=1690053669&width=1946'
    WHEN 74 THEN 'https://mobileimages.lowes.com/productimages/75a6a930-9754-4ba9-b741-e45a4b5faf58/04119258.jpg?size=pdhism'
    WHEN 75 THEN 'https://alswaiket.com/image/catalog/products/14214/6287000996395-1.png'
    WHEN 77 THEN 'https://wedo.de/var/formats/productThumb/013/38/106_501_frei.jpg?v=1'
    WHEN 78 THEN 'https://images.apollo247.in/pub/media/catalog/product/L/I/LIT0202_1_1.jpg'
    WHEN 79 THEN 'https://images.apollo247.in/pub/media/catalog/product/J/O/JOH0049_1-AUG23_1.jpg'
    WHEN 81 THEN 'https://www.petessentialswarehouse.co.nz/cdn/shop/files/AM505_Grey__19671_600x.webp?v=1684214316'
    ELSE image_url
END
WHERE product_id IN (8, 9, 12, 30, 36, 37, 38, 39, 40, 43, 44, 45, 46, 48, 54, 55, 57, 68, 70, 71, 72, 74, 75, 77, 78, 79, 81);
