-- 01_schema_and_setup.sql
-- Purpose: create the database and raw staging tables, load the Olist CSVs, and reconcile row counts.
-- Staging tables store everything as text; typing and cleaning happen in later scripts.
-- NOTE: LOAD DATA paths must be literal. If your project lives elsewhere, edit the paths below.

CREATE DATABASE IF NOT EXISTS olist_analytics
  DEFAULT CHARACTER SET utf8mb4;
USE olist_analytics;

DROP TABLE IF EXISTS raw_customers, raw_geolocation, raw_orders, raw_order_items,
  raw_order_payments, raw_order_reviews, raw_products, raw_sellers, raw_category_translation;

CREATE TABLE raw_customers (
  customer_id VARCHAR(50), customer_unique_id VARCHAR(50),
  customer_zip_code_prefix VARCHAR(10), customer_city VARCHAR(100), customer_state VARCHAR(10)
);

CREATE TABLE raw_geolocation (
  geolocation_zip_code_prefix VARCHAR(10), geolocation_lat VARCHAR(30), geolocation_lng VARCHAR(30),
  geolocation_city VARCHAR(100), geolocation_state VARCHAR(10)
);

CREATE TABLE raw_orders (
  order_id VARCHAR(50), customer_id VARCHAR(50), order_status VARCHAR(30),
  order_purchase_timestamp VARCHAR(30), order_approved_at VARCHAR(30),
  order_delivered_carrier_date VARCHAR(30), order_delivered_customer_date VARCHAR(30),
  order_estimated_delivery_date VARCHAR(30)
);

CREATE TABLE raw_order_items (
  order_id VARCHAR(50), order_item_id VARCHAR(10), product_id VARCHAR(50), seller_id VARCHAR(50),
  shipping_limit_date VARCHAR(30), price VARCHAR(30), freight_value VARCHAR(30)
);

CREATE TABLE raw_order_payments (
  order_id VARCHAR(50), payment_sequential VARCHAR(10), payment_type VARCHAR(30),
  payment_installments VARCHAR(10), payment_value VARCHAR(30)
);

CREATE TABLE raw_order_reviews (
  review_id VARCHAR(50), order_id VARCHAR(50), review_score VARCHAR(10),
  review_comment_title TEXT, review_comment_message TEXT,
  review_creation_date VARCHAR(30), review_answer_timestamp VARCHAR(30)
);

-- Column names product_name_lenght / product_description_lenght keep the source's spelling.
CREATE TABLE raw_products (
  product_id VARCHAR(50), product_category_name VARCHAR(100),
  product_name_lenght VARCHAR(10), product_description_lenght VARCHAR(10),
  product_photos_qty VARCHAR(10), product_weight_g VARCHAR(20), product_length_cm VARCHAR(20),
  product_height_cm VARCHAR(20), product_width_cm VARCHAR(20)
);

CREATE TABLE raw_sellers (
  seller_id VARCHAR(50), seller_zip_code_prefix VARCHAR(10),
  seller_city VARCHAR(100), seller_state VARCHAR(10)
);

CREATE TABLE raw_category_translation (
  product_category_name VARCHAR(100), product_category_name_english VARCHAR(100)
);

-- ---------- Load ----------
LOAD DATA LOCAL INFILE 'C:/Users/DELL/Pavan_Projects/retail-sales-business-analytics/data/raw/olist_customers_dataset.csv'
INTO TABLE raw_customers CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/DELL/Pavan_Projects/retail-sales-business-analytics/data/raw/olist_geolocation_dataset.csv'
INTO TABLE raw_geolocation CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/DELL/Pavan_Projects/retail-sales-business-analytics/data/raw/olist_orders_dataset.csv'
INTO TABLE raw_orders CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/DELL/Pavan_Projects/retail-sales-business-analytics/data/raw/olist_order_items_dataset.csv'
INTO TABLE raw_order_items CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/DELL/Pavan_Projects/retail-sales-business-analytics/data/raw/olist_order_payments_dataset.csv'
INTO TABLE raw_order_payments CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/DELL/Pavan_Projects/retail-sales-business-analytics/data/raw/olist_order_reviews_dataset.csv'
INTO TABLE raw_order_reviews CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/DELL/Pavan_Projects/retail-sales-business-analytics/data/raw/olist_products_dataset.csv'
INTO TABLE raw_products CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/DELL/Pavan_Projects/retail-sales-business-analytics/data/raw/olist_sellers_dataset.csv'
INTO TABLE raw_sellers CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/DELL/Pavan_Projects/retail-sales-business-analytics/data/raw/product_category_name_translation.csv'
INTO TABLE raw_category_translation CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n' IGNORE 1 LINES;



-- ---------- Reconciliation ----------
-- Compare rows actually in each table with the row counts verified from the raw CSV files
-- (counted with PowerShell Import-Csv). Every difference should be 0.
SELECT 'raw_customers' AS table_name, COUNT(*) AS loaded_rows, 99441 AS expected_rows, COUNT(*) - 99441 AS difference FROM raw_customers
UNION ALL SELECT 'raw_geolocation', COUNT(*), 1000163, COUNT(*) - 1000163 FROM raw_geolocation
UNION ALL SELECT 'raw_orders', COUNT(*), 99441, COUNT(*) - 99441 FROM raw_orders
UNION ALL SELECT 'raw_order_items', COUNT(*), 112650, COUNT(*) - 112650 FROM raw_order_items
UNION ALL SELECT 'raw_order_payments', COUNT(*), 103886, COUNT(*) - 103886 FROM raw_order_payments
UNION ALL SELECT 'raw_order_reviews', COUNT(*), 99224, COUNT(*) - 99224 FROM raw_order_reviews
UNION ALL SELECT 'raw_products', COUNT(*), 32951, COUNT(*) - 32951 FROM raw_products
UNION ALL SELECT 'raw_sellers', COUNT(*), 3095, COUNT(*) - 3095 FROM raw_sellers
UNION ALL SELECT 'raw_category_translation', COUNT(*), 71, COUNT(*) - 71 FROM raw_category_translation;

-- Stray carriage-return checks: should both return 0 (files use \n line endings).
SELECT COUNT(*) AS customers_rows_with_cr FROM raw_customers WHERE RIGHT(customer_state, 1) = CHAR(13);
SELECT COUNT(*) AS orders_rows_with_cr FROM raw_orders WHERE RIGHT(order_estimated_delivery_date, 1) = CHAR(13);

-- Visual spot checks
SELECT * FROM raw_orders LIMIT 5;
SELECT * FROM raw_products LIMIT 5;




