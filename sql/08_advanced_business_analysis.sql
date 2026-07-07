-- ============================================================
-- Project: Olist E-Commerce Business Performance Analysis
-- File: 08_advanced_business_analysis.sql
-- Purpose: Advanced SQL analysis using CTEs and window functions
-- ============================================================


-- ============================================================
-- 1. Month-over-Month Revenue Growth
-- Business Question:
-- How fast is revenue growing or declining month over month?
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        order_month,
        SUM(total_order_item_value) AS revenue,
        COUNT(DISTINCT order_id) AS total_orders
    FROM vw_order_analysis
    WHERE order_status = 'delivered'
    GROUP BY order_month
),

monthly_revenue_with_lag AS (
    SELECT
        order_month,
        revenue,
        total_orders,
        LAG(revenue) OVER (ORDER BY order_month) AS previous_month_revenue,
        LAG(total_orders) OVER (ORDER BY order_month) AS previous_month_orders
    FROM monthly_revenue
)

SELECT
    order_month,
    ROUND(revenue, 2) AS revenue,
    total_orders,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    previous_month_orders,
    ROUND(
        (revenue - previous_month_revenue) * 100.0 /
        NULLIF(previous_month_revenue, 0),
        2
    ) AS revenue_growth_percentage,
    ROUND(
        (total_orders - previous_month_orders) * 100.0 /
        NULLIF(previous_month_orders, 0),
        2
    ) AS order_growth_percentage
FROM monthly_revenue_with_lag
WHERE previous_month_revenue IS NOT NULL
ORDER BY order_month;


-- ============================================================
-- 2. 3-Month Moving Average Revenue
-- Business Question:
-- What is the smoother revenue trend over time?
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        order_month,
        SUM(total_order_item_value) AS revenue
    FROM vw_order_analysis
    WHERE order_status = 'delivered'
    GROUP BY order_month
)

SELECT
    order_month,
    ROUND(revenue, 2) AS monthly_revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY order_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS three_month_moving_average_revenue
FROM monthly_revenue
ORDER BY order_month;


-- ============================================================
-- 3. Top 3 Product Categories in Each Customer State
-- Business Question:
-- What are the top product categories in each state?
-- ============================================================

WITH state_category_revenue AS (
    SELECT
        oa.customer_state,
        oie.product_category_name_english AS category,
        SUM(oie.item_total_value) AS total_revenue,
        COUNT(DISTINCT oa.order_id) AS total_orders
    FROM vw_order_items_enriched oie
    JOIN vw_order_analysis oa
        ON oie.order_id = oa.order_id
    WHERE oa.order_status = 'delivered'
    GROUP BY oa.customer_state, oie.product_category_name_english
),

ranked_categories AS (
    SELECT
        customer_state,
        category,
        total_revenue,
        total_orders,
        RANK() OVER (
            PARTITION BY customer_state
            ORDER BY total_revenue DESC
        ) AS category_rank
    FROM state_category_revenue
)

SELECT
    customer_state,
    category,
    ROUND(total_revenue, 2) AS total_revenue,
    total_orders,
    category_rank
FROM ranked_categories
WHERE category_rank <= 3
ORDER BY customer_state, category_rank;


-- ============================================================
-- 4. Seller Revenue Ranking by State
-- Business Question:
-- Who are the top sellers within each seller state?
-- ============================================================

WITH seller_revenue AS (
    SELECT
        oie.seller_state,
        oie.seller_id,
        oie.seller_city,
        SUM(oie.item_total_value) AS total_revenue,
        COUNT(DISTINCT oa.order_id) AS total_orders
    FROM vw_order_items_enriched oie
    JOIN vw_order_analysis oa
        ON oie.order_id = oa.order_id
    WHERE oa.order_status = 'delivered'
    GROUP BY oie.seller_state, oie.seller_id, oie.seller_city
),

ranked_sellers AS (
    SELECT
        seller_state,
        seller_id,
        seller_city,
        total_revenue,
        total_orders,
        RANK() OVER (
            PARTITION BY seller_state
            ORDER BY total_revenue DESC
        ) AS seller_rank
    FROM seller_revenue
)

SELECT
    seller_state,
    seller_id,
    seller_city,
    ROUND(total_revenue, 2) AS total_revenue,
    total_orders,
    seller_rank
FROM ranked_sellers
WHERE seller_rank <= 5
ORDER BY seller_state, seller_rank;


-- ============================================================
-- 5. Delivery Speed Buckets and Review Scores
-- Business Question:
-- How does delivery speed relate to review score?
-- ============================================================

SELECT
    CASE
        WHEN delivery_days <= 3 THEN '0-3 days'
        WHEN delivery_days BETWEEN 4 AND 7 THEN '4-7 days'
        WHEN delivery_days BETWEEN 8 AND 14 THEN '8-14 days'
        WHEN delivery_days BETWEEN 15 AND 30 THEN '15-30 days'
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
-- 6. Customer Segmentation by Spending and Frequency
-- Business Question:
-- How can customers be grouped by order behavior?
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


-- ============================================================
-- 7. Category Revenue Contribution Percentage
-- Business Question:
-- Which categories contribute the largest share of total revenue?
-- ============================================================

WITH category_revenue AS (
    SELECT
        oie.product_category_name_english AS category,
        SUM(oie.item_total_value) AS total_revenue
    FROM vw_order_items_enriched oie
    JOIN vw_order_analysis oa
        ON oie.order_id = oa.order_id
    WHERE oa.order_status = 'delivered'
    GROUP BY oie.product_category_name_english
),

total_revenue AS (
    SELECT
        SUM(total_revenue) AS grand_total_revenue
    FROM category_revenue
)

SELECT
    cr.category,
    ROUND(cr.total_revenue, 2) AS total_revenue,
    ROUND(cr.total_revenue * 100.0 / tr.grand_total_revenue, 2) AS revenue_contribution_percentage,
    RANK() OVER (ORDER BY cr.total_revenue DESC) AS revenue_rank
FROM category_revenue cr
CROSS JOIN total_revenue tr
ORDER BY total_revenue DESC
LIMIT 20;


-- ============================================================
-- 8. Seller Concentration Analysis
-- Business Question:
-- Is revenue concentrated among a small number of sellers?
-- ============================================================

WITH seller_revenue AS (
    SELECT
        oie.seller_id,
        SUM(oie.item_total_value) AS seller_revenue
    FROM vw_order_items_enriched oie
    JOIN vw_order_analysis oa
        ON oie.order_id = oa.order_id
    WHERE oa.order_status = 'delivered'
    GROUP BY oie.seller_id
),

ranked_sellers AS (
    SELECT
        seller_id,
        seller_revenue,
        RANK() OVER (ORDER BY seller_revenue DESC) AS revenue_rank,
        SUM(seller_revenue) OVER () AS total_revenue
    FROM seller_revenue
)

SELECT
    seller_id,
    ROUND(seller_revenue, 2) AS seller_revenue,
    revenue_rank,
    ROUND(seller_revenue * 100.0 / total_revenue, 2) AS revenue_percentage
FROM ranked_sellers
ORDER BY revenue_rank
LIMIT 20;


-- ============================================================
-- 9. Monthly Review Score and Late Delivery Trend
-- Business Question:
-- Are late deliveries and review scores changing over time?
-- ============================================================

SELECT
    order_month,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(average_review_score), 2) AS average_review_score,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days,
    ROUND(
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(SUM(CASE WHEN is_late IS NOT NULL THEN 1 ELSE 0 END), 0),
        2
    ) AS late_delivery_rate_percentage
FROM vw_order_analysis
WHERE order_status = 'delivered'
  AND average_review_score IS NOT NULL
  AND is_late IS NOT NULL
GROUP BY order_month
ORDER BY order_month;


-- ============================================================
-- 10. Categories With Highest Late Delivery Rate
-- Business Question:
-- Which product categories have the most delivery problems?
-- ============================================================

SELECT
    oie.product_category_name_english AS category,
    COUNT(DISTINCT oa.order_id) AS delivered_orders,
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
  AND oa.is_late IS NOT NULL
GROUP BY oie.product_category_name_english
HAVING COUNT(DISTINCT oa.order_id) >= 100
ORDER BY late_delivery_rate_percentage DESC;