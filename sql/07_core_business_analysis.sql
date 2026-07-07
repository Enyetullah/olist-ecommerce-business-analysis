-- ============================================================
-- Project: Olist E-Commerce Business Performance Analysis
-- File: 07_core_business_analysis.sql
-- Purpose: Core SQL business analysis queries
-- ============================================================


-- ============================================================
-- 1. Executive KPI Summary
-- Business Question:
-- What are the overall business performance metrics?
-- ============================================================

SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS total_unique_customers,
    ROUND(SUM(total_order_item_value), 2) AS total_revenue,
    ROUND(AVG(total_order_item_value), 2) AS average_order_value,
    ROUND(AVG(average_review_score), 2) AS average_review_score,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days,
    ROUND(
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(SUM(CASE WHEN is_late IS NOT NULL THEN 1 ELSE 0 END), 0),
        2
    ) AS late_delivery_rate_percentage
FROM vw_order_analysis
WHERE order_status = 'delivered';


-- ============================================================
-- 2. Order Status Distribution
-- Business Question:
-- What percentage of orders were delivered, canceled, shipped, etc.?
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_orders
FROM vw_order_analysis
GROUP BY order_status
ORDER BY total_orders DESC;


-- ============================================================
-- 3. Monthly Revenue Trend
-- Business Question:
-- How has revenue changed over time?
-- ============================================================

SELECT
    order_month,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_order_item_value), 2) AS monthly_revenue,
    ROUND(AVG(total_order_item_value), 2) AS average_order_value
FROM vw_order_analysis
WHERE order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;


-- ============================================================
-- 4. Monthly Order Volume Trend
-- Business Question:
-- How many orders were placed each month?
-- ============================================================

SELECT
    order_month,
    COUNT(DISTINCT order_id) AS total_orders
FROM vw_order_analysis
GROUP BY order_month
ORDER BY order_month;


-- ============================================================
-- 5. Revenue by Customer State
-- Business Question:
-- Which states generate the most revenue?
-- ============================================================

SELECT
    customer_state,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    ROUND(SUM(total_order_item_value), 2) AS total_revenue,
    ROUND(AVG(total_order_item_value), 2) AS average_order_value
FROM vw_order_analysis
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY total_revenue DESC;


-- ============================================================
-- 6. Top Customer Cities by Revenue
-- Business Question:
-- Which cities generate the most revenue?
-- ============================================================

SELECT
    customer_city,
    customer_state,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    ROUND(SUM(total_order_item_value), 2) AS total_revenue
FROM vw_order_analysis
WHERE order_status = 'delivered'
GROUP BY customer_city, customer_state
ORDER BY total_revenue DESC
LIMIT 20;


-- ============================================================
-- 7. Revenue by Product Category
-- Business Question:
-- Which product categories generate the most revenue?
-- ============================================================

SELECT
    category,
    total_orders,
    total_items_sold,
    unique_products,
    unique_sellers,
    total_revenue,
    average_item_price,
    average_review_score
FROM vw_category_analysis
ORDER BY total_revenue DESC
LIMIT 20;


-- ============================================================
-- 8. Product Category Performance with Delivery and Reviews
-- Business Question:
-- Which categories have strong revenue, review scores, and delivery performance?
-- ============================================================

SELECT
    oie.product_category_name_english AS category,
    COUNT(DISTINCT oa.order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    ROUND(SUM(oie.item_total_value), 2) AS total_revenue,
    ROUND(AVG(oie.price), 2) AS average_item_price,
    ROUND(AVG(oa.average_review_score), 2) AS average_review_score,
    ROUND(AVG(oa.delivery_days), 2) AS average_delivery_days,
    ROUND(
        SUM(CASE WHEN oa.is_late = 1 THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(SUM(CASE WHEN oa.is_late IS NOT NULL THEN 1 ELSE 0 END), 0),
        2
    ) AS late_delivery_rate_percentage
FROM vw_order_items_enriched oie
JOIN vw_order_analysis oa
    ON oie.order_id = oa.order_id
WHERE oa.order_status = 'delivered'
GROUP BY oie.product_category_name_english
HAVING COUNT(DISTINCT oa.order_id) >= 50
ORDER BY total_revenue DESC;


-- ============================================================
-- 9. Top Sellers by Revenue
-- Business Question:
-- Which sellers generate the most revenue?
-- ============================================================

SELECT
    oie.seller_id,
    oie.seller_city,
    oie.seller_state,
    COUNT(DISTINCT oa.order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    COUNT(DISTINCT oie.product_id) AS unique_products_sold,
    ROUND(SUM(oie.item_total_value), 2) AS total_revenue,
    ROUND(AVG(oa.average_review_score), 2) AS average_review_score
FROM vw_order_items_enriched oie
JOIN vw_order_analysis oa
    ON oie.order_id = oa.order_id
WHERE oa.order_status = 'delivered'
GROUP BY
    oie.seller_id,
    oie.seller_city,
    oie.seller_state
ORDER BY total_revenue DESC
LIMIT 20;


-- ============================================================
-- 10. Seller State Performance
-- Business Question:
-- Which seller states contribute the most revenue?
-- ============================================================

SELECT
    oie.seller_state,
    COUNT(DISTINCT oie.seller_id) AS total_sellers,
    COUNT(DISTINCT oa.order_id) AS total_orders,
    ROUND(SUM(oie.item_total_value), 2) AS total_revenue,
    ROUND(AVG(oa.average_review_score), 2) AS average_review_score
FROM vw_order_items_enriched oie
JOIN vw_order_analysis oa
    ON oie.order_id = oa.order_id
WHERE oa.order_status = 'delivered'
GROUP BY oie.seller_state
ORDER BY total_revenue DESC;


-- ============================================================
-- 11. Payment Type Breakdown
-- Business Question:
-- Which payment methods are used the most?
-- ============================================================

SELECT
    op.payment_type,
    COUNT(*) AS total_payment_records,
    COUNT(DISTINCT op.order_id) AS total_orders,
    ROUND(SUM(op.payment_value), 2) AS total_payment_value,
    ROUND(AVG(op.payment_value), 2) AS average_payment_value
FROM order_payments op
JOIN orders o
    ON op.order_id = o.order_id
GROUP BY op.payment_type
ORDER BY total_payment_value DESC;


-- ============================================================
-- 12. Payment Installment Behavior
-- Business Question:
-- How often do customers use installments?
-- ============================================================

SELECT
    CASE
        WHEN payment_installments = 1 THEN 'One-time payment'
        WHEN payment_installments BETWEEN 2 AND 3 THEN '2-3 installments'
        WHEN payment_installments BETWEEN 4 AND 6 THEN '4-6 installments'
        WHEN payment_installments BETWEEN 7 AND 12 THEN '7-12 installments'
        ELSE 'More than 12 installments'
    END AS installment_group,
    COUNT(*) AS total_payment_records,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS average_payment_value
FROM order_payments
GROUP BY installment_group
ORDER BY total_payment_value DESC;


-- ============================================================
-- 13. Review Score Distribution
-- Business Question:
-- What does customer satisfaction look like overall?
-- ============================================================

SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_reviews
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;


-- ============================================================
-- 14. Average Review Score by Month
-- Business Question:
-- Did customer satisfaction change over time?
-- ============================================================

SELECT
    oa.order_month,
    COUNT(DISTINCT oa.order_id) AS total_reviewed_orders,
    ROUND(AVG(oa.average_review_score), 2) AS average_review_score
FROM vw_order_analysis oa
WHERE oa.average_review_score IS NOT NULL
GROUP BY oa.order_month
ORDER BY oa.order_month;


-- ============================================================
-- 15. Late Delivery Impact on Review Score
-- Business Question:
-- Do late deliveries affect customer satisfaction?
-- ============================================================

SELECT
    CASE
        WHEN is_late = 1 THEN 'Late'
        WHEN is_late = 0 THEN 'On Time'
        ELSE 'Unknown'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(AVG(average_review_score), 2) AS average_review_score,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days
FROM vw_order_analysis
WHERE average_review_score IS NOT NULL
  AND is_late IS NOT NULL
GROUP BY delivery_status
ORDER BY total_orders DESC;


-- ============================================================
-- 16. Delivery Performance by Customer State
-- Business Question:
-- Which states have the slowest delivery or highest late delivery rate?
-- ============================================================

SELECT
    customer_state,
    COUNT(DISTINCT order_id) AS delivered_orders,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days,
    ROUND(
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_percentage,
    ROUND(AVG(average_review_score), 2) AS average_review_score
FROM vw_order_analysis
WHERE order_status = 'delivered'
  AND is_late IS NOT NULL
GROUP BY customer_state
ORDER BY late_delivery_rate_percentage DESC;


-- ============================================================
-- 17. Average Delivery Time by Product Category
-- Business Question:
-- Which categories take longer to deliver?
-- ============================================================

SELECT
    oie.product_category_name_english AS category,
    COUNT(DISTINCT oa.order_id) AS total_orders,
    ROUND(AVG(oa.delivery_days), 2) AS average_delivery_days,
    ROUND(
        SUM(CASE WHEN oa.is_late = 1 THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(SUM(CASE WHEN oa.is_late IS NOT NULL THEN 1 ELSE 0 END), 0),
        2
    ) AS late_delivery_rate_percentage,
    ROUND(AVG(oa.average_review_score), 2) AS average_review_score
FROM vw_order_items_enriched oie
JOIN vw_order_analysis oa
    ON oie.order_id = oa.order_id
WHERE oa.order_status = 'delivered'
  AND oa.delivery_days IS NOT NULL
GROUP BY oie.product_category_name_english
HAVING COUNT(DISTINCT oa.order_id) >= 50
ORDER BY average_delivery_days DESC;


-- ============================================================
-- 18. Repeat Customer Rate
-- Business Question:
-- How many customers placed more than one order?
-- ============================================================

WITH customer_order_counts AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM vw_order_analysis
    WHERE customer_unique_id IS NOT NULL
    GROUP BY customer_unique_id
)

SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS repeat_customer_rate_percentage,
    ROUND(AVG(total_orders), 2) AS average_orders_per_customer
FROM customer_order_counts;


-- ============================================================
-- 19. Top Customers by Spending
-- Business Question:
-- Which customers spent the most?
-- ============================================================

SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_order_item_value), 2) AS total_spent,
    ROUND(AVG(total_order_item_value), 2) AS average_order_value
FROM vw_order_analysis
WHERE order_status = 'delivered'
  AND customer_unique_id IS NOT NULL
GROUP BY customer_unique_id
ORDER BY total_spent DESC
LIMIT 20;


-- ============================================================
-- 20. High Revenue but Low Satisfaction Categories
-- Business Question:
-- Which categories sell well but have weaker customer satisfaction?
-- ============================================================

WITH category_metrics AS (
    SELECT
        oie.product_category_name_english AS category,
        COUNT(DISTINCT oa.order_id) AS total_orders,
        ROUND(SUM(oie.item_total_value), 2) AS total_revenue,
        ROUND(AVG(oa.average_review_score), 2) AS average_review_score,
        ROUND(AVG(oa.delivery_days), 2) AS average_delivery_days
    FROM vw_order_items_enriched oie
    JOIN vw_order_analysis oa
        ON oie.order_id = oa.order_id
    WHERE oa.order_status = 'delivered'
      AND oa.average_review_score IS NOT NULL
    GROUP BY oie.product_category_name_english
    HAVING COUNT(DISTINCT oa.order_id) >= 100
)

SELECT *
FROM category_metrics
WHERE total_revenue > (
    SELECT AVG(total_revenue)
    FROM category_metrics
)
AND average_review_score < (
    SELECT AVG(average_review_score)
    FROM category_metrics
)
ORDER BY total_revenue DESC;