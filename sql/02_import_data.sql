SET search_path TO olist;

COPY customers
FROM '/Users/pavankumarbathula/Desktop/olist-business-analytics/data/olist_customers_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY orders
FROM '/Users/pavankumarbathula/Desktop/olist-business-analytics/data/olist_orders_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY order_items
FROM '/Users/pavankumarbathula/Desktop/olist-business-analytics/data/olist_order_items_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY order_payments
FROM '/Users/pavankumarbathula/Desktop/olist-business-analytics/data/olist_order_payments_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY order_reviews
FROM '/Users/pavankumarbathula/Desktop/olist-business-analytics/data/olist_order_reviews_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY products
FROM '/Users/pavankumarbathula/Desktop/olist-business-analytics/data/olist_products_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY sellers
FROM '/Users/pavankumarbathula/Desktop/olist-business-analytics/data/olist_sellers_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY geolocation
FROM '/Users/pavankumarbathula/Desktop/olist-business-analytics/data/olist_geolocation_dataset.csv'
DELIMITER ','
CSV HEADER;

COPY category_translation
FROM '/Users/pavankumarbathula/Desktop/olist-business-analytics/data/product_category_name_translation.csv'
DELIMITER ','
CSV HEADER;


SET search_path TO olist;

SELECT 'customers' AS table_name, COUNT(*) FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL
SELECT 'category_translation', COUNT(*) FROM category_translation;


-- ============================================================
-- Add Foreign Key: Orders → Customers
-- Each order must belong to an existing customer.
-- ============================================================
ALTER TABLE olist.orders
ADD CONSTRAINT fk_orders_customers
FOREIGN KEY (customer_id)
REFERENCES olist.customers(customer_id);


-- ============================================================
-- Add Foreign Key: Order Items → Orders
-- Each order item must belong to an existing order.
-- ============================================================
ALTER TABLE olist.order_items
ADD CONSTRAINT fk_order_items_orders
FOREIGN KEY (order_id)
REFERENCES olist.orders(order_id);


-- ============================================================
-- Add Foreign Key: Order Items → Products
-- Each order item must reference an existing product.
-- ============================================================
ALTER TABLE olist.order_items
ADD CONSTRAINT fk_order_items_products
FOREIGN KEY (product_id)
REFERENCES olist.products(product_id);


-- ============================================================
-- Add Foreign Key: Order Items → Sellers
-- Each order item must reference an existing seller.
-- ============================================================
ALTER TABLE olist.order_items
ADD CONSTRAINT fk_order_items_sellers
FOREIGN KEY (seller_id)
REFERENCES olist.sellers(seller_id);


-- ============================================================
-- Add Foreign Key: Order Payments → Orders
-- Each payment record must belong to an existing order.
-- ============================================================
ALTER TABLE olist.order_payments
ADD CONSTRAINT fk_order_payments_orders
FOREIGN KEY (order_id)
REFERENCES olist.orders(order_id);


-- ============================================================
-- Add Foreign Key: Order Reviews → Orders
-- Each review must be associated with an existing order.
-- ============================================================
ALTER TABLE olist.order_reviews
ADD CONSTRAINT fk_order_reviews_orders
FOREIGN KEY (order_id)
REFERENCES olist.orders(order_id);

-- ============================================================
-- Configure Relationship Between Products and Category Translation
-- ============================================================
ALTER TABLE category_translation
ADD CONSTRAINT uq_category_translation_name
UNIQUE (product_category_name);

ALTER TABLE products
ADD CONSTRAINT fk_products_category_translation
FOREIGN KEY (product_category_name)
REFERENCES category_translation(product_category_name);

