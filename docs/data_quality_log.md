# Data Quality Log

Database: `olist_analytics` (raw tables loaded from Olist Brazilian E-Commerce, Kaggle Version 2, downloaded 18 Oct 2026).
Raw tables are never modified. Exclusions are applied in the cleaned layer and counted.

## Findings

| # | Check | Result | Treatment |
|---|---|---|---|
| 1 | Row counts after load | All 9 tables match the source files (difference 0) | None |
| 2 | Duplicate keys | `order_id`, `customer_id`, `product_id`, (`order_id`,`order_item_id`), (`order_id`,`payment_sequential`) are unique | None |
| 3 | Customers | 99,441 `customer_id` but 96,096 `customer_unique_id` | Count customers by `customer_unique_id` |
| 4 | Order status | delivered 96,478 (97.02%), shipped 1,107, canceled 625, unavailable 609, invoiced 314, processing 301, created 5, approved 2 | See valid-order definition |
| 5 | Blank dates by status | Delivered orders: 8 without delivery date, 2 without carrier date, 14 without approval time. 6 canceled orders have a delivery date | Exclude from delivery-time metrics only |
| 6 | Orders without items | 775 (unavailable 603, canceled 164, created 5, invoiced 2, shipped 1) | No revenue; not counted as valid orders |
| 7 | Orphan rows | None (items, products, customers, payments, reviews all resolve) | None |
| 8 | Money fields | All numeric; price 0.85 to 6,735.00; 383 zero-freight items; payments up to 13,664.08 | Keep; zero freight treated as free shipping |
| 9 | Payments join | 2,961 orders have 2+ payment rows; joining payments to items raised the item price total from 13,591,643.70 to 14,209,115.34 (+4.5%) | Revenue from `order_items` only; collapse payments to one row per order before joining |
| 10 | Order without payment | 1 delivered order has no payment row | Stays in revenue |
| 11 | Reviews | 789 `review_id` values reused across different orders; 547 orders have 2-3 reviews; 768 orders have none; scores only 1-5 | One review per order: latest `review_answer_timestamp` |
| 12 | Date ordering | Carrier pickup before purchase: 166; delivered before carrier pickup: 23; approved before purchase: 0; delivered before purchase: 0 | Exclude from carrier-based stage durations only |
| 13 | Monthly volume | 2016 sparse (no November), Sep-Oct 2018 nearly empty (16 and 4 orders) | Analysis window Jan 2017 to Aug 2018 |
| 14 | Categories | 610 products with no category; 2 categories missing from translation (`pc_gamer`, `portateis_cozinha_e_preparadores_de_alimentos`) | Label blanks "Unknown"; add own mapping, documented as ours |
| 15 | Zero payments | 9 (6 voucher, 3 not_defined) | Exclude `not_defined` from payment-mix analysis |
| 16 | High prices | Top item price 6,735.00 | Keep; show median alongside mean |

## Working definitions (to confirm before KPI work)

- **Valid order:** at least one item, and status not `canceled` or `unavailable`. Expected count: 99,441 - 775 - 461 - 6 = 98,199 (to be verified in the cleaned layer).
- **Revenue:** sum of item `price` for valid orders (freight reported separately). Currency to be confirmed from the dataset documentation.
- **Customers:** distinct `customer_unique_id`.

## Limitations

- No cost, profit or discount data exists, so profitability is not analysed.
- Valid-order and review rules are analyst decisions and are documented here.