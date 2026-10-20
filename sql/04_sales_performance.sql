-- 04_sales_performance.sql
-- Purpose: overall performance KPIs, monthly trend, MoM and YoY comparisons.
-- Definitions: docs/kpi_definitions.md. Window for trends: 2017-01 to 2018-08.
USE olist_analytics;

-- Monthly summary of valid orders (reused by later queries)
CREATE OR REPLACE VIEW v_monthly_sales AS
SELECT o.order_month,
       COUNT(DISTINCT o.order_id) AS orders,
       COUNT(*)                   AS units,
       SUM(i.price)               AS revenue,
       SUM(i.freight_value)       AS freight
FROM clean_orders o
JOIN clean_order_items i ON i.order_id = o.order_id
WHERE o.is_valid_order = 1
GROUP BY o.order_month;

-- ===== A. Headline KPIs =====
-- A1. All valid orders vs. the analysis window
SELECT 'all_valid_orders' AS scope,
       COUNT(DISTINCT o.order_id) AS orders, COUNT(*) AS units,
       SUM(i.price) AS revenue, SUM(i.freight_value) AS freight,
       ROUND(SUM(i.price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
       COUNT(DISTINCT o.customer_unique_id) AS customers
FROM clean_orders o JOIN clean_order_items i ON i.order_id = o.order_id
WHERE o.is_valid_order = 1
UNION ALL
SELECT 'window_2017-01_to_2018-08',
       COUNT(DISTINCT o.order_id), COUNT(*), SUM(i.price), SUM(i.freight_value),
       ROUND(SUM(i.price) / COUNT(DISTINCT o.order_id), 2),
       COUNT(DISTINCT o.customer_unique_id)
FROM clean_orders o JOIN clean_order_items i ON i.order_id = o.order_id
WHERE o.is_valid_order = 1 AND o.order_month BETWEEN '2017-01-01' AND '2018-08-01';

-- A2. Basket size: how many items do valid orders contain?
SELECT item_count AS items_in_order, COUNT(*) AS orders
FROM clean_orders WHERE is_valid_order = 1
GROUP BY item_count ORDER BY item_count;

-- ===== B. Monthly trend and month-over-month growth =====
-- LAG looks at the previous row after the WHERE filter, so January 2017 has no previous month (NULL).
SELECT order_month, orders, units, revenue,
       ROUND(revenue / orders, 2) AS avg_order_value,
       LAG(revenue) OVER (ORDER BY order_month) AS prev_month_revenue,
       ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY order_month))
             / NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0), 1) AS mom_growth_pct
FROM v_monthly_sales
WHERE order_month BETWEEN '2017-01-01' AND '2018-08-01'
ORDER BY order_month;

-- B2. Months outside the window (partial or sparse), reported separately
SELECT order_month, orders, units, revenue
FROM v_monthly_sales
WHERE order_month < '2017-01-01' OR order_month > '2018-08-01'
ORDER BY order_month;

-- ===== C. Year-over-year (same months) =====
-- C1. Jan-Aug 2018 vs Jan-Aug 2017, month by month
SELECT DATE_FORMAT(cur.order_month, '%M') AS month_name,
       prev.revenue AS revenue_2017, cur.revenue AS revenue_2018,
       ROUND(100 * (cur.revenue - prev.revenue) / NULLIF(prev.revenue, 0), 1) AS yoy_growth_pct
FROM v_monthly_sales cur
JOIN v_monthly_sales prev ON prev.order_month = DATE_SUB(cur.order_month, INTERVAL 1 YEAR)
WHERE cur.order_month BETWEEN '2018-01-01' AND '2018-08-01'
ORDER BY cur.order_month;

-- C2. Jan-Aug totals
SELECT SUM(CASE WHEN YEAR(order_month) = 2017 THEN revenue END) AS revenue_jan_aug_2017,
       SUM(CASE WHEN YEAR(order_month) = 2018 THEN revenue END) AS revenue_jan_aug_2018,
       ROUND(100 * (SUM(CASE WHEN YEAR(order_month) = 2018 THEN revenue END)
                  - SUM(CASE WHEN YEAR(order_month) = 2017 THEN revenue END))
             / SUM(CASE WHEN YEAR(order_month) = 2017 THEN revenue END), 1) AS yoy_growth_pct
FROM v_monthly_sales
WHERE order_month BETWEEN '2017-01-01' AND '2018-08-01' AND MONTH(order_month) <= 8;

-- ===== D. Validation =====
-- D1. Monthly view totals must equal the cleaned-layer totals
SELECT SUM(orders) AS orders, SUM(units) AS units, SUM(revenue) AS revenue FROM v_monthly_sales;