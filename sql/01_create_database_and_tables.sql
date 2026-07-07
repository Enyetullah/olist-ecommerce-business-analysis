-- ============================================================
-- Project: Olist E-Commerce Business Performance Analysis
-- File: 01_create_database_and_tables.sql
-- Purpose: Create all PostgreSQL tables for the Olist dataset
-- ============================================================

-- Drop tables if they already exist.
-- This allows the script to be re-run safely during development.

DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS geolocation;
DROP TABLE IF EXISTS product_category_translation;


-- ============================================================
-- 1. Customers Table
-- ============================================================

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);


-- ============================================================
-- 2. Sellers Table
-- ============================================================

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);


-- ============================================================
-- 3. Products Table
-- Note: The original dataset uses "lenght" instead of "length".
-- We keep the original spelling so the CSV import works easily.
-- ============================================================

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);


-- ============================================================
-- 4. Product Category Translation Table
-- ============================================================

CREATE TABLE product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);


-- ============================================================
-- 5. Orders Table
-- ============================================================

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);


-- ============================================================
-- 6. Order Items Table
-- One order can have multiple items.
-- The combination of order_id and order_item_id is unique.
-- ============================================================

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10, 2),
    freight_value NUMERIC(10, 2),
    PRIMARY KEY (order_id, order_item_id)
);


-- ============================================================
-- 7. Order Payments Table
-- One order can have multiple payment records.
-- ============================================================

CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value NUMERIC(10, 2),
    PRIMARY KEY (order_id, payment_sequential)
);


-- ============================================================
-- 8. Order Reviews Table
-- Review text columns are TEXT because comments can be long.
-- ============================================================

CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);


-- ============================================================
-- 9. Geolocation Table
-- This table can contain repeated zip code prefixes.
-- Do not use geolocation_zip_code_prefix as a primary key.
-- ============================================================

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat NUMERIC(12, 8),
    geolocation_lng NUMERIC(12, 8),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);