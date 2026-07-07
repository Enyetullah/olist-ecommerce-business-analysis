-- ============================================================
-- Project: Olist E-Commerce Business Performance Analysis
-- File: 05_create_clean_analysis_views.sql
-- Purpose: Create cleaned and analysis-ready SQL views
-- ============================================================


-- ============================================================
-- 1. Product Category View
-- Purpose: Add English category names and handle missing categories
-- ============================================================

CREATE OR REPLACE VIEW vw_products_cleaned AS
SELECT
    p.product_id,
    p.product_category_name,
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS product_category_name_english,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM products p
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name;


-- ============================================================
-- 2. Order Items Enriched View
-- Purpose: Add product, category, and seller information to each order item
-- ============================================================

CREATE OR REPLACE VIEW vw_order_items_enriched AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    pc.product_category_name_english,
    oi.seller_id,
    s.seller_city,
    s.seller_state,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,
    ROUND(oi.price + oi.freight_value, 2) AS item_total_value
FROM order_items oi
LEFT JOIN vw_products_cleaned pc
    ON oi.product_id = pc.product_id
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id;


-- ============================================================
-- 3. Order Items Summary View
-- Purpose: Create one row per order from order_items
-- This avoids row multiplication when joining order_items with payments.
-- ============================================================

CREATE OR REPLACE VIEW vw_order_items_summary AS
SELECT
    order_id,
    COUNT(*) AS total_items,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(DISTINCT seller_id) AS unique_sellers,
    ROUND(SUM(price), 2) AS total_item_price,
    ROUND(SUM(freight_value), 2) AS total_freight_value,
    ROUND(SUM(price + freight_value), 2) AS total_order_item_value
FROM order_items
GROUP BY order_id;


-- ============================================================
-- 4. Payments Summary View
-- Purpose: Create one row per order from payment records
-- ============================================================

CREATE OR REPLACE VIEW vw_payments_summary AS
SELECT
    order_id,
    COUNT(*) AS total_payment_records,
    STRING_AGG(DISTINCT payment_type, ', ') AS payment_types,
    MAX(payment_installments) AS max_installments,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM order_payments
GROUP BY order_id;


-- ============================================================
-- 5. Reviews Summary View
-- Purpose: Create one row per order from reviews
-- Some orders may have more than one review record.
-- ============================================================

CREATE OR REPLACE VIEW vw_reviews_summary AS
SELECT
    order_id,
    COUNT(*) AS total_review_records,
    ROUND(AVG(review_score), 2) AS average_review_score,
    MIN(review_score) AS lowest_review_score,
    MAX(review_score) AS highest_review_score,
    MIN(review_creation_date) AS first_review_creation_date,
    MAX(review_answer_timestamp) AS latest_review_answer_timestamp
FROM order_reviews
GROUP BY order_id;


-- ============================================================
-- 6. Orders Cleaned View
-- Purpose: Add customer information and useful date-based fields
-- ============================================================

CREATE OR REPLACE VIEW vw_orders_cleaned AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS order_month,
    DATE_TRUNC('year', o.order_purchase_timestamp)::DATE AS order_year,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    CASE
        WHEN o.order_approved_at IS NOT NULL
        THEN ROUND(EXTRACT(EPOCH FROM (o.order_approved_at - o.order_purchase_timestamp)) / 86400, 2)
        ELSE NULL
    END AS approval_days,

    CASE
        WHEN o.order_delivered_carrier_date IS NOT NULL
        THEN ROUND(EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_purchase_timestamp)) / 86400, 2)
        ELSE NULL
    END AS days_to_carrier,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400, 2)
        ELSE NULL
    END AS delivery_days,

    CASE
        WHEN o.order_estimated_delivery_date IS NOT NULL
        THEN ROUND(EXTRACT(EPOCH FROM (o.order_estimated_delivery_date - o.order_purchase_timestamp)) / 86400, 2)
        ELSE NULL
    END AS estimated_delivery_days,

    CASE
        WHEN o.order_delivered_customer_date IS NULL
          OR o.order_estimated_delivery_date IS NULL
        THEN NULL
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN 1
        ELSE 0
    END AS is_late,

    CASE
        WHEN o.order_status = 'delivered'
          AND o.order_delivered_customer_date IS NOT NULL
        THEN 'completed_delivered'
        WHEN o.order_status = 'canceled'
        THEN 'canceled'
        WHEN o.order_status = 'unavailable'
        THEN 'unavailable'
        ELSE 'incomplete_or_other'
    END AS order_status_group

FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id;


-- ============================================================
-- 7. Main Order Analysis View
-- Purpose: One row per order with customer, payment, review, item, and delivery metrics
-- This will be useful for dashboards and high-level business analysis.
-- ============================================================

CREATE OR REPLACE VIEW vw_order_analysis AS
SELECT
    oc.order_id,
    oc.customer_id,
    oc.customer_unique_id,
    oc.customer_city,
    oc.customer_state,
    oc.order_status,
    oc.order_status_group,
    oc.order_purchase_timestamp,
    oc.order_month,
    oc.order_year,
    oc.order_approved_at,
    oc.order_delivered_carrier_date,
    oc.order_delivered_customer_date,
    oc.order_estimated_delivery_date,
    oc.approval_days,
    oc.days_to_carrier,
    oc.delivery_days,
    oc.estimated_delivery_days,
    oc.is_late,

    COALESCE(ois.total_items, 0) AS total_items,
    COALESCE(ois.unique_products, 0) AS unique_products,
    COALESCE(ois.unique_sellers, 0) AS unique_sellers,
    COALESCE(ois.total_item_price, 0) AS total_item_price,
    COALESCE(ois.total_freight_value, 0) AS total_freight_value,
    COALESCE(ois.total_order_item_value, 0) AS total_order_item_value,

    ps.total_payment_records,
    ps.payment_types,
    ps.max_installments,
    ps.total_payment_value,

    rs.total_review_records,
    rs.average_review_score,
    rs.lowest_review_score,
    rs.highest_review_score

FROM vw_orders_cleaned oc
LEFT JOIN vw_order_items_summary ois
    ON oc.order_id = ois.order_id
LEFT JOIN vw_payments_summary ps
    ON oc.order_id = ps.order_id
LEFT JOIN vw_reviews_summary rs
    ON oc.order_id = rs.order_id;


-- ============================================================
-- 8. Category Analysis View
-- Purpose: Category-level item, seller, revenue, and review analysis
-- ============================================================

CREATE OR REPLACE VIEW vw_category_analysis AS
SELECT
    oie.product_category_name_english AS category,
    COUNT(DISTINCT oie.order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    COUNT(DISTINCT oie.product_id) AS unique_products,
    COUNT(DISTINCT oie.seller_id) AS unique_sellers,
    ROUND(SUM(oie.price), 2) AS total_product_revenue,
    ROUND(SUM(oie.freight_value), 2) AS total_freight_revenue,
    ROUND(SUM(oie.item_total_value), 2) AS total_revenue,
    ROUND(AVG(oie.price), 2) AS average_item_price,
    ROUND(AVG(rs.average_review_score), 2) AS average_review_score
FROM vw_order_items_enriched oie
LEFT JOIN vw_reviews_summary rs
    ON oie.order_id = rs.order_id
GROUP BY oie.product_category_name_english;


-- ============================================================
-- 9. Seller Analysis View
-- Purpose: Seller-level performance summary
-- ============================================================

CREATE OR REPLACE VIEW vw_seller_analysis AS
SELECT
    oie.seller_id,
    oie.seller_city,
    oie.seller_state,
    COUNT(DISTINCT oie.order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    COUNT(DISTINCT oie.product_id) AS unique_products_sold,
    ROUND(SUM(oie.price), 2) AS total_product_revenue,
    ROUND(SUM(oie.freight_value), 2) AS total_freight_value,
    ROUND(SUM(oie.item_total_value), 2) AS total_revenue,
    ROUND(AVG(rs.average_review_score), 2) AS average_review_score
FROM vw_order_items_enriched oie
LEFT JOIN vw_reviews_summary rs
    ON oie.order_id = rs.order_id
GROUP BY
    oie.seller_id,
    oie.seller_city,
    oie.seller_state;
