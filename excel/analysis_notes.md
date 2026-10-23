# Excel analysis notes

## What Excel was used for
Excel was used as an independent check of the SQL results, not to repeat the SQL workflow.

| Task | Tool | Why |
|---|---|---|
| Cleaning, joins, exclusion rules, window functions | MySQL | Repeatable scripts; handles 1,000,163-row geolocation and multi-table joins |
| Reconciling totals, counts and monthly revenue | Excel | A second tool reproducing the same numbers builds confidence |
| Delivery and review summary checks | Excel | Quick AVERAGE, MEDIAN and AVERAGEIFS on the order-level export |
| Dashboard | Power BI | Interactive slicers and measures |

## What was checked
- fact_items export (112,101 rows): row count, revenue 13,494,400.74, freight 2,241,126.29, distinct orders 98,199, distinct customers 94,983.
- Window revenue (Jan 2017 to Aug 2018) 13,449,529.68; SP 5,150,778.70; health_beauty 1,251,145.54; Nov 2017 1,003,862.14.
- PivotTable by month: all 24 months with valid orders match the SQL monthly view to the cent.
- fact_orders export (98,199 rows): revenue, average delivery 12.56 days, median 10.22, late share 6.8%, 97,467 orders with a review, average review 2.27 for late and 4.29 for on-time deliveries.

## Notes
- Workbook `supporting_analysis.xlsx` holds only the summary and reconciliation. The full working workbook contains the dataset (CC BY-NC-SA 4.0) and is not committed.
- Workbench wrote SQL NULL as the text "NULL" in the order-level export; it was removed with PowerShell before loading into Excel so numeric columns stayed numeric.
- The Excel version used has no UNIQUE function, so distinct counts used a PivotTable with the Data Model.