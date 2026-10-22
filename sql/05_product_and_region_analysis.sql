-- 05_product_and_region_analysis.sql
-- Purpose: category and regional performance, concentration, YoY change.
-- Region = customer state (no store data exists). Window: 2017-01 to 2018-08.
USE olist_analytics;

-- One row per item on valid orders, with month, state and category attached
CREATE OR REPLACE VIEW v_sales_items AS
SELECT i.order_id, i.order_item_id, i.product_id, i.seller_id,
       o.order_month, o.purchase_ts, o.customer_unique_id, o.customer_state,
       p.category_english, i.price, i.freight_value
FROM clean_order_items i
JOIN clean_orders o   ON o.order_id = i.order_id
JOIN clean_products p ON p.product_id = i.product_id
WHERE o.is_valid_order = 1;

-- Category and state summaries for the analysis window
CREATE OR REPLACE VIEW v_category_sales AS
SELECT category_english, COUNT(DISTINCT order_id) AS orders, COUNT(*) AS units, SUM(price) AS revenue
FROM v_sales_items
WHERE order_month BETWEEN '2017-01-01' AND '2018-08-01'
GROUP BY category_english;

CREATE OR REPLACE VIEW v_state_sales AS
SELECT customer_state, COUNT(DISTINCT order_id) AS orders, COUNT(*) AS units,
       SUM(price) AS revenue, SUM(freight_value) AS freight
FROM v_sales_items
WHERE order_month BETWEEN '2017-01-01' AND '2018-08-01'
GROUP BY customer_state;

-- ===== A. Categories =====
-- A1. Top 15 categories with share of revenue and cumulative share
SELECT RANK() OVER (ORDER BY revenue DESC) AS revenue_rank, category_english, orders, units, revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (), 1) AS pct_of_revenue,
       ROUND(100 * SUM(revenue) OVER (ORDER BY revenue DESC) / SUM(revenue) OVER (), 1) AS cumulative_pct
FROM v_category_sales
ORDER BY revenue DESC LIMIT 15;

-- A2. How concentrated is revenue?
SELECT COUNT(*) AS categories,
       ROUND(100 * SUM(CASE WHEN rnk <= 5  THEN revenue END) / SUM(revenue), 1) AS top5_pct,
       ROUND(100 * SUM(CASE WHEN rnk <= 10 THEN revenue END) / SUM(revenue), 1) AS top10_pct
FROM (SELECT revenue, RANK() OVER (ORDER BY revenue DESC) AS rnk FROM v_category_sales) r;

-- A3. Ten smallest categories by revenue (niche, not necessarily failing)
SELECT category_english, orders, units, revenue FROM v_category_sales ORDER BY revenue ASC LIMIT 10;

-- A4. Revenue share of products with no category
SELECT ROUND(100 * revenue / (SELECT SUM(revenue) FROM v_category_sales), 2) AS pct_unknown_revenue
FROM v_category_sales WHERE category_english = 'Unknown';

-- A5. Year-over-year (Jan-Aug 2018 vs Jan-Aug 2017) for the ten biggest categories of 2018
SELECT category_english, rev_2017, rev_2018,
       ROUND(100 * (rev_2018 - rev_2017) / NULLIF(rev_2017, 0), 1) AS yoy_growth_pct
FROM (SELECT category_english,
             SUM(CASE WHEN YEAR(order_month) = 2017 THEN price ELSE 0 END) AS rev_2017,
             SUM(CASE WHEN YEAR(order_month) = 2018 THEN price ELSE 0 END) AS rev_2018
      FROM v_sales_items
      WHERE order_month BETWEEN '2017-01-01' AND '2018-08-01' AND MONTH(order_month) <= 8
      GROUP BY category_english) t
ORDER BY rev_2018 DESC LIMIT 10;

-- ===== B. Regions (customer state) =====
-- B1. All states: revenue, share, cumulative share, order value, freight burden
SELECT RANK() OVER (ORDER BY revenue DESC) AS revenue_rank, customer_state, orders, revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (), 1) AS pct_of_revenue,
       ROUND(100 * SUM(revenue) OVER (ORDER BY revenue DESC) / SUM(revenue) OVER (), 1) AS cumulative_pct,
       ROUND(revenue / orders, 2) AS avg_order_value,
       ROUND(100 * freight / revenue, 1) AS freight_pct_of_price
FROM v_state_sales
ORDER BY revenue DESC;

-- B2. Year-over-year for the ten biggest states of 2018
SELECT customer_state, rev_2017, rev_2018,
       ROUND(100 * (rev_2018 - rev_2017) / NULLIF(rev_2017, 0), 1) AS yoy_growth_pct
FROM (SELECT customer_state,
             SUM(CASE WHEN YEAR(order_month) = 2017 THEN price ELSE 0 END) AS rev_2017,
             SUM(CASE WHEN YEAR(order_month) = 2018 THEN price ELSE 0 END) AS rev_2018
      FROM v_sales_items
      WHERE order_month BETWEEN '2017-01-01' AND '2018-08-01' AND MONTH(order_month) <= 8
      GROUP BY customer_state) t
ORDER BY rev_2018 DESC LIMIT 10;

-- ===== C. What happened in November 2017? Busiest days =====
SELECT DATE(purchase_ts) AS order_date, COUNT(*) AS orders
FROM clean_orders
WHERE is_valid_order = 1 AND order_month = '2017-11-01'
GROUP BY DATE(purchase_ts) ORDER BY orders DESC LIMIT 5;

-- ===== D. Validation =====
SELECT COUNT(*) AS item_rows, SUM(price) AS revenue FROM v_sales_items;                  -- 112,101 / 13,494,400.74
SELECT SUM(revenue) AS category_total FROM v_category_sales;                              -- 13,449,529.68
SELECT SUM(revenue) AS state_total, SUM(orders) AS orders FROM v_state_sales;             -- 13,449,529.68 / 97,905