-- ============================================================
-- Project: Olist E-Commerce Business Performance Analysis
-- File: 03_create_indexes.sql
-- Purpose: Improve join and filtering performance
-- ============================================================

CREATE INDEX idx_orders_customer_id
ON orders(customer_id);

CREATE INDEX idx_orders_purchase_timestamp
ON orders(order_purchase_timestamp);

CREATE INDEX idx_order_items_order_id
ON order_items(order_id);

CREATE INDEX idx_order_items_product_id
ON order_items(product_id);

CREATE INDEX idx_order_items_seller_id
ON order_items(seller_id);

CREATE INDEX idx_order_payments_order_id
ON order_payments(order_id);

CREATE INDEX idx_order_reviews_order_id
ON order_reviews(order_id);

CREATE INDEX idx_products_category_name
ON products(product_category_name);

CREATE INDEX idx_customers_state
ON customers(customer_state);

CREATE INDEX idx_sellers_state
ON sellers(seller_state);