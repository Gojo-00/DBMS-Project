-- no-transaction
ALTER TABLE Orders DROP FOREIGN KEY orders_ibfk_1;
ALTER TABLE Product DROP FOREIGN KEY product_ibfk_1;
ALTER TABLE Order_Item DROP FOREIGN KEY order_item_ibfk_1, DROP FOREIGN KEY order_item_ibfk_2;
ALTER TABLE Payment DROP FOREIGN KEY payment_ibfk_1;
ALTER TABLE Delivery DROP FOREIGN KEY delivery_ibfk_1;
ALTER TABLE Wishlist DROP FOREIGN KEY wishlist_ibfk_1, DROP FOREIGN KEY wishlist_ibfk_2;

ALTER TABLE Customer MODIFY customer_id INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Category MODIFY category_id INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Product MODIFY product_id INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Orders MODIFY order_id INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Order_Item MODIFY order_item_id INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Payment MODIFY payment_id INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Delivery MODIFY delivery_id INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Wishlist MODIFY wishlist_id INT NOT NULL AUTO_INCREMENT;

ALTER TABLE Orders ADD CONSTRAINT orders_ibfk_1 FOREIGN KEY (customer_id) REFERENCES Customer(customer_id);
ALTER TABLE Product ADD CONSTRAINT product_ibfk_1 FOREIGN KEY (category_id) REFERENCES Category(category_id);
ALTER TABLE Order_Item
    ADD CONSTRAINT order_item_ibfk_1 FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    ADD CONSTRAINT order_item_ibfk_2 FOREIGN KEY (product_id) REFERENCES Product(product_id);
ALTER TABLE Payment ADD CONSTRAINT payment_ibfk_1 FOREIGN KEY (order_id) REFERENCES Orders(order_id);
ALTER TABLE Delivery ADD CONSTRAINT delivery_ibfk_1 FOREIGN KEY (order_id) REFERENCES Orders(order_id);
ALTER TABLE Wishlist
    ADD CONSTRAINT wishlist_ibfk_1 FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    ADD CONSTRAINT wishlist_ibfk_2 FOREIGN KEY (product_id) REFERENCES Product(product_id);
