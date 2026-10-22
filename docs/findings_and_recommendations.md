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

## Limitations
- No cost, profit or discount data. Currency to be confirmed from the dataset documentation.
- Only about 20 months of meaningful data; seasonality cannot be separated from growth with one prior year.