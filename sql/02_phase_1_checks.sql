-- ============================================================
-- Project: Olist E-Commerce Business Performance Analysis
-- File: 02_phase_1_checks.sql
-- Purpose: Confirm that all tables imported correctly
-- ============================================================


-- ============================================================
-- 1. Row count checks
-- ============================================================

SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM customers
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'product_category_translation', COUNT(*) FROM product_category_translation
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation
ORDER BY table_name;


-- ============================================================
-- 2. Preview each important table
-- ============================================================

SELECT *
FROM customers
LIMIT 10;

SELECT *
FROM orders
LIMIT 10;

SELECT *
FROM order_items
LIMIT 10;

SELECT *
FROM order_payments
LIMIT 10;

SELECT *
FROM order_reviews
LIMIT 10;

SELECT *
FROM products
LIMIT 10;


-- ============================================================
-- 3. Check date range of orders
-- ============================================================

SELECT
    MIN(order_purchase_timestamp) AS first_order_date,
    MAX(order_purchase_timestamp) AS last_order_date
FROM orders;


-- ============================================================
-- 4. Check order statuses
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- ============================================================
-- 5. Check payment types
-- ============================================================

SELECT
    payment_type,
    COUNT(*) AS total_payment_records
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_records DESC;


-- ============================================================
-- 6. Check customer states
-- ============================================================

SELECT
    customer_state,
    COUNT(*) AS total_customers
FROM customers
GROUP BY customer_state
ORDER BY total_customers DESC;


-- ============================================================
-- 7. Check seller states
-- ============================================================

SELECT
    seller_state,
    COUNT(*) AS total_sellers
FROM sellers
GROUP BY seller_state
ORDER BY total_sellers DESC;


-- ============================================================
-- 8. Check product categories
-- ============================================================

SELECT
    product_category_name,
    COUNT(*) AS total_products
FROM products
GROUP BY product_category_name
ORDER BY total_products DESC
LIMIT 20;