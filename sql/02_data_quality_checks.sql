-- 02_data_quality_checks.sql
-- Purpose: profile the raw Olist tables for duplicates, blanks, orphans and invalid numbers.
-- Read-only: nothing here modifies the raw tables.
USE olist_analytics;

-- ===== A. Key uniqueness =====
-- A1. Are order_id and customer_id unique in their tables?
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT order_id) AS distinct_orders FROM raw_orders;
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT customer_id) AS distinct_customer_ids,
       COUNT(DISTINCT customer_unique_id) AS distinct_customer_unique_ids FROM raw_customers;
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT product_id) AS distinct_products FROM raw_products;
-- A2. Is each item / payment row unique within its order?
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT order_id, order_item_id) AS distinct_order_items FROM raw_order_items;
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT order_id, payment_sequential) AS distinct_payment_rows FROM raw_order_payments;
-- A3. Reviews: one per order?
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT review_id) AS distinct_review_ids,
       COUNT(DISTINCT order_id) AS distinct_orders_reviewed FROM raw_order_reviews;

-- ===== B. Order status and blank dates =====
-- B1. Orders by status
SELECT order_status, COUNT(*) AS orders,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders
FROM raw_orders GROUP BY order_status ORDER BY orders DESC;
-- B2. Blank date fields by status (blank = empty text, not NULL, because the raw load keeps text)
SELECT order_status, COUNT(*) AS orders,
       SUM(order_purchase_timestamp = '') AS blank_purchase,
       SUM(order_approved_at = '') AS blank_approved,
       SUM(order_delivered_carrier_date = '') AS blank_carrier,
       SUM(order_delivered_customer_date = '') AS blank_delivered,
       SUM(order_estimated_delivery_date = '') AS blank_estimated
FROM raw_orders GROUP BY order_status ORDER BY orders DESC;

-- ===== C. Orphan checks (rows that point to something missing) =====
SELECT COUNT(*) AS items_without_order
FROM raw_order_items i LEFT JOIN raw_orders o ON o.order_id = i.order_id
WHERE o.order_id IS NULL;

SELECT o.order_status, COUNT(*) AS orders_without_items
FROM raw_orders o LEFT JOIN raw_order_items i ON i.order_id = o.order_id
WHERE i.order_id IS NULL GROUP BY o.order_status ORDER BY orders_without_items DESC;

SELECT COUNT(*) AS items_without_product
FROM raw_order_items i LEFT JOIN raw_products p ON p.product_id = i.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS orders_without_customer
FROM raw_orders o LEFT JOIN raw_customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS payments_without_order
FROM raw_order_payments p LEFT JOIN raw_orders o ON o.order_id = p.order_id
WHERE o.order_id IS NULL;

-- ===== D. Money columns: format and range =====
SELECT COUNT(*) AS item_rows,
       SUM(price NOT REGEXP '^[0-9]+([.][0-9]+)?$') AS non_numeric_price,
       SUM(freight_value NOT REGEXP '^[0-9]+([.][0-9]+)?$') AS non_numeric_freight,
       MIN(CAST(price AS DECIMAL(12,2))) AS min_price, MAX(CAST(price AS DECIMAL(12,2))) AS max_price,
       SUM(CAST(price AS DECIMAL(12,2)) = 0) AS zero_price,
       MIN(CAST(freight_value AS DECIMAL(12,2))) AS min_freight,
       MAX(CAST(freight_value AS DECIMAL(12,2))) AS max_freight,
       SUM(CAST(freight_value AS DECIMAL(12,2)) = 0) AS zero_freight
FROM raw_order_items;

SELECT COUNT(*) AS payment_rows,
       SUM(payment_value NOT REGEXP '^[0-9]+([.][0-9]+)?$') AS non_numeric_payment,
       MIN(CAST(payment_value AS DECIMAL(12,2))) AS min_payment,
       MAX(CAST(payment_value AS DECIMAL(12,2))) AS max_payment,
       SUM(CAST(payment_value AS DECIMAL(12,2)) = 0) AS zero_payment
FROM raw_order_payments;

-- ===== E. Reviews =====
-- E1. Repeated review_ids: same order twice, or one review_id attached to different orders?
SELECT SUM(orders_per_id = 1) AS dup_ids_same_order, SUM(orders_per_id > 1) AS dup_ids_different_orders
FROM (SELECT review_id, COUNT(DISTINCT order_id) AS orders_per_id
      FROM raw_order_reviews GROUP BY review_id HAVING COUNT(*) > 1) d;
-- E2. Reviews per order
SELECT reviews_per_order, COUNT(*) AS orders
FROM (SELECT order_id, COUNT(*) AS reviews_per_order FROM raw_order_reviews GROUP BY order_id) t
GROUP BY reviews_per_order ORDER BY reviews_per_order;
-- E3. Review score values
SELECT review_score, COUNT(*) AS reviews FROM raw_order_reviews GROUP BY review_score ORDER BY review_score;
-- E4. Reviews pointing to a missing order
SELECT COUNT(*) AS reviews_without_order
FROM raw_order_reviews r LEFT JOIN raw_orders o ON o.order_id = r.order_id
WHERE o.order_id IS NULL;

-- ===== F. Dates =====
-- F1. Diagnostic: non-blank values vs. values that convert to a date (each pair should match)
-- Note: CAST(NULLIF(col, '') AS DATETIME) returned NULL for every row here, so CASE is used instead.
SELECT COUNT(*) AS total_orders,
       SUM(order_approved_at <> '') AS approved_nonblank,
       COUNT(CASE WHEN order_approved_at <> '' THEN CAST(order_approved_at AS DATETIME) END) AS approved_ok,
       SUM(order_delivered_carrier_date <> '') AS carrier_nonblank,
       COUNT(CASE WHEN order_delivered_carrier_date <> '' THEN CAST(order_delivered_carrier_date AS DATETIME) END) AS carrier_ok,
       SUM(order_delivered_customer_date <> '') AS delivered_nonblank,
       COUNT(CASE WHEN order_delivered_customer_date <> '' THEN CAST(order_delivered_customer_date AS DATETIME) END) AS delivered_ok
FROM raw_orders;
-- F2. Impossible date orderings
SELECT SUM(approved_ts < purchase_ts)  AS approved_before_purchase,
       SUM(carrier_ts < purchase_ts)   AS carrier_before_purchase,
       SUM(delivered_ts < carrier_ts)  AS delivered_before_carrier,
       SUM(delivered_ts < purchase_ts) AS delivered_before_purchase
FROM (SELECT CAST(order_purchase_timestamp AS DATETIME) AS purchase_ts,
             CASE WHEN order_approved_at <> '' THEN CAST(order_approved_at AS DATETIME) END AS approved_ts,
             CASE WHEN order_delivered_carrier_date <> '' THEN CAST(order_delivered_carrier_date AS DATETIME) END AS carrier_ts,
             CASE WHEN order_delivered_customer_date <> '' THEN CAST(order_delivered_customer_date AS DATETIME) END AS delivered_ts
      FROM raw_orders) t;
-- F3. Orders per month (to spot partial or sparse months)
SELECT DATE_FORMAT(CAST(order_purchase_timestamp AS DATETIME), '%Y-%m') AS order_month, COUNT(*) AS orders
FROM raw_orders GROUP BY order_month ORDER BY order_month;

-- ===== G. Categories =====
-- G1. Products with no category
SELECT COUNT(*) AS products_without_category FROM raw_products WHERE product_category_name = '';
-- G2. Categories missing from the translation table
SELECT p.product_category_name, COUNT(*) AS products
FROM raw_products p LEFT JOIN raw_category_translation t ON t.product_category_name = p.product_category_name
WHERE p.product_category_name <> '' AND t.product_category_name IS NULL
GROUP BY p.product_category_name;

-- ===== H. Outliers and payments =====
-- H1. Ten highest-priced items
SELECT order_id, product_id, price, freight_value FROM raw_order_items
ORDER BY CAST(price AS DECIMAL(12,2)) DESC LIMIT 10;
-- H2. Payment types and zero-value payments
SELECT payment_type, COUNT(*) AS payments, SUM(CAST(payment_value AS DECIMAL(12,2)) = 0) AS zero_value
FROM raw_order_payments GROUP BY payment_type ORDER BY payments DESC;
-- H3. Payment rows per order
SELECT payments_per_order, COUNT(*) AS orders
FROM (SELECT order_id, COUNT(*) AS payments_per_order FROM raw_order_payments GROUP BY order_id) t
GROUP BY payments_per_order ORDER BY payments_per_order;
-- H4. Orders with no payment row
SELECT o.order_id, o.order_status
FROM raw_orders o LEFT JOIN raw_order_payments p ON p.order_id = o.order_id
WHERE p.order_id IS NULL;
-- H5. Join fan-out: item price total with and without joining payments
SELECT
  (SELECT SUM(CAST(price AS DECIMAL(14,2))) FROM raw_order_items) AS items_price_total,
  (SELECT SUM(CAST(i.price AS DECIMAL(14,2)))
   FROM raw_order_items i JOIN raw_order_payments p ON p.order_id = i.order_id) AS price_total_after_joining_payments;