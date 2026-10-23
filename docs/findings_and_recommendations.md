# Findings and Recommendations (draft, updated as phases complete)

Basis: valid orders (see docs/data_quality_log.md); revenue = item price excluding freight; window Jan 2017 to Aug 2018 unless stated.

## A. Overall performance
- All valid orders: 98,199 orders, 112,101 units, revenue 13,494,400.74, freight 2,241,126.29, average order value 137.42, 94,983 customers (about 1.03 orders per customer).
- The analysis window holds 97,905 orders and revenue of 13,449,529.68. The other 294 orders (44,871.06) fall in Sep-Dec 2016 and Sep 2018.
- Jan-Aug revenue: 3,080,850.81 in 2017 vs 7,341,037.41 in 2018 (+138.3%). Monthly YoY growth falls from +687.2% (Jan) to +49.4% (Aug); early months are inflated by a very small 2017 base.
- Growth came from order volume: monthly orders rose from 787 (Jan 2017) to 7,187 (Jan 2018) while average order value stayed between 124.76 and 152.60.
- Peak month: November 2017, revenue 1,003,862.14 from 7,421 orders (+52.1% MoM, then -26.1% in December). Cause not established from monthly data.
- 2018 plateau: Jun-Aug 2018 averaged about 13% below Apr-May 2018; Aug 2018 was -3.3% MoM.
- 90.1% of valid orders contain a single item; average item price is about 120.38.

## B. Categories (window Jan 2017 - Aug 2018)
- 74 category labels (including "Unknown"); no category exceeds 9.3% of revenue. Top 5 = 39.9%, top 10 = 62.4%, top 15 = 76.3%.
- Largest: health_beauty 1,251,145.54 (9.3%), watches_gifts 1,194,824.97 (8.9%), bed_bath_table 1,035,485.07 (7.7%).
- Products with no category account for 1.33% of revenue.
- The ten smallest categories each have fewer than 30 orders; too small for firm conclusions.
- cool_stuff grew only +8.9% (Jan-Aug 2018 vs 2017) against +138.3% overall; its share fell from about 6.9% to 3.1%. Cause not established.
- Among 2018's ten largest categories, fastest growth: baby +264.1%, watches_gifts +243.4%, health_beauty +211.2% (small 2017 bases).

## C. Regions (customer state; no store data exists)
- 27 states. SP = 38.3% of revenue; SP, RJ, MG together = 63.4%; top 5 = 73.9%.
- SP's share of Jan-Aug revenue rose from about 36.1% (2017) to 40.3% (2018); RJ fell from about 14.4% to 12.3% (RJ +103.7% vs +138.3% overall).
- Average order value is lowest in SP (125.56); small states are higher (e.g. PB 216.65 on 530 orders).
- Freight is 13.8% of item price in SP, 16.8-17.1% in RJ and MG, and above 20% in many northern and north-eastern states (up to 27.8% in RR). Distance is not in the data, so no cause is claimed.

## D. Peak day
- 24 Nov 2017: 1,166 valid orders, 15.7% of November's 7,421 and about 4.7 times the November daily average. Coincides with Black Friday 2017; the data holds no promotion information, so causation is not established.

## E. Delivery and customer experience
- 96,470 delivered valid orders with a delivery date: average 12.6 days, median 10.2 days, 6.8% delivered after the estimated date.
- Worst period: Nov 2017 (15.2 days, 12.4% late) to Mar 2018 (16.3 days, 19.0% late; Feb 2018 averaged 16.9 days). By Aug 2018: 7.7 days, 6.2% late. Orders still in transit at the end of the data are not included, which may flatter the latest months.
- By state (at least 100 delivered orders): SP 8.8 days (4.5% late); slowest AM 26.4, AL 24.5, PA 23.8 days. Highest late shares: AL 21.4%, MA 17.4%, SE 15.2%. RJ, second-largest by revenue: 15.3 days, 12.1% late. AM shows a low late share (2.8%) despite long delivery times, so estimates appear to differ by location (not examined).
- Reviews on valid orders: 58.4% five-star, 19.5% four, 8.3% three, 3.1% two, 10.7% one; 732 valid orders have no review.
- Late deliveries average 2.27 stars vs 4.29 on time (6,381 vs 89,443 reviewed orders). An association; other factors may differ between the groups.

## F. Payments
- Main payment type on valid orders: credit card 75.5% (average maximum installments 3.6), boleto 19.9%, voucher 3.1%, debit card 1.5%.
- Reconciliation: payments 16,008,872.12 vs item price + freight 15,843,553.24 (gap 165,318.88). Pieces: +162,591.95 payments on 775 orders with no items; +2,838.38 on valid orders; +32.01 canceled orders; 0.00 unavailable; -143.46 items of the one valid order with no payment row. The pieces sum exactly to the gap.
- On valid orders, 97,897 of 98,198 (99.7%) have payments equal to item price + freight within one cent; 262 are higher (3,038.13 in total) and 39 lower (199.08). The data does not explain the differences.
- 162,591.95 of payments sits on orders with no items (mostly unavailable and canceled). The data contains no refund information, so the outcome of that money is unknown.

## Recommendations (draft; each needs the additional information listed)
1. Improve delivery reliability first in high-revenue, high-lateness states, starting with RJ (12.1% late vs 4.5% in SP), then the north-east (AL, MA, SE). Evidence: late orders average 2.27 stars vs 4.29. Needs carrier, seller and distance data to find causes.
2. Plan capacity for peak events. Nov 2017 had 24 Nov at about 4.7 times the daily average, and that month had 12.4% late deliveries. Needs the promotion calendar and carrier capacity.
3. Reduce dependence on SP (38.3% of revenue, share rising from about 36.1% to 40.3%) and look into why RJ grew more slowly (+103.7% vs +138.3%). Needs regional marketing and pricing data.
4. Investigate cool_stuff (+8.9% vs +138.3% overall). Needs seller and catalog data for that category.
5. Ask finance or operations what happened to the 162,591.95 of payments on orders with no items (refunds, failed captures or data issues).
6. Review shipping cost in the north and north-east, where freight reaches 20-28% of item price. Needs distance and carrier cost data.

## Information that would improve future analysis
Product cost and margin, discounts and promotions, refunds and returns, seller and store locations with distances, and more than one prior year of data.

## Limitations
- No cost, profit or discount data. Currency to be confirmed from the dataset documentation.
- Only about 20 months of meaningful data; seasonality cannot be separated from growth with one prior year.