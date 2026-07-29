SET search_path TO olist;

-- ============================================================
-- DASHBOARD QUERIES
-- ============================================================
-- Project : Olist Brazilian E-Commerce Analytics
-- Database: PostgreSQL
--
-- Description:
-- This file contains the SQL queries used to calculate the
-- KPIs and datasets displayed in the Power BI dashboard.
--
-- Dashboard Sections:
-- 1. Executive Dashboard
-- 2. Sales Dashboard
-- 3. Customer Dashboard
-- 4. Product Dashboard
-- 5. Seller Dashboard
-- 6. Delivery Dashboard
-- 7. Payment Dashboard
-- ============================================================



-- ============================================================
-- SECTION 1: EXECUTIVE DASHBOARD
-- ============================================================


-- KPI 1: Total Revenue
-- Measures total product sales revenue, excluding freight.

SELECT
    ROUND(SUM(price), 2) AS total_revenue
FROM order_items;


-- KPI 2: Total Orders

SELECT
    COUNT(DISTINCT order_id) AS total_orders
FROM orders;


-- KPI 3: Average Order Value
-- First calculates the value of each order and then averages it.

WITH order_values AS (
    SELECT
        order_id,
        SUM(price) AS order_value
    FROM order_items
    GROUP BY order_id
)
SELECT
    ROUND(AVG(order_value), 2) AS average_order_value
FROM order_values;


-- KPI 4: Total Unique Customers

SELECT
    COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers;


-- KPI 5: Total Sellers

SELECT
    COUNT(DISTINCT seller_id) AS total_sellers
FROM sellers;


-- Visual 1: Monthly Revenue Trend

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
    ROUND(SUM(oi.price), 2) AS monthly_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY order_month;


-- Visual 2: Revenue by Customer State

SELECT
    c.customer_state,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;


-- Visual 3: Top 10 Product Categories by Revenue

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,
    ROUND(SUM(oi.price), 2) AS total_revenue
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
ORDER BY total_revenue DESC
LIMIT 10;



-- ============================================================
-- SECTION 2: SALES DASHBOARD
-- ============================================================


-- Visual 1: Monthly Sales and Order Trend

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY order_month;


-- Visual 2: Month-over-Month Revenue Growth

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
        SUM(oi.price) AS monthly_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
),
sales_with_previous_month AS (
    SELECT
        order_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            ORDER BY order_month
        ) AS previous_month_revenue
    FROM monthly_sales
)
SELECT
    order_month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        (
            (monthly_revenue - previous_month_revenue)
            / NULLIF(previous_month_revenue, 0)
        ) * 100,
        2
    ) AS mom_growth_percentage
FROM sales_with_previous_month
ORDER BY order_month;


-- Visual 3: Revenue by Day of Week
-- DOW: Sunday = 0 and Saturday = 6.

SELECT
    EXTRACT(DOW FROM o.order_purchase_timestamp) AS day_number,
    TO_CHAR(o.order_purchase_timestamp, 'FMDay') AS day_of_week,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    EXTRACT(DOW FROM o.order_purchase_timestamp),
    TO_CHAR(o.order_purchase_timestamp, 'FMDay')
ORDER BY day_number;


-- Visual 4: Orders by Hour of Day

SELECT
    EXTRACT(HOUR FROM order_purchase_timestamp)::integer AS order_hour,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY EXTRACT(HOUR FROM order_purchase_timestamp)
ORDER BY order_hour;


-- Visual 5: Order Status Distribution

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS order_percentage
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;



-- ============================================================
-- SECTION 3: CUSTOMER DASHBOARD
-- ============================================================


-- Visual 1: Unique Customers by State

SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers
GROUP BY customer_state
ORDER BY total_customers DESC;


-- Visual 2: Top 10 Cities by Unique Customers

SELECT
    customer_city,
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers
GROUP BY
    customer_city,
    customer_state
ORDER BY total_customers DESC
LIMIT 10;


-- KPI: Repeat Customers

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS repeat_customers
FROM customer_orders
WHERE total_orders > 1;


-- KPI: Repeat Customer Percentage

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (
        WHERE total_orders > 1
    ) AS repeat_customers,
    ROUND(
        COUNT(*) FILTER (WHERE total_orders > 1) * 100.0
        / COUNT(*),
        2
    ) AS repeat_customer_percentage
FROM customer_orders;


-- KPI: Average Orders per Customer

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    ROUND(AVG(total_orders), 2) AS average_orders_per_customer
FROM customer_orders;


-- Visual 3: Customer Revenue by State

SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;



-- ============================================================
-- SECTION 4: PRODUCT DASHBOARD
-- ============================================================


-- Visual 1: Top 10 Products by Revenue
-- The Olist products table does not contain a product name,
-- so product_id is used as the product identifier.

SELECT
    oi.product_id,
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,
    COUNT(*) AS quantity_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY
    oi.product_id,
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )
ORDER BY total_revenue DESC
LIMIT 10;


-- Visual 2: Category Performance

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,
    COUNT(*) AS quantity_sold,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS average_selling_price
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


-- Visual 3: Average Freight Cost by Category

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,
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
ORDER BY average_freight_cost DESC;


-- Visual 4: Product Price Distribution by Category

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,
    ROUND(MIN(oi.price), 2) AS minimum_price,
    ROUND(AVG(oi.price), 2) AS average_price,
    ROUND(MAX(oi.price), 2) AS maximum_price
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
ORDER BY average_price DESC;



-- ============================================================
-- SECTION 5: SELLER DASHBOARD
-- ============================================================


-- Visual 1: Top 10 Sellers by Revenue

SELECT
    oi.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
JOIN sellers s
    ON oi.seller_id = s.seller_id
GROUP BY
    oi.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY total_revenue DESC
LIMIT 10;


-- Visual 2: Seller Revenue by State

SELECT
    s.seller_state,
    COUNT(DISTINCT s.seller_id) AS total_sellers,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY s.seller_state
ORDER BY total_revenue DESC;


-- Visual 3: Average Review Score by Seller
-- DISTINCT prevents the same seller-order combination from being repeated
-- when an order contains multiple items from the same seller.

WITH seller_orders AS (
    SELECT DISTINCT
        seller_id,
        order_id
    FROM order_items
)
SELECT
    so.seller_id,
    s.seller_state,
    COUNT(DISTINCT so.order_id) AS reviewed_orders,
    ROUND(AVG(r.review_score), 2) AS average_review_score
FROM seller_orders so
JOIN sellers s
    ON so.seller_id = s.seller_id
JOIN order_reviews r
    ON so.order_id = r.order_id
GROUP BY
    so.seller_id,
    s.seller_state
ORDER BY average_review_score DESC;


-- Visual 4: Sellers Serving the Most Customer States

SELECT
    oi.seller_id,
    s.seller_state,
    COUNT(DISTINCT c.customer_state) AS customer_states_served
FROM order_items oi
JOIN sellers s
    ON oi.seller_id = s.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY
    oi.seller_id,
    s.seller_state
ORDER BY customer_states_served DESC;


-- Visual 5: Average Revenue per Seller by State

WITH seller_revenue AS (
    SELECT
        s.seller_id,
        s.seller_state,
        SUM(oi.price) AS total_revenue
    FROM sellers s
    JOIN order_items oi
        ON s.seller_id = oi.seller_id
    GROUP BY
        s.seller_id,
        s.seller_state
)
SELECT
    seller_state,
    COUNT(*) AS total_sellers,
    ROUND(AVG(total_revenue), 2) AS average_revenue_per_seller
FROM seller_revenue
GROUP BY seller_state
ORDER BY average_revenue_per_seller DESC;



-- ============================================================
-- SECTION 6: DELIVERY AND REVIEW DASHBOARD
-- ============================================================


-- KPI 1: Average Delivery Time in Days

SELECT
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_delivered_customer_date
                    - order_purchase_timestamp
                )
            ) / 86400
        ),
        2
    ) AS average_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


-- KPI 2: Total Late Deliveries

SELECT
    COUNT(*) AS late_deliveries
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
  AND order_delivered_customer_date
      > order_estimated_delivery_date;


-- KPI 3: On-Time Delivery Percentage

SELECT
    COUNT(*) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
              <= order_estimated_delivery_date
    ) AS on_time_deliveries,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_delivered_customer_date
                  <= order_estimated_delivery_date
        ) * 100.0 / COUNT(*),
        2
    ) AS on_time_delivery_percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- Visual 1: Average Delivery Time by Customer State

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    o.order_delivered_customer_date
                    - o.order_purchase_timestamp
                )
            ) / 86400
        ),
        2
    ) AS average_delivery_days
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY average_delivery_days DESC;


-- Visual 2: Delivery Status Distribution

SELECT
    CASE
        WHEN order_delivered_customer_date
             <= order_estimated_delivery_date
            THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS delivery_percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY
    CASE
        WHEN order_delivered_customer_date
             <= order_estimated_delivery_date
            THEN 'On Time'
        ELSE 'Late'
    END;


-- Visual 3: Delivery Time vs Review Score

WITH order_delivery AS (
    SELECT
        order_id,
        EXTRACT(
            EPOCH FROM (
                order_delivered_customer_date
                - order_purchase_timestamp
            )
        ) / 86400 AS delivery_days
    FROM orders
    WHERE order_delivered_customer_date IS NOT NULL
)
SELECT
    r.review_score,
    COUNT(DISTINCT d.order_id) AS total_orders,
    ROUND(AVG(d.delivery_days), 2) AS average_delivery_days
FROM order_delivery d
JOIN order_reviews r
    ON d.order_id = r.order_id
GROUP BY r.review_score
ORDER BY r.review_score;


-- Visual 4: Review Score Distribution

SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS review_percentage
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;



-- ============================================================
-- SECTION 7: PAYMENT DASHBOARD
-- ============================================================


-- Visual 1: Payment Method Usage

SELECT
    payment_type,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS usage_percentage
FROM order_payments
GROUP BY payment_type
ORDER BY payment_records DESC;


-- Visual 2: Payment Value by Payment Method
-- payment_value is summed directly from order_payments to avoid
-- duplicating payments through an order_items join.

SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


-- Visual 3: Average Transaction Value by Payment Method

SELECT
    payment_type,
    ROUND(AVG(payment_value), 2) AS average_transaction_value
FROM order_payments
GROUP BY payment_type
ORDER BY average_transaction_value DESC;


-- KPI: Average Number of Installments

SELECT
    ROUND(AVG(payment_installments), 2) AS average_installments
FROM order_payments
WHERE payment_installments > 0;


-- Visual 4: Installment Distribution

SELECT
    payment_installments,
    COUNT(*) AS total_payments,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS payment_percentage
FROM order_payments
WHERE payment_installments > 0
GROUP BY payment_installments
ORDER BY payment_installments;


-- Visual 5: Payment Type and Installment Summary

SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(payment_installments), 2) AS average_installments,
    ROUND(AVG(payment_value), 2) AS average_payment_value,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;