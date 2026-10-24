# Power BI model and measures

Source files: CSV exports of the cleaned MySQL tables (data/exports, not committed: dataset license CC BY-NC-SA 4.0).
Report file: powerbi/retail_analytics.pbix.

## Model (star schema)
| Table | Grain | Rows |
|---|---|---|
| fact_items | one row per item on a valid order | 112,101 |
| fact_orders | one row per valid order (delivery, review, payment) | 98,199 |
| dim_state | state with its macro-region (own mapping, not in the dataset) | 27 |
| dim_category | product category | 74 |
| dim_date | day; DAX calculated table, with an "Analysis Window" column | 1,096 |

Relationships (all one-to-many, single direction): dim_date[Date] to fact_items[order_date] and fact_orders[order_date]; dim_state[customer_state] to fact_items[customer_state] and fact_orders[customer_state]; dim_category[category_english] to fact_items[category_english]. There is deliberately no relationship between the two fact tables.

Design decisions:
- Two fact tables avoid counting an order twice when it has items from several categories. Category analysis uses fact_items; delivery, review and payment analysis uses fact_orders. A category slicer therefore does not filter fact_orders measures.
- Analysis window: January 2017 to August 2018 (dim_date[Analysis Window] = "In window", 608 days). 2016 and Sep-Oct 2018 are sparse or incomplete.
- Empty values in the order-level export are blank (the text "NULL" written by MySQL Workbench was removed before import).

## Measures
| Measure | Definition (DAX) | Status |
|---|---|---|
| Revenue | `SUM(fact_items[price])` | verified vs SQL |
| Freight | `SUM(fact_items[freight_value])` | verified |
| Orders | `DISTINCTCOUNT(fact_items[order_id])` | verified |
| Units Sold | `COUNTROWS(fact_items)` | verified |
| Avg Order Value | `DIVIDE([Revenue], [Orders])` | verified |
| Items per Order | `DIVIDE([Units Sold], [Orders])` | verified |
| Customers | `DISTINCTCOUNT(fact_items[customer_unique_id])` | verified |
| Freight % of Price | `DIVIDE([Freight], [Revenue])` | verified |
| Revenue % of Selection | `DIVIDE([Revenue], CALCULATE([Revenue], ALLSELECTED()))` | checked at 100% |
| Revenue Previous Month | previous month's revenue, only from Feb 2017 | verified through MoM |
| MoM Growth % | `DIVIDE([Revenue] - [Revenue Previous Month], [Revenue Previous Month])` | verified, 20 months |
| Revenue Same Month Last Year | same month a year earlier, only from Jan 2018 | verified through YoY |
| YoY Growth % | `DIVIDE([Revenue] - [Revenue Same Month Last Year], [Revenue Same Month Last Year])` | verified, 8 months |
| Orders (fact_orders) | `COUNTROWS(fact_orders)` | verified |
| Delivered Orders | `COUNT(fact_orders[delivery_days])` | verified |
| Avg Delivery Days | `AVERAGE(fact_orders[delivery_days])` | verified |
| Median Delivery Days | `MEDIAN(fact_orders[delivery_days])` | verified |
| Late Delivery % | `DIVIDE(SUM(fact_orders[is_late]), [Delivered Orders])` | verified |
| Orders with Review | `COUNT(fact_orders[review_score])` | verified |
| Avg Review Score | `AVERAGE(fact_orders[review_score])` | verified |
| Avg Review Score (Late) | filter is_late = 1 | verified |
| Avg Review Score (On Time) | filter is_late = 0 and not blank | verified after fix |
| Latest Month Revenue / MoM % / YoY % | Aug 2018 vs Jul 2018 and Aug 2017, ignoring date slicers | verified vs SQL, including under the South slicer (Aug 2018 vs Jul 2018 and Aug 2017) |

## Lessons recorded
- In DAX, BLANK() = 0 is true, so a filter `is_late = 0` also matched undelivered orders (blank) and gave 4.25 instead of 4.29. Fixed with `NOT ISBLANK(...)`.
- Joining payments to items inflated revenue by 4.5%; revenue is calculated from items only.