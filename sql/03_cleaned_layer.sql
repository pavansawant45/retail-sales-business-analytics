-- 03_cleaned_layer.sql
-- Purpose: build typed clean_* tables from raw_* tables. Raw tables are never modified.
-- Rules are documented in docs/data_quality_log.md.
USE olist_analytics;

DROP TABLE IF EXISTS clean_order_payments, clean_order_reviews, clean_order_items,
  clean_orders, clean_products, clean_category_map;

-- ---------- Category mapping ----------
-- Source translations plus two manual rows for categories missing from the source file.
CREATE TABLE clean_category_map (
  product_category_name VARCHAR(100) NOT NULL PRIMARY KEY,
  category_english VARCHAR(100) NOT NULL,
  mapping_source VARCHAR(20) NOT NULL
);
INSERT INTO clean_category_map
SELECT product_category_name, product_category_name_english, 'olist_translation'
FROM raw_category_translation;
INSERT INTO clean_category_map VALUES
  ('pc_gamer', 'pc_gamer', 'manual'),
  ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_preparers', 'manual');

-- ---------- Products ----------
CREATE TABLE clean_products (
  product_id VARCHAR(50) NOT NULL PRIMARY KEY,
  category_pt VARCHAR(100) NULL,
  category_english VARCHAR(100) NOT NULL
);
INSERT INTO clean_products
SELECT p.product_id, NULLIF(p.product_category_name, ''), COALESCE(m.category_english, 'Unknown')
FROM raw_products p
LEFT JOIN clean_category_map m ON m.product_category_name = p.product_category_name;

-- ---------- Orders (all orders kept; exclusions are flagged) ----------
CREATE TABLE clean_orders (
  order_id VARCHAR(50) NOT NULL PRIMARY KEY,
  customer_id VARCHAR(50) NOT NULL,
  customer_unique_id VARCHAR(50) NOT NULL,
  customer_city VARCHAR(100) NULL,
  customer_state VARCHAR(10) NULL,
  order_status VARCHAR(30) NOT NULL,
  purchase_ts DATETIME NOT NULL,
  approved_ts DATETIME NULL,
  carrier_ts DATETIME NULL,
  delivered_ts DATETIME NULL,
  estimated_delivery_ts DATETIME NULL,
  order_month DATE NOT NULL,
  item_count INT NOT NULL,
  exclusion_reason VARCHAR(20) NULL,
  is_valid_order TINYINT GENERATED ALWAYS AS (IF(exclusion_reason IS NULL, 1, 0)) STORED,
  carrier_date_anomaly TINYINT GENERATED ALWAYS AS
    (IF(carrier_ts < purchase_ts OR delivered_ts < carrier_ts, 1, 0)) STORED
);
INSERT INTO clean_orders
  (order_id, customer_id, customer_unique_id, customer_city, customer_state, order_status,
   purchase_ts, approved_ts, carrier_ts, delivered_ts, estimated_delivery_ts,
   order_month, item_count, exclusion_reason)
SELECT o.order_id, o.customer_id, c.customer_unique_id, c.customer_city, c.customer_state, o.order_status,
  CAST(o.order_purchase_timestamp AS DATETIME),
  CASE WHEN o.order_approved_at <> '' THEN CAST(o.order_approved_at AS DATETIME) END,
  CASE WHEN o.order_delivered_carrier_date <> '' THEN CAST(o.order_delivered_carrier_date AS DATETIME) END,
  CASE WHEN o.order_delivered_customer_date <> '' THEN CAST(o.order_delivered_customer_date AS DATETIME) END,
  CASE WHEN o.order_estimated_delivery_date <> '' THEN CAST(o.order_estimated_delivery_date AS DATETIME) END,
  DATE_FORMAT(CAST(o.order_purchase_timestamp AS DATETIME), '%Y-%m-01'),
  COALESCE(i.item_count, 0),
  -- Valid-order rule lives here: first matching reason wins.
  CASE WHEN COALESCE(i.item_count, 0) = 0 THEN 'no_items'
       WHEN o.order_status = 'canceled'    THEN 'canceled'
       WHEN o.order_status = 'unavailable' THEN 'unavailable'
  END
FROM raw_orders o
JOIN raw_customers c ON c.customer_id = o.customer_id
LEFT JOIN (SELECT order_id, COUNT(*) AS item_count FROM raw_order_items GROUP BY order_id) i
  ON i.order_id = o.order_id;

-- ---------- Order items ----------
CREATE TABLE clean_order_items (
  order_id VARCHAR(50) NOT NULL,
  order_item_id INT NOT NULL,
  product_id VARCHAR(50) NOT NULL,
  seller_id VARCHAR(50) NOT NULL,
  shipping_limit_ts DATETIME NULL,
  price DECIMAL(10,2) NOT NULL,
  freight_value DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (order_id, order_item_id)
);
INSERT INTO clean_order_items
SELECT order_id, CAST(order_item_id AS UNSIGNED), product_id, seller_id,
       CASE WHEN shipping_limit_date <> '' THEN CAST(shipping_limit_date AS DATETIME) END,
       CAST(price AS DECIMAL(10,2)), CAST(freight_value AS DECIMAL(10,2))
FROM raw_order_items;

-- ---------- Reviews: one per order (latest answer timestamp) ----------
CREATE TABLE clean_order_reviews (
  order_id VARCHAR(50) NOT NULL PRIMARY KEY,
  review_id VARCHAR(50) NOT NULL,
  review_score TINYINT NOT NULL,
  review_creation_ts DATETIME NULL,
  review_answer_ts DATETIME NULL,
  reviews_on_order INT NOT NULL
);
INSERT INTO clean_order_reviews
SELECT order_id, review_id, CAST(review_score AS UNSIGNED),
       CASE WHEN review_creation_date <> '' THEN CAST(review_creation_date AS DATETIME) END,
       CASE WHEN review_answer_timestamp <> '' THEN CAST(review_answer_timestamp AS DATETIME) END,
       reviews_on_order
FROM (
  SELECT r.*,
         COUNT(*) OVER (PARTITION BY order_id) AS reviews_on_order,
         ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC, review_id) AS rn
  FROM raw_order_reviews r
) ranked
WHERE rn = 1;

-- ---------- Payments: one row per order ----------
CREATE TABLE clean_order_payments (
  order_id VARCHAR(50) NOT NULL PRIMARY KEY,
  payment_rows INT NOT NULL,
  payment_total DECIMAL(12,2) NOT NULL,
  max_installments INT NOT NULL,
  main_payment_type VARCHAR(30) NOT NULL
);
INSERT INTO clean_order_payments
SELECT order_id, payment_rows, payment_total, max_installments, payment_type
FROM (
  SELECT order_id, payment_type,
         COUNT(*) OVER (PARTITION BY order_id) AS payment_rows,
         SUM(CAST(payment_value AS DECIMAL(12,2))) OVER (PARTITION BY order_id) AS payment_total,
         MAX(CAST(payment_installments AS UNSIGNED)) OVER (PARTITION BY order_id) AS max_installments,
         ROW_NUMBER() OVER (PARTITION BY order_id
                            ORDER BY CAST(payment_value AS DECIMAL(12,2)) DESC,
                                     CAST(payment_sequential AS UNSIGNED)) AS rn
  FROM raw_order_payments
) ranked
WHERE rn = 1;

---------- Validation ----------

-- V1. Row counts
SELECT 'clean_category_map' AS table_name, COUNT(*) AS rows_loaded, 73 AS expected FROM clean_category_map
UNION ALL SELECT 'clean_products', COUNT(*), 32951 FROM clean_products
UNION ALL SELECT 'clean_orders', COUNT(*), 99441 FROM clean_orders
UNION ALL SELECT 'clean_order_items', COUNT(*), 112650 FROM clean_order_items
UNION ALL SELECT 'clean_order_reviews', COUNT(*), 98673 FROM clean_order_reviews
UNION ALL SELECT 'clean_order_payments', COUNT(*), 99440 FROM clean_order_payments;

-- V2. Orders by exclusion bucket
SELECT COALESCE(exclusion_reason, 'valid') AS bucket, COUNT(*) AS orders
FROM clean_orders GROUP BY bucket ORDER BY orders DESC;

-- V3. Money reconciliation against raw
SELECT (SELECT SUM(price) FROM clean_order_items) AS clean_price_total,
       13591643.70 AS control_total,
       (SELECT SUM(CAST(freight_value AS DECIMAL(14,2))) FROM raw_order_items) AS raw_freight_total,
       (SELECT SUM(freight_value) FROM clean_order_items) AS clean_freight_total,
       (SELECT SUM(CAST(payment_value AS DECIMAL(14,2))) FROM raw_order_payments) AS raw_payment_total,
       (SELECT SUM(payment_total) FROM clean_order_payments) AS clean_payment_total;

-- V4. Item rows and price by bucket (first look at valid vs. excluded value)
SELECT COALESCE(o.exclusion_reason, 'valid') AS bucket, COUNT(DISTINCT o.order_id) AS orders,
       COUNT(*) AS item_rows, SUM(i.price) AS price_total
FROM clean_order_items i JOIN clean_orders o ON o.order_id = i.order_id
GROUP BY bucket;

-- V5. Products labelled Unknown
SELECT COUNT(*) AS unknown_category_products FROM clean_products WHERE category_english = 'Unknown';

-- V6. Date anomaly flags
SELECT SUM(carrier_ts < purchase_ts) AS carrier_before_purchase,
       SUM(delivered_ts < carrier_ts) AS delivered_before_carrier,
       SUM(carrier_date_anomaly) AS flagged_orders
FROM clean_orders;

-- V7. Reviews where one was kept out of several
SELECT COUNT(*) AS orders_with_multiple_reviews FROM clean_order_reviews WHERE reviews_on_order > 1;