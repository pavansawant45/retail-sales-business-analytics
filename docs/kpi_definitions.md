# KPI Definitions

All KPIs use **valid orders only** (`clean_orders.is_valid_order = 1`) and are attributed to the order's **purchase month**.
Dataset limitations: there is no cost, profit or discount data, so profit and margin are not calculated.

| KPI | Definition | Source | Notes |
|---|---|---|---|
| Revenue | Sum of item `price`, excluding freight | `clean_order_items.price` | Currency to be confirmed from the dataset documentation |
| Freight | Sum of `freight_value` | `clean_order_items.freight_value` | Reported separately from revenue |
| Orders | Count of distinct valid orders | `clean_orders.order_id` | Excludes canceled, unavailable and itemless orders |
| Units Sold | Number of item rows | `clean_order_items` rows | The dataset has no quantity column; each row is treated as one unit |
| Average Order Value (AOV) | Revenue / Orders | derived | Item price only; a mean, so a few high-priced items (max 6,735.00) pull it up |
| Items per Order | Units Sold / Orders | derived | |
| Customers | Distinct `customer_unique_id` on valid orders | `clean_orders` | `customer_id` is created per order and is not used for counting people |
| MoM growth % | (Revenue this month - Revenue previous month) / Revenue previous month | `LAG()` | NULL when there is no previous month or it is 0 |
| YoY growth % | Same calendar months compared across years | `v_monthly_sales` | Jan-Aug 2018 vs Jan-Aug 2017 |

## Analysis window

Trend and growth KPIs use **January 2017 to August 2018**. Reasons: 2016 is sparse (no orders in November, 1 in December), and September and October 2018 contain 16 and 4 orders (incomplete). Orders outside the window are still counted in the all-time totals and reported separately.