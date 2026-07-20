 SET search_path TO olist;
-- ============================================================
-- SECTION 1: SALES KPI ANALYSIS
-- ============================================================

-- QUESTION 1 - What is the total sales revenue?


SELECT
    SUM(price) AS total_sales_revenue
FROM order_items;



-- QUESTION 2 - How many orders were placed?


SELECT
    COUNT(order_id) AS total_orders
FROM orders;



-- QUESTION 3 - What is the average order value?


SELECT
    ROUND(AVG(order_total), 2) AS average_order_value
FROM (
    SELECT
        order_id,
        SUM(price) AS order_total
    FROM order_items
    GROUP BY order_id
) AS order_totals;



-- QUESTION 4 - Which product categories generate the most revenue?


SELECT
    ct.product_category_name_english AS category,
    SUM(oi.price) AS total_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY
    ct.product_category_name_english
ORDER BY
    total_revenue DESC;



-- QUESTION 5 - Which states have the highest sales?


SELECT
    c.customer_state,
    ROUND(SUM(oi.price), 2) AS total_sales
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    c.customer_state
ORDER BY
    total_sales DESC Limit 10;

-- Q6. Which customer cities generate the highest sales?

SELECT
    c.customer_city,
    ROUND(SUM(oi.price), 2) AS total_sales
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    c.customer_city
ORDER BY
    total_sales DESC Limit 10;

-- Q7. What are the top 10 highest-value orders?

SELECT 
	O.order_id, SUM(OI.price) AS Order_value
From	
	orders O JOIN order_items OI
	ON O.order_id = OI.order_id
GROUP BY
	O.order_id
ORDER BY 
	Order_value DESC LIMIT 10;



-- ============================================================
-- SECTION 2: PRODUCT PERFORMANCE ANALYSIS
-- ============================================================

SELECT
    product_id,
    SUM(price) AS revenue
FROM order_items
GROUP BY
    product_id
ORDER BY
    revenue DESC;
	
	

-- Q9. Which products are sold the most (by quantity)?

SELECT product_id, COUNT(product_id) AS QUANTITY_SOLD
FROM
	order_items
GROUP BY product_id
ORDER BY QUANTITY_SOLD DESC;
-- Q10. Which product categories sell the highest quantity?

SELECT CT.product_category_name_english, COUNT(OI.product_id) AS QUANTITY_SOLD 
FROM category_translation CT JOIN products P
ON CT.product_category_name = P.product_category_name 
JOIN order_items OI 
ON P.product_id = OI.product_id 
GROUP BY CT.product_category_name_english 
ORDER BY QUANTITY_SOLD DESC
LIMIT 10;

-- Q11. What is the average selling price of each product category?

SELECT CT.product_category_name_english, ROUND(AVG(OI.price),2) AS AVG_SELLING_PRICE
FROM category_translation CT JOIN products P
ON CT.product_category_name = P.product_category_name 
JOIN order_items OI 
ON P.product_id = OI.product_id 
GROUP BY CT.product_category_name_english 
ORDER BY AVG_SELLING_PRICE DESC
LIMIT 10;

-- Q12. Which product categories have the highest average freight cost?

SELECT CT.product_category_name_english, ROUND(AVG(OI.freight_value),2) AS AVG_FREIGHT_VALUE
FROM category_translation CT JOIN products P
ON CT.product_category_name = P.product_category_name 
JOIN order_items OI 
ON P.product_id = OI.product_id 
GROUP BY CT.product_category_name_english 
ORDER BY AVG_FREIGHT_VALUE DESC
LIMIT 10;



-- ============================================================
-- SECTION 3: SELLER PERFORMANCE ANALYSIS
-- ============================================================

-- Q13. Who are the top 10 sellers by revenue?

SELECT seller_id, SUM(price) AS REVENUE
FROM order_items
GROUP BY seller_id
ORDER BY REVENUE DESC
LIMIT 10;

-- Q14. Which seller states generate the highest revenue?

SELECT S.seller_state, SUM(OI.price) AS REVENUE
FROM order_items OI JOIN sellers S
ON OI.seller_id = S.seller_id
GROUP BY S.seller_state
ORDER BY REVENUE DESC
LIMIT 10;


-- Q15. Which sellers have fulfilled the most orders?

WITH seller_orders AS (
    SELECT DISTINCT
        seller_id,
        order_id
    FROM order_items
)
SELECT
    so.seller_id,
    ROUND(AVG(orv.review_score), 2) AS average_review_score
FROM seller_orders so
JOIN order_reviews orv
    ON so.order_id = orv.order_id
GROUP BY
    so.seller_id
ORDER BY
    average_review_score DESC
LIMIT 10;

-- Q16. What is the average revenue generated per seller?

WITH SELLER_REVENUE AS (
SELECT seller_id, SUM(price) AS TOTAL_REVENUE
FROM
	order_items
GROUP BY 
	seller_id
	)
SELECT ROUND(AVG(TOTAL_REVENUE),2) AS AVG_REVENUE_PER_SELLER
FROM SELLER_REVENUE;


-- ============================================================
-- SECTION 4: CUSTOMER ANALYSIS
-- ============================================================

-- Q17. Which states have the highest number of customers?

SELECT customer_state, COUNT(customer_id) AS NO_OF_CUSTOMERS
FROM customers
GROUP BY customer_state
ORDER BY NO_OF_CUSTOMERS DESC;

-- Q18. Which cities have the highest number of customers?

SELECT customer_city, COUNT(customer_id) AS NO_OF_CUSTOMERS
FROM customers
GROUP BY customer_city
ORDER BY NO_OF_CUSTOMERS DESC;

-- Q19. Which customers placed more than one order?

SELECT C.customer_unique_id, COUNT(O.order_id) AS NO_OF_ORDERS
FROM customers C JOIN orders O
ON C.customer_id = O.customer_id
GROUP BY C.customer_unique_id
HAVING COUNT(O.order_id)>1
ORDER BY NO_OF_ORDERS DESC;

-- Q20. What is the average number of orders per customer?

WITH NO_OF_ORDERS AS (
SELECT C.customer_unique_id, COUNT(O.order_id) AS NO_OF_CUSTOMER_ORDERS
FROM customers C JOIN orders O
ON C.customer_id = O.customer_id
GROUP BY C.customer_unique_id
)
SELECT ROUND(AVG(NO_OF_CUSTOMER_ORDERS),2) FROM NO_OF_ORDERS;

-- ============================================================
-- SECTION 5: DELIVERY PERFORMANCE ANALYSIS
-- ============================================================

-- Q21. What is the average delivery time?

SELECT
    ROUND(AVG(
            EXTRACT(EPOCH FROM
                (order_delivered_customer_date - order_purchase_timestamp)) / 86400 ),2)
				AS AVG_DELIVERY_DAYS
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- Q22. Which states have the longest average delivery time?

WITH DELIVER_TIME AS (
SELECT C.customer_state,
ROUND(AVG(EXTRACT(EPOCH FROM(O.order_delivered_customer_date - O.order_purchase_timestamp))
/86400),2) AS AVG_DELIVERY_DAYS
FROM orders O
JOIN customers C
ON C.customer_id = O.customer_id
WHERE O.order_delivered_customer_date IS NOT NULL
GROUP BY C.customer_state)

SELECT * FROM DELIVER_TIME
ORDER BY AVG_DELIVERY_DAYS DESC;


-- Q23. How many orders were delivered after the estimated delivery date?

WITH LATE_DELIVERY AS (SELECT COUNT(*) AS NO_OF_ORDERS_DELIVERED_LATE
FROM orders
WHERE order_estimated_delivery_date<order_delivered_customer_date
AND order_delivered_customer_date IS NOT NULL)
SELECT * FROM LATE_DELIVERY;

-- Q24. What percentage of orders were delivered on time?

WITH TOTAL_ORDERS AS (
SELECT COUNT(*) AS TOTAL_ORDERS_PLACED
FROM orders
WHERE order_delivered_customer_date IS NOT NULL),

LATE_DELIVERY AS (
SELECT COUNT(*) AS NO_OF_ORDERS_DELIVERED_LATE
FROM orders
WHERE order_delivered_customer_date::DATE > order_estimated_delivery_date
AND order_delivered_customer_date IS NOT NULL)

SELECT ROUND((t.TOTAL_ORDERS_PLACED - L.NO_OF_ORDERS_DELIVERED_LATE)
*100.0/t.TOTAL_ORDERS_PLACED,2)AS ON_TIME_DELIVERY_PERCENTAGE
FROM TOTAL_ORDERS t CROSS JOIN LATE_DELIVERY L;



-- ============================================================
-- SECTION 6: CUSTOMER REVIEW ANALYSIS
-- Purpose:
-- Analyze customer satisfaction using review scores.
-- ============================================================

-- Q25. What is the average review score?

SELECT ROUND(AVG(review_score),2) AS AVG_REVIEW_SCORE
FROM order_reviews;

-- Q26. How are review scores distributed?
SELECT review_score, COUNT(review_score) AS no_of_reviews
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- Q27. Which product categories have the highest average review score?

WITH order_categories AS (
    SELECT DISTINCT
        oi.order_id,
        ct.product_category_name_english AS category
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name)
SELECT
    oc.category,
    ROUND(AVG(orr.review_score), 2) AS avg_review_score
FROM order_categories oc
JOIN order_reviews orr
    ON oc.order_id = orr.order_id
GROUP BY
    oc.category
ORDER BY
    avg_review_score DESC;

-- Q28. Which product categories have the lowest average review score?

WITH order_categories AS (
    SELECT DISTINCT
        oi.order_id,
        ct.product_category_name_english AS category
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name)
SELECT
    oc.category,
    ROUND(AVG(orr.review_score), 2) AS avg_review_score
FROM order_categories oc
JOIN order_reviews orr
    ON oc.order_id = orr.order_id
GROUP BY
    oc.category
ORDER BY
    avg_review_score ASC;

-- Q29. Does delivery time affect review scores?

SELECT ROUND(AVG(EXTRACT(EPOCH FROM(O.order_delivered_customer_date - O.order_purchase_timestamp))/86400),2)
AS AVG_DELIVERY_DAYS, ORR.review_score AS REVIEW_SCORE
FROM Orders O JOIN order_reviews ORR
ON O.order_id = ORR.order_id
WHERE O.order_delivered_customer_date IS NOT NULL
GROUP BY REVIEW_SCORE
ORDER BY REVIEW_SCORE ASC;

-- ============================================================
-- SECTION 7: PAYMENT ANALYSIS
-- Purpose:
-- Analyze customer payment behavior and payment methods.
-- ============================================================

-- Q30. Which payment methods are most commonly used?

SELECT payment_type, COUNT(*) AS COUNTS
FROM order_payments
GROUP BY payment_type
ORDER BY COUNTS DESC;

-- Q31. Which payment methods generate the highest revenue?

SELECT payment_type, SUM(payment_value) AS highest_revenue
FROM order_payments 
GROUP BY payment_type
ORDER BY highest_revenue DESC;

-- Q32. What is the average payment installment count?

SELECT ROUND(AVG(payment_installments),2)
FROM order_payments
WHERE payment_installments != 0;

-- Q33. Which payment method has the highest average transaction value?

SELECT payment_type, ROUND(AVG(payment_value),2) AS highest_revenue
FROM order_payments 
GROUP BY payment_type
ORDER BY highest_revenue DESC;

-- ============================================================
-- SECTION 8: TIME-BASED SALES ANALYSIS
-- Purpose:
-- Analyze sales trends and seasonal business performance.
-- ============================================================

-- Q34. What are the monthly sales trends?

SELECT DATE_TRUNC('month', O.order_purchase_timestamp)::DATE AS ORDERED_MONTH, 
	SUM(OP.payment_value) AS total_sales
FROM orders O JOIN order_payments OP
ON O.order_id = OP.order_id
GROUP BY ORDERED_MONTH
ORDER BY ORDERED_MONTH;

-- Q35. What are the monthly order trends?

SELECT DATE_TRUNC('month', order_purchase_timestamp)::DATE AS ORDERED_MONTH, 
	COUNT(order_id) AS total_orders
FROM orders
GROUP BY ORDERED_MONTH
ORDER BY ORDERED_MONTH;

-- Q36. Which month generated the highest revenue?

SELECT DATE_TRUNC('month', O.order_purchase_timestamp)::DATE AS ORDERED_MONTH, 
	SUM(OP.payment_value) AS total_sales
FROM orders O JOIN order_payments OP
ON O.order_id = OP.order_id
GROUP BY ORDERED_MONTH
ORDER BY total_sales DESC 
LIMIT 1;

-- Q37. Which month had the highest number of orders?

SELECT DATE_TRUNC('month', order_purchase_timestamp)::DATE AS ORDERED_MONTH, 
	COUNT(order_id) AS total_orders
FROM orders
GROUP BY ORDERED_MONTH
ORDER BY total_orders DESC
LIMIT 1;


-- Q38. What is the month-over-month revenue growth?

-- Q38. What is the month-over-month revenue growth?

WITH monthly_sales AS (
    SELECT DATE_TRUNC('month', O.order_purchase_timestamp)::DATE AS ordered_month,
    SUM(OP.payment_value) AS monthly_revenue
    FROM orders O
    JOIN order_payments OP
    ON O.order_id = OP.order_id
    GROUP BY ordered_month
),

previous_month_sales AS (
    SELECT ordered_month, monthly_revenue,
        LAG(monthly_revenue) OVER (ORDER BY ordered_month) AS previous_month_revenue
    FROM monthly_sales
)

SELECT
    ordered_month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND((monthly_revenue - previous_month_revenue)
        * 100.0 / previous_month_revenue,2) 
		AS mom_growth_percentage
FROM previous_month_sales
ORDER BY ordered_month;

-- ============================================================
-- SECTION 9: ADVANCED BUSINESS ANALYSIS
-- Purpose:
-- Solve advanced business problems using complex SQL queries.
-- ============================================================

-- Q39. Which orders generated the highest revenue?

SELECT O.order_id, SUM(OP.payment_value) AS revenue
FROM orders O JOIN order_payments OP
ON O.order_id = OP.order_id
GROUP BY O.order_id
ORDER BY revenue DESC
LIMIT 10;

-- Q40. Which sellers sell across the most customer states?

SELECT S.seller_id, COUNT(DISTINCT C.customer_state) AS NO_OF_STATES
FROM sellers S JOIN order_items OI
ON S.seller_id = OI.seller_id
JOIN orders O
ON O.order_id = OI.order_id
JOIN customers C 
ON C.customer_id = O.customer_id
GROUP BY S.seller_id
ORDER BY NO_OF_STATES DESC;

-- Q41. Which customer states purchase the widest variety of product categories?

SELECT C.customer_state,COUNT(DISTINCT(CT.product_category_name_english)) AS NO_OF_CATEGORIES,
STRING_AGG(DISTINCT CT.product_category_name_english,', '
ORDER BY CT.product_category_name_english) AS categories
FROM category_translation CT JOIN products P
ON CT.product_category_name = P.product_category_name
JOIN order_items OI
ON OI.product_id = P.product_id
JOIN orders O
ON O.order_id = OI.order_id
JOIN customers C
ON C.customer_id = O.customer_id
GROUP BY C.customer_state
ORDER BY NO_OF_CATEGORIES DESC;


-- Q42. What percentage of total revenue comes from the top 10 product categories?

WITH category_revenue AS (
    SELECT
        p.product_category_name,
        SUM(oi.price) AS category_revenue
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    GROUP BY
        p.product_category_name
),
top_10_categories AS (
    SELECT
        product_category_name,
        category_revenue
    FROM category_revenue
    ORDER BY
        category_revenue DESC
    LIMIT 10
)
SELECT
    ROUND(
        SUM(t.category_revenue) * 100.0
        / (SELECT SUM(category_revenue) FROM category_revenue),
        2
    ) AS top_10_revenue_percentage
FROM top_10_categories t;

-- Q43. What percentage of total revenue comes from the top 10 sellers?

WITH SELLER_REVENUE AS(
SELECT S.seller_id,SUM(OI.price) AS REVENUE
FROM sellers S JOIN order_items OI
ON S.seller_id = OI.seller_id
GROUP BY S.seller_id
ORDER BY REVENUE DESC
),
TOP10_SELLER AS(
SELECT seller_id,REVENUE FROM  SELLER_REVENUE
LIMIT 10
)
SELECT
    ROUND(
        SUM(SR.REVENUE) * 100.0
        / (SELECT SUM(REVENUE) FROM SELLER_REVENUE),
        2
    ) AS top_10_seller_revenue_percentage
FROM TOP10_SELLER SR;

-- Q44. Which product categories have the highest average order value?

WITH CATEGORY_ORDER_VALUE AS(
SELECT P.product_category_name,SUM(OI.price) AS ORDER_VALUE
FROM order_items OI 
JOIN products P
ON OI.product_id = P.product_id
GROUP BY P.product_category_name
)
SELECT CT.product_category_name_english AS CATEGORY,
ROUND(AVG(COV.ORDER_VALUE),2) AS AVG_ORDER_VALUE
FROM category_translation CT 
JOIN CATEGORY_ORDER_VALUE COV
ON CT.product_category_name = COV.product_category_name 
GROUP BY
    CT.product_category_name_english
ORDER BY
    AVG_ORDER_VALUE DESC
LIMIT 10;

-- Q45. Which sellers have the strongest review performance

WITH order_sellers AS (
SELECT DISTINCT
order_id, seller_id
FROM order_items
),

seller_reviews AS (
SELECT os.seller_id, COUNT(*) AS review_count,
AVG(orr.review_score) AS avg_review_score
FROM order_sellers os
JOIN order_reviews orr
ON os.order_id = orr.order_id
GROUP BY os.seller_id
),

AVG_REVIEWS AS (
SELECT AVG(review_count) AS order_reviews
FROM seller_reviews
),

review_benchmark AS (
SELECT AVG(review_score) AS global_avg_score
FROM order_reviews
)

SELECT sr.seller_id,sr.review_count,
ROUND(sr.avg_review_score, 2) AS avg_review_score,
ROUND((sr.review_count * sr.avg_review_score + AR.order_reviews * rb.global_avg_score)/ 
(sr.review_count + AR.order_reviews),2) 
AS weighted_review_score
FROM seller_reviews sr
CROSS JOIN review_benchmark rb,
AVG_REVIEWS AR
ORDER BY
weighted_review_score DESC,
review_count DESC
LIMIT 10;



-- Q46. Which seller generated the highest revenue in each state?

SELECT oi.seller_id,c.customer_state,
ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN orders o
ON oi.order_id = o.order_id
JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY oi.seller_id, c.customer_state
ORDER BY revenue DESC;


-- Q47. Which product category contributes the most freight cost?

SELECT CT.product_category_name_english,
	SUM(OI.freight_value) AS CATEGORY_FREIGHT_VALUE
FROM Products P
JOIN order_items OI
ON P.product_id = OI.product_id
JOIN category_translation CT
ON CT.product_category_name = P.product_category_name
GROUP BY CT.product_category_name_english
ORDER BY CATEGORY_FREIGHT_VALUE DESC;

-- Q48. Which customer state has the highest average order value?

WITH ORDER_VALUE AS (
SELECT C.customer_state,SUM(OI.price) AS TOTAL_ORDER_VALUE 
FROM customers C 
JOIN orders O 
ON C.customer_id = O.customer_id 
JOIN order_items OI 
ON OI.order_id = O.order_id 
GROUP BY  O.order_id,C.customer_state
)

SELECT customer_state,ROUND(AVG(TOTAL_ORDER_VALUE),2) AS AVG_ORDER_VALUE
FROM ORDER_VALUE
GROUP BY customer_state
ORDER BY customer_state DESC
LIMIT 1;

-- Q49. Which day of the week has the highest number of orders?

SELECT TO_CHAR(order_purchase_timestamp, 'Day') AS day_of_week,
COUNT(order_id) AS total_orders
FROM orders
GROUP BY day_of_week
ORDER BY total_orders DESC
LIMIT 1;

-- Q50. Which hour of the day receives the most orders?
SELECT EXTRACT(HOUR FROM order_purchase_timestamp)AS hour_of_day,
COUNT(order_id) AS total_orders
FROM orders
GROUP BY hour_of_day
ORDER BY total_orders DESC
LIMIT 1;
