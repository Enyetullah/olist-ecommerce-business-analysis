-- ============================================================
-- Project: Olist E-Commerce Business Performance Analysis
-- File: 06_phase_2_summary_checks.sql
-- Purpose: Confirm Phase 2 cleaned views work correctly
-- ============================================================


-- ============================================================
-- 1. Check row count in main order analysis view
-- Expected: should match total rows in orders table
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM orders) AS raw_orders_count,
    (SELECT COUNT(*) FROM vw_order_analysis) AS analysis_view_count;


-- ============================================================
-- 2. Preview main order analysis view
-- ============================================================

SELECT *
FROM vw_order_analysis
LIMIT 20;


-- ============================================================
-- 3. Check revenue totals from item summary
-- ============================================================

SELECT
    ROUND(SUM(total_item_price), 2) AS total_product_revenue,
    ROUND(SUM(total_freight_value), 2) AS total_freight_value,
    ROUND(SUM(total_order_item_value), 2) AS total_order_value
FROM vw_order_items_summary;


-- ============================================================
-- 4. Check payment total
-- ============================================================

SELECT
    ROUND(SUM(total_payment_value), 2) AS total_payment_value
FROM vw_payments_summary;


-- ============================================================
-- 5. Compare item revenue and payment value
-- Note: These may not match exactly because of payment structure,
-- canceled orders, unavailable orders, or dataset differences.
-- ============================================================

SELECT
    ROUND((SELECT SUM(total_order_item_value) FROM vw_order_items_summary), 2) AS total_item_value,
    ROUND((SELECT SUM(total_payment_value) FROM vw_payments_summary), 2) AS total_payment_value,
    ROUND(
        (SELECT SUM(total_payment_value) FROM vw_payments_summary)
        -
        (SELECT SUM(total_order_item_value) FROM vw_order_items_summary),
        2
    ) AS difference;


-- ============================================================
-- 6. Check late delivery count
-- ============================================================

SELECT
    is_late,
    COUNT(*) AS total_orders
FROM vw_order_analysis
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY is_late
ORDER BY is_late;


-- ============================================================
-- 7. Check average delivery days
-- ============================================================

SELECT
    ROUND(AVG(delivery_days), 2) AS average_delivery_days
FROM vw_order_analysis
WHERE delivery_days IS NOT NULL;


-- ============================================================
-- 8. Check category analysis view
-- ============================================================

SELECT *
FROM vw_category_analysis
ORDER BY total_revenue DESC
LIMIT 20;


-- ============================================================
-- 9. Check seller analysis view
-- ============================================================

SELECT *
FROM vw_seller_analysis
ORDER BY total_revenue DESC
LIMIT 20;


-- ============================================================
-- 10. Check review score by delivery status
-- ============================================================

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
GROUP BY delivery_status
ORDER BY total_orders DESC;