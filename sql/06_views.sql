SET search_path TO olist;

-- ============================================================
-- ANALYTICAL VIEWS
-- ============================================================
-- Project : Olist Brazilian E-Commerce Analytics
-- Database: PostgreSQL
--
-- Description:
-- This file creates reusable analytical views that serve
-- as the data source for the Power BI dashboard.
--
-- These views simplify reporting by providing clean,
-- business-ready datasets for sales, customers, products,
-- sellers, deliveries, payments, and reviews.
-- ============================================================

-- ============================================================
-- VIEW 1: SALES OVERVIEW
-- ============================================================

CREATE OR REPLACE VIEW vw_sales_overview AS

SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    COUNT(DISTINCT oi.seller_id) AS total_sellers,
    ROUND(SUM(oi.price),2) AS total_revenue,
    ROUND(AVG(order_value.total_order_value),2) AS average_order_value

FROM orders o

JOIN customers c
ON o.customer_id = c.customer_id

JOIN order_items oi
ON o.order_id = oi.order_id

JOIN
(
    SELECT
        order_id,
        SUM(price) AS total_order_value
    FROM order_items
    GROUP BY order_id
) order_value
ON o.order_id = order_value.order_id;


-- ============================================================
-- VIEW 2: MONTHLY SALES
-- ============================================================

CREATE OR REPLACE VIEW vw_monthly_sales AS

WITH monthly_orders AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
        o.order_id,
        SUM(oi.price) AS order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        DATE_TRUNC('month', o.order_purchase_timestamp),
        o.order_id
)

SELECT
    order_month,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(order_value), 2) AS total_revenue,
    ROUND(AVG(order_value), 2) AS average_order_value
FROM monthly_orders
GROUP BY order_month
ORDER BY order_month;

-- ============================================================
-- VIEW 3: CUSTOMER ANALYSIS
-- ============================================================

CREATE OR REPLACE VIEW vw_customer_analysis AS

SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(
        SUM(oi.price) /
        COUNT(DISTINCT c.customer_unique_id),
        2
    ) AS revenue_per_customer
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;


-- ============================================================
-- VIEW 4: PRODUCT ANALYSIS
-- ============================================================

CREATE OR REPLACE VIEW vw_product_analysis AS

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,

    COUNT(*) AS quantity_sold,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    ROUND(SUM(oi.price), 2) AS total_revenue,

    ROUND(AVG(oi.price), 2) AS average_price,

    ROUND(AVG(oi.freight_value), 2) AS average_freight_cost

FROM order_items oi

JOIN products p
ON oi.product_id = p.product_id

LEFT JOIN category_translation ct
ON p.product_category_name = ct.product_category_name

GROUP BY
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )

ORDER BY total_revenue DESC;

-- ============================================================
-- VIEW 5: SELLER ANALYSIS
-- ============================================================

CREATE OR REPLACE VIEW vw_seller_analysis AS

SELECT
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS average_order_value,
    ROUND(AVG(r.review_score), 2) AS average_review_score

FROM sellers s

JOIN order_items oi
ON s.seller_id = oi.seller_id

LEFT JOIN order_reviews r
ON oi.order_id = r.order_id

GROUP BY
    s.seller_id,
    s.seller_state

ORDER BY total_revenue DESC;

-- ============================================================
-- VIEW 6: DELIVERY ANALYSIS
-- ============================================================

CREATE OR REPLACE VIEW vw_delivery_analysis AS

SELECT
    c.customer_state,
    COUNT(o.order_id) AS total_orders,
	ROUND(
    AVG(
        EXTRACT(
            EPOCH FROM (
                o.order_delivered_customer_date -
                o.order_purchase_timestamp
            )
        ) / 86400
    ),
    2
) AS average_delivery_days,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date >
                 o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_deliveries,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN o.order_delivered_customer_date <=
                     o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) /
        COUNT(o.order_id),
        2
    ) AS on_time_delivery_percentage

FROM orders o

JOIN customers c
ON o.customer_id = c.customer_id

WHERE o.order_delivered_customer_date IS NOT NULL

GROUP BY c.customer_state

ORDER BY average_delivery_days DESC;

-- ============================================================
-- VIEW 7: PAYMENT ANALYSIS
-- ============================================================

CREATE OR REPLACE VIEW vw_payment_analysis AS

SELECT
    payment_type,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS average_payment_value,
    ROUND(AVG(payment_installments), 2) AS average_installments
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- ============================================================
-- VIEW 8: REVIEW ANALYSIS
-- ============================================================

CREATE OR REPLACE VIEW vw_review_analysis AS

SELECT
    r.review_score,
    COUNT(DISTINCT r.review_id) AS total_reviews,
    COUNT(DISTINCT r.order_id) AS total_orders,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    o.order_delivered_customer_date -
                    o.order_purchase_timestamp
                )
            ) / 86400
        ),
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(order_value.total_order_value),
        2
    ) AS average_order_value

FROM order_reviews r

JOIN orders o
    ON r.order_id = o.order_id

JOIN (
    SELECT
        order_id,
        SUM(price) AS total_order_value
    FROM order_items
    GROUP BY order_id
) order_value
    ON r.order_id = order_value.order_id

WHERE o.order_delivered_customer_date IS NOT NULL

GROUP BY r.review_score

ORDER BY r.review_score;
