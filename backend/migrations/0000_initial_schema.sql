-- Base schema for a clean demo database. IDs become AUTO_INCREMENT in 0001.
-- Keep table and constraint names aligned with the API and 0001 migration.

CREATE TABLE Customer (
    customer_id INT NOT NULL,
    name VARCHAR(120) NOT NULL,
    email VARCHAR(254) NULL,
    phone VARCHAR(20) NULL,
    address VARCHAR(500) NOT NULL DEFAULT '',
    PRIMARY KEY (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Category (
    category_id INT NOT NULL,
    category_name VARCHAR(120) NOT NULL,
    description VARCHAR(500) NULL,
    PRIMARY KEY (category_id),
    UNIQUE KEY uq_category_name (category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Product (
    product_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INT NULL,
    category_id INT NULL,
    PRIMARY KEY (product_id),
    KEY idx_product_category (category_id),
    CONSTRAINT product_ibfk_1 FOREIGN KEY (category_id) REFERENCES Category(category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Orders (
    order_id INT NOT NULL,
    order_date DATE NULL,
    customer_id INT NOT NULL,
    order_status VARCHAR(40) NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id),
    KEY idx_orders_customer (customer_id),
    CONSTRAINT orders_ibfk_1 FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Order_Item (
    order_item_id INT NOT NULL,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_item_id),
    KEY idx_order_item_order (order_id),
    KEY idx_order_item_product (product_id),
    CONSTRAINT order_item_ibfk_1 FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    CONSTRAINT order_item_ibfk_2 FOREIGN KEY (product_id) REFERENCES Product(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Payment (
    payment_id INT NOT NULL,
    order_id INT NOT NULL,
    payment_date_time DATETIME NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(60) NULL,
    payment_status VARCHAR(40) NULL,
    PRIMARY KEY (payment_id),
    KEY idx_payment_order (order_id),
    CONSTRAINT payment_ibfk_1 FOREIGN KEY (order_id) REFERENCES Orders(order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Delivery (
    delivery_id INT NOT NULL,
    order_id INT NOT NULL,
    scheduled_delivery_date DATE NULL,
    scheduled_delivery_time TIME NULL,
    delivery_date DATE NULL,
    delivery_address VARCHAR(500) NOT NULL,
    delivery_status VARCHAR(40) NULL,
    PRIMARY KEY (delivery_id),
    KEY idx_delivery_order (order_id),
    CONSTRAINT delivery_ibfk_1 FOREIGN KEY (order_id) REFERENCES Orders(order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Wishlist (
    wishlist_id INT NOT NULL,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    added_date DATE NULL,
    PRIMARY KEY (wishlist_id),
    KEY idx_wishlist_customer (customer_id),
    KEY idx_wishlist_product (product_id),
    CONSTRAINT wishlist_ibfk_1 FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    CONSTRAINT wishlist_ibfk_2 FOREIGN KEY (product_id) REFERENCES Product(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
