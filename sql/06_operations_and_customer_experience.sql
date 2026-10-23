-- 06_operations_and_customer_experience.sql
-- Purpose: delivery performance, reviews, payment mix, payments vs items reconciliation.
-- Basis: valid orders. Delivery metrics use delivered orders that have a delivery date.
USE olist_analytics;

-- Delivered valid orders. The estimated date is stored at 00:00:00, so lateness compares DATES:
-- an order delivered at 15:00 on the estimated day is on time.
CREATE OR REPLACE VIEW v_delivered_orders AS
SELECT o.order_id, o.order_month, o.customer_state,
       TIMESTAMPDIFF(SECOND, o.purchase_ts, o.delivered_ts) / 86400 AS delivery_days,
       IF(DATE(o.delivered_ts) > DATE(o.estimated_delivery_ts), 1, 0) AS is_late
FROM clean_orders o
WHERE o.is_valid_order = 1 AND o.order_status = 'delivered' AND o.delivered_ts IS NOT NULL;

-- ===== A. Delivery performance =====
-- A1. Overall (expect 96,470 delivered orders with a delivery date)
SELECT COUNT(*) AS delivered_orders, ROUND(AVG(delivery_days), 1) AS avg_days,
       ROUND(100 * AVG(is_late), 1) AS pct_late
FROM v_delivered_orders;

-- A2. Median delivery days
SELECT ROUND(AVG(delivery_days), 1) AS median_days
FROM (SELECT delivery_days, ROW_NUMBER() OVER (ORDER BY delivery_days) AS rn, COUNT(*) OVER () AS cnt
      FROM v_delivered_orders) t
WHERE rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2));

-- A3. By month (window)
SELECT order_month, COUNT(*) AS delivered_orders, ROUND(AVG(delivery_days), 1) AS avg_days,
       ROUND(100 * AVG(is_late), 1) AS pct_late
FROM v_delivered_orders
WHERE order_month BETWEEN '2017-01-01' AND '2018-08-01'
GROUP BY order_month ORDER BY order_month;

-- A4. By state (states with at least 100 delivered orders), slowest first
SELECT customer_state, COUNT(*) AS delivered_orders, ROUND(AVG(delivery_days), 1) AS avg_days,
       ROUND(100 * AVG(is_late), 1) AS pct_late
FROM v_delivered_orders
GROUP BY customer_state HAVING COUNT(*) >= 100
ORDER BY avg_days DESC;

-- ===== B. Reviews =====
-- B1. Score distribution on valid orders
SELECT r.review_score, COUNT(*) AS orders,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM clean_order_reviews r JOIN clean_orders o ON o.order_id = r.order_id
WHERE o.is_valid_order = 1
GROUP BY r.review_score ORDER BY r.review_score;

-- B2. Review coverage: valid orders with no review
SELECT COUNT(*) AS valid_orders_without_review
FROM clean_orders o LEFT JOIN clean_order_reviews r ON r.order_id = o.order_id
WHERE o.is_valid_order = 1 AND r.order_id IS NULL;

-- B3. Average score: late vs. on-time deliveries (association only, not cause)
SELECT d.is_late, COUNT(*) AS orders, ROUND(AVG(r.review_score), 2) AS avg_score
FROM v_delivered_orders d JOIN clean_order_reviews r ON r.order_id = d.order_id
GROUP BY d.is_late;

-- ===== C. Payments =====
-- C1. Main payment type per valid order (type of the largest payment)
SELECT p.main_payment_type, COUNT(*) AS orders,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_orders,
       ROUND(AVG(p.max_installments), 1) AS avg_max_installments
FROM clean_orders o JOIN clean_order_payments p ON p.order_id = o.order_id
WHERE o.is_valid_order = 1
GROUP BY p.main_payment_type ORDER BY orders DESC;

-- C2. Payments vs. item price + freight, by exclusion bucket (one row per order on both sides)
SELECT COALESCE(o.exclusion_reason, 'valid') AS bucket, COUNT(*) AS orders,
       ROUND(SUM(p.payment_total), 2) AS payments,
       ROUND(SUM(COALESCE(x.price_total, 0) + COALESCE(x.freight_total, 0)), 2) AS items_plus_freight
FROM clean_orders o
JOIN clean_order_payments p ON p.order_id = o.order_id
LEFT JOIN (SELECT order_id, SUM(price) AS price_total, SUM(freight_value) AS freight_total
           FROM clean_order_items GROUP BY order_id) x ON x.order_id = o.order_id
GROUP BY bucket;

-- C3. Within valid orders: how many orders match, and how large are the differences?
SELECT SUM(ABS(d) <= 0.01) AS orders_matching, SUM(d > 0.01) AS payment_higher, SUM(d < -0.01) AS payment_lower,
       ROUND(SUM(CASE WHEN d > 0.01 THEN d END), 2) AS total_excess,
       ROUND(SUM(CASE WHEN d < -0.01 THEN d END), 2) AS total_shortfall
FROM (SELECT p.payment_total - (x.price_total + x.freight_total) AS d
      FROM clean_orders o
      JOIN clean_order_payments p ON p.order_id = o.order_id
      JOIN (SELECT order_id, SUM(price) AS price_total, SUM(freight_value) AS freight_total
            FROM clean_order_items GROUP BY order_id) x ON x.order_id = o.order_id
      WHERE o.is_valid_order = 1) t;