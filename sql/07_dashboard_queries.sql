-- 07_dashboard_queries.sql
-- Purpose: dimension table, export views for Power BI, and validation. Run after scripts 03, 05 and 06
-- (this file uses v_sales_items from 05 and v_delivered_orders from 06).
USE olist_analytics;

-- State-to-region mapping. This is our own mapping of the five official Brazilian macro-regions;
-- it is NOT part of the Olist data.
DROP TABLE IF EXISTS clean_state_region;
CREATE TABLE clean_state_region (
  customer_state VARCHAR(10) NOT NULL PRIMARY KEY,
  customer_region VARCHAR(20) NOT NULL
);
INSERT INTO clean_state_region VALUES
  ('AC','North'),('AP','North'),('AM','North'),('PA','North'),('RO','North'),('RR','North'),('TO','North'),
  ('AL','Northeast'),('BA','Northeast'),('CE','Northeast'),('MA','Northeast'),('PB','Northeast'),
  ('PE','Northeast'),('PI','Northeast'),('RN','Northeast'),('SE','Northeast'),
  ('DF','Central-West'),('GO','Central-West'),('MT','Central-West'),('MS','Central-West'),
  ('ES','Southeast'),('MG','Southeast'),('RJ','Southeast'),('SP','Southeast'),
  ('PR','South'),('RS','South'),('SC','South');

-- ---------- Export views ----------
CREATE OR REPLACE VIEW v_export_fact_items AS
SELECT order_id, order_item_id, product_id, DATE(purchase_ts) AS order_date,
       customer_unique_id, customer_state, category_english, price, freight_value
FROM v_sales_items;

CREATE OR REPLACE VIEW v_export_fact_orders AS
SELECT o.order_id, DATE(o.purchase_ts) AS order_date, o.customer_unique_id, o.customer_state,
       o.item_count AS items, x.price_total AS revenue, x.freight_total AS freight,
       ROUND(d.delivery_days, 2) AS delivery_days, d.is_late, r.review_score,
       p.main_payment_type, p.max_installments
FROM clean_orders o
JOIN (SELECT order_id, SUM(price) AS price_total, SUM(freight_value) AS freight_total
      FROM clean_order_items GROUP BY order_id) x ON x.order_id = o.order_id
LEFT JOIN v_delivered_orders d ON d.order_id = o.order_id
LEFT JOIN clean_order_reviews r ON r.order_id = o.order_id
LEFT JOIN clean_order_payments p ON p.order_id = o.order_id
WHERE o.is_valid_order = 1;

CREATE OR REPLACE VIEW v_export_dim_state AS
SELECT customer_state, customer_region FROM clean_state_region;

CREATE OR REPLACE VIEW v_export_dim_category AS
SELECT DISTINCT category_english FROM v_sales_items;

-- ---------- Additional analysis for the findings ----------
-- Region summary (window). Southeast should equal SP + RJ + MG + ES = 8,794,685.26.
SELECT r.customer_region, COUNT(DISTINCT s.order_id) AS orders, SUM(s.price) AS revenue,
       ROUND(100 * SUM(s.price) / SUM(SUM(s.price)) OVER (), 1) AS pct_of_revenue
FROM v_sales_items s JOIN clean_state_region r ON r.customer_state = s.customer_state
WHERE s.order_month BETWEEN '2017-01-01' AND '2018-08-01'
GROUP BY r.customer_region ORDER BY revenue DESC;

-- Product concentration (window): share of revenue from the top 10 / 100 / 1,000 products
SELECT COUNT(*) AS products_sold,
       ROUND(100 * SUM(CASE WHEN rnk <= 10   THEN revenue END) / SUM(revenue), 1) AS top10_pct,
       ROUND(100 * SUM(CASE WHEN rnk <= 100  THEN revenue END) / SUM(revenue), 1) AS top100_pct,
       ROUND(100 * SUM(CASE WHEN rnk <= 1000 THEN revenue END) / SUM(revenue), 1) AS top1000_pct
FROM (SELECT product_id, SUM(price) AS revenue, RANK() OVER (ORDER BY SUM(price) DESC) AS rnk
      FROM v_sales_items
      WHERE order_month BETWEEN '2017-01-01' AND '2018-08-01'
      GROUP BY product_id) t;

-- ---------- Validation ----------
-- Every state in the data must have a region (expect 0)
SELECT COUNT(*) AS states_without_region
FROM (SELECT DISTINCT customer_state FROM clean_orders) s
LEFT JOIN clean_state_region r ON r.customer_state = s.customer_state
WHERE r.customer_state IS NULL;

-- Export view sizes and totals
SELECT (SELECT COUNT(*) FROM v_export_fact_items)  AS fact_items_rows,
       (SELECT SUM(price) FROM v_export_fact_items) AS items_revenue,
       (SELECT COUNT(*) FROM v_export_fact_orders) AS fact_orders_rows,
       (SELECT SUM(revenue) FROM v_export_fact_orders) AS orders_revenue,
       (SELECT COUNT(delivery_days) FROM v_export_fact_orders) AS orders_with_delivery,
       (SELECT COUNT(review_score) FROM v_export_fact_orders) AS orders_with_review,
       (SELECT COUNT(main_payment_type) FROM v_export_fact_orders) AS orders_with_payment,
       (SELECT COUNT(*) FROM v_export_dim_state) AS state_rows,
       (SELECT COUNT(*) FROM v_export_dim_category) AS category_rows;