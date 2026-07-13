SET search_path TO olist;
-- ==================
-- 1. ROW COUNTS
-- ==================
SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers
UNION ALL
SELECT 'orders', count(*) 
FROM ORDERS
UNION ALL
SELECT 'order_items', count(*) 
FROM ORDER_ITEMS
UNION ALL
SELECT 'order_payments', COUNT(*) 
FROM order_payments
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

-- ====================
--2. DATA TYPE VALIDATION
-- ====================

SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'olist'
  AND table_name IN ('orders', 'order_items', 'order_payments')
ORDER BY table_name, ordinal_position;

-- ==========================================
-- 3. DUPLICATE PRIMARY KEY CHECK
-- ==========================================

SELECT
    order_id,
    COUNT(*) AS record_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT
    product_id,
    COUNT(*) AS record_count
FROM olist.products
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT
    seller_id,
    COUNT(*) AS record_count
FROM olist.sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS record_count
FROM olist.order_items
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;



-- =================================