-- ============================================================
-- Project: Olist E-Commerce Business Performance Analysis
-- File: 10_powerbi_export_queries.sql
-- Purpose: Export clean datasets for Power BI dashboard
-- ============================================================


-- ============================================================
-- 1. Executive Order Analysis Dataset
-- Use this as the main dashboard table.
-- Export as: powerbi_order_analysis.csv
-- ============================================================

SELECT
    order_id,
    customer_unique_id,
    customer_city,
    customer_state,
    order_status,
    order_status_group,
    order_purchase_timestamp,
    order_month,
    order_year,
    delivery_days,
    estimated_delivery_days,
    is_late,
    total_items,
    unique_products,
    unique_sellers,
    total_item_price,
    total_freight_value,
    total_order_item_value,
    total_payment_value,
    payment_types,
    max_installments,
    average_review_score
FROM vw_order_analysis;


-- ============================================================
-- 2. Product Category Analysis Dataset
-- Export as: powerbi_category_analysis.csv
-- ============================================================

SELECT
    category,
    total_orders,
    total_items_sold,
    unique_products,
    unique_sellers,
    total_product_revenue,
    total_freight_revenue,
    total_revenue,
    average_item_price,
    average_review_score
FROM vw_category_analysis;


-- ============================================================
-- 3. Seller Analysis Dataset
-- Export as: powerbi_seller_analysis.csv
-- ============================================================

SELECT
    seller_id,
    seller_city,
    seller_state,
    total_orders,
    total_items_sold,
    unique_products_sold,
    total_product_revenue,
    total_freight_value,
    total_revenue,
    average_review_score
FROM vw_seller_analysis;


-- ============================================================
-- 4. Monthly Revenue Dataset
-- Export as: powerbi_monthly_revenue.csv
-- ============================================================

SELECT
    order_month,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_order_item_value), 2) AS monthly_revenue,
    ROUND(AVG(total_order_item_value), 2) AS average_order_value,
    ROUND(AVG(average_review_score), 2) AS average_review_score,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days,
    ROUND(
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(SUM(CASE WHEN is_late IS NOT NULL THEN 1 ELSE 0 END), 0),
        2
    ) AS late_delivery_rate_percentage
FROM vw_order_analysis
WHERE order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;


-- ============================================================
-- 5. Customer State Performance Dataset
-- Export as: powerbi_state_performance.csv
-- ============================================================

SELECT
    customer_state,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    ROUND(SUM(total_order_item_value), 2) AS total_revenue,
    ROUND(AVG(total_order_item_value), 2) AS average_order_value,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days,
    ROUND(
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(SUM(CASE WHEN is_late IS NOT NULL THEN 1 ELSE 0 END), 0),
        2
    ) AS late_delivery_rate_percentage,
    ROUND(AVG(average_review_score), 2) AS average_review_score
FROM vw_order_analysis
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY total_revenue DESC;


-- ============================================================
-- 6. Delivery Review Analysis Dataset
-- Export as: powerbi_delivery_review_analysis.csv
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
-- 7. Delivery Speed Bucket Dataset
-- Export as: powerbi_delivery_speed_buckets.csv
-- ============================================================

SELECT
    CASE
        WHEN delivery_days < 4 THEN '0-3 days'
        WHEN delivery_days < 8 THEN '4-7 days'
        WHEN delivery_days < 15 THEN '8-14 days'
        WHEN delivery_days < 31 THEN '15-30 days'
        ELSE 'More than 30 days'
    END AS delivery_speed_bucket,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days,
    ROUND(AVG(average_review_score), 2) AS average_review_score,
    ROUND(
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(SUM(CASE WHEN is_late IS NOT NULL THEN 1 ELSE 0 END), 0),
        2
    ) AS late_delivery_rate_percentage
FROM vw_order_analysis
WHERE order_status = 'delivered'
  AND delivery_days IS NOT NULL
  AND average_review_score IS NOT NULL
GROUP BY delivery_speed_bucket
ORDER BY average_delivery_days;


-- ============================================================
-- 8. Payment Type Dataset
-- Export as: powerbi_payment_type.csv
-- ============================================================

SELECT
    payment_type,
    COUNT(*) AS total_payment_records,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS average_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


-- ============================================================
-- 9. Review Score Distribution Dataset
-- Export as: powerbi_review_score_distribution.csv
-- ============================================================

SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_reviews
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;


-- ============================================================
-- 10. Customer Segment Dataset
-- Export as: powerbi_customer_segments.csv
-- ============================================================

WITH customer_metrics AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(total_order_item_value) AS total_spent,
        AVG(total_order_item_value) AS average_order_value
    FROM vw_order_analysis
    WHERE order_status = 'delivered'
      AND customer_unique_id IS NOT NULL
    GROUP BY customer_unique_id
),

customer_segments AS (
    SELECT
        customer_unique_id,
        total_orders,
        total_spent,
        average_order_value,
        CASE
            WHEN total_orders >= 3 AND total_spent >= 1000 THEN 'High-value repeat customer'
            WHEN total_orders >= 2 THEN 'Repeat customer'
            WHEN total_spent >= 500 THEN 'High-value one-time customer'
            ELSE 'One-time or low-value customer'
        END AS customer_segment
    FROM customer_metrics
)

SELECT
    customer_segment,
    COUNT(*) AS total_customers,
    ROUND(AVG(total_orders), 2) AS average_orders,
    ROUND(AVG(total_spent), 2) AS average_total_spent,
    ROUND(SUM(total_spent), 2) AS segment_revenue
FROM customer_segments
GROUP BY customer_segment
ORDER BY segment_revenue DESC;