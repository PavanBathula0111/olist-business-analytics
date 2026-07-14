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

-- Q23. How many orders were delivered after the estimated delivery date?

-- Q24. What percentage of orders were delivered on time?



-- ============================================================
-- SECTION 6: CUSTOMER REVIEW ANALYSIS
-- Purpose:
-- Analyze customer satisfaction using review scores.
-- ============================================================

-- Q25. What is the average review score?

-- Q26. How are review scores distributed?

-- Q27. Which product categories have the highest average review score?

-- Q28. Which product categories have the lowest average review score?

-- Q29. Does delivery time affect review scores?



-- ============================================================
-- SECTION 7: PAYMENT ANALYSIS
-- Purpose:
-- Analyze customer payment behavior and payment methods.
-- ============================================================

-- Q30. Which payment methods are most commonly used?

-- Q31. Which payment methods generate the highest revenue?

-- Q32. What is the average payment installment count?

-- Q33. Which payment method has the highest average transaction value?



-- ============================================================
-- SECTION 8: TIME-BASED SALES ANALYSIS
-- Purpose:
-- Analyze sales trends and seasonal business performance.
-- ============================================================

-- Q34. What are the monthly sales trends?

-- Q35. What are the monthly order trends?

-- Q36. Which month generated the highest revenue?

-- Q37. Which month had the highest number of orders?

-- Q38. What is the month-over-month revenue growth?



-- ============================================================
-- SECTION 9: ADVANCED BUSINESS ANALYSIS
-- Purpose:
-- Solve advanced business problems using complex SQL queries.
-- ============================================================

-- Q39. Which orders generated the highest revenue?

-- Q40. Which sellers sell across the most customer states?

-- Q41. Which customer states purchase the widest variety of product categories?

-- Q42. What percentage of total revenue comes from the top 10 product categories?

-- Q43. What percentage of total revenue comes from the top 10 sellers?

-- Q44. Which product categories have the highest average order value?

-- Q45. Which seller has the highest average review score?

-- Q46. Which seller generated the highest revenue in each state?

-- Q47. Which product category contributes the most freight cost?

-- Q48. Which customer state has the highest average order value?

-- Q49. Which day of the week has the highest number of orders?

-- Q50. Which hour of the day receives the most orders?