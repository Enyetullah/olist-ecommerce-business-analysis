-- ============================================================
-- Project: Olist E-Commerce Business Performance Analysis
-- File: 04_data_validation_checks.sql
-- Purpose: Validate raw data quality before analysis
-- ============================================================


-- ============================================================
-- 1. Row Count Checks
-- Purpose: Confirm that all tables contain data
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
-- 2. Duplicate Primary Key Checks
-- Purpose: Make sure important ID columns are unique where expected
-- ============================================================

-- Duplicate customer IDs
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Duplicate seller IDs
SELECT
    seller_id,
    COUNT(*) AS duplicate_count
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


-- Duplicate product IDs
SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- Duplicate order IDs
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- Duplicate order item records
SELECT
    order_id,
    order_item_id,
    COUNT(*) AS duplicate_count
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;


-- Duplicate payment records
SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS duplicate_count
FROM order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;


-- ============================================================
-- 3. Missing Value Checks
-- Purpose: Identify important columns with missing values
-- ============================================================

-- Missing values in customers
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_unique_id,
    SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS missing_zip_code,
    SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) AS missing_city,
    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS missing_state
FROM customers;


-- Missing values in orders
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS missing_order_status,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_purchase_timestamp,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS missing_approved_at,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS missing_carrier_delivery_date,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS missing_customer_delivery_date,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS missing_estimated_delivery_date
FROM orders;


-- Missing values in order_items
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS missing_seller_id,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS missing_price,
    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS missing_freight_value
FROM order_items;


-- Missing values in products
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS missing_category,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS missing_weight,
    SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) AS missing_length,
    SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) AS missing_height,
    SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) AS missing_width
FROM products;


-- Missing values in reviews
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END) AS missing_review_id,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS missing_review_score,
    SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END) AS missing_review_creation_date,
    SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_review_answer_timestamp
FROM order_reviews;


-- ============================================================
-- 4. Invalid Numeric Value Checks
-- Purpose: Check for impossible or suspicious numeric values
-- ============================================================

-- Negative or zero prices
SELECT *
FROM order_items
WHERE price <= 0;


-- Negative freight values
SELECT *
FROM order_items
WHERE freight_value < 0;


-- Invalid payment values
SELECT *
FROM order_payments
WHERE payment_value <= 0;


-- Invalid review scores
SELECT *
FROM order_reviews
WHERE review_score < 1
   OR review_score > 5;


-- Invalid product measurements
SELECT *
FROM products
WHERE product_weight_g <= 0
   OR product_length_cm <= 0
   OR product_height_cm <= 0
   OR product_width_cm <= 0;


-- ============================================================
-- 5. Relationship Checks
-- Purpose: Make sure foreign-key style relationships are valid
-- ============================================================

-- Orders with customer IDs not found in customers table
SELECT
    o.order_id,
    o.customer_id
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- Order items with order IDs not found in orders table
SELECT
    oi.order_id
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- Order items with product IDs not found in products table
SELECT
    oi.order_id,
    oi.product_id
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Order items with seller IDs not found in sellers table
SELECT
    oi.order_id,
    oi.seller_id
FROM order_items oi
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- Payments with order IDs not found in orders table
SELECT
    op.order_id
FROM order_payments op
LEFT JOIN orders o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;


-- Reviews with order IDs not found in orders table
SELECT
    r.order_id
FROM order_reviews r
LEFT JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- 6. Date Consistency Checks
-- Purpose: Check whether order timeline dates make sense
-- ============================================================

-- Orders where approval happened before purchase
SELECT *
FROM orders
WHERE order_approved_at < order_purchase_timestamp;


-- Orders where carrier delivery happened before purchase
SELECT *
FROM orders
WHERE order_delivered_carrier_date < order_purchase_timestamp;


-- Orders where customer delivery happened before purchase
SELECT *
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;


-- Orders where customer delivery happened before carrier delivery
SELECT *
FROM orders
WHERE order_delivered_customer_date < order_delivered_carrier_date;


-- Delivered orders missing customer delivery date
SELECT *
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;


-- Non-delivered orders that still have a customer delivery date
SELECT *
FROM orders
WHERE order_status <> 'delivered'
  AND order_delivered_customer_date IS NOT NULL;


-- ============================================================
-- 7. Category Translation Checks
-- Purpose: Find product categories without English translation
-- ============================================================

SELECT
    p.product_category_name,
    COUNT(*) AS product_count
FROM products p
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND pct.product_category_name_english IS NULL
GROUP BY p.product_category_name
ORDER BY product_count DESC;


-- ============================================================
-- 8. Order Status Distribution
-- Purpose: Understand the status breakdown of orders
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- ============================================================
-- 9. Review Score Distribution
-- Purpose: Understand customer satisfaction distribution
-- ============================================================

SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_reviews
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;


-- ============================================================
-- 10. Payment Type Distribution
-- Purpose: Understand customer payment behavior
-- ============================================================

SELECT
    payment_type,
    COUNT(*) AS total_payment_records,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;