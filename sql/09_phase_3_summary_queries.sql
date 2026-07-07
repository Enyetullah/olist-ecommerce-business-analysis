-- ============================================================
-- Project: Olist E-Commerce Business Performance Analysis
-- File: 09_phase_3_summary_queries.sql
-- Purpose: Final summary numbers for README and dashboard
-- ============================================================


-- 1. Final Executive KPIs

SELECT
    COUNT(DISTINCT order_id) AS delivered_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
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


-- 2. Top 5 Revenue Categories

SELECT
    category,
    total_revenue
FROM vw_category_analysis
ORDER BY total_revenue DESC
LIMIT 5;


-- 3. Top 5 Customer States by Revenue

SELECT
    customer_state,
    ROUND(SUM(total_order_item_value), 2) AS total_revenue
FROM vw_order_analysis
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY total_revenue DESC
LIMIT 5;


-- 4. Payment Method Summary

SELECT
    payment_type,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


-- 5. Late vs On-Time Review Score

SELECT
    CASE
        WHEN is_late = 1 THEN 'Late'
        WHEN is_late = 0 THEN 'On Time'
        ELSE 'Unknown'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(AVG(average_review_score), 2) AS average_review_score
FROM vw_order_analysis
WHERE average_review_score IS NOT NULL
  AND is_late IS NOT NULL
GROUP BY delivery_status
ORDER BY total_orders DESC;


-- 6. Monthly Revenue for Dashboard

SELECT
    order_month,
    ROUND(SUM(total_order_item_value), 2) AS monthly_revenue,
    COUNT(DISTINCT order_id) AS total_orders
FROM vw_order_analysis
WHERE order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;


-- 7. Review Score Distribution

SELECT
    review_score,
    COUNT(*) AS total_reviews
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;