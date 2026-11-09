# Data Quality Rules (Silver layer)

Implemented in `nb_02_silver_transform`. **error** = row quarantined to `silver_dq_rejects`; **warning** = row kept, count logged in `silver_dq_results`.

| Table | Rule | Severity | Fails when |
|---|---|---|---|
| customers | customer_key_invalid | error | key missing or not an integer |
| customers | customer_key_duplicate | error | key appears more than once (latest load kept) |
| customers | birth_date_invalid | error | birthday not a valid `M/d/yyyy` date |
| customers | birth_date_implausible | warning | birth date in the future or before 1900 |
| customers | gender_unexpected | warning | gender not Male/Female |
| products | product_key_invalid | error | key missing or not an integer |
| products | product_key_duplicate | error | duplicate key |
| products | price_invalid | error | price missing, unparseable or ≤ 0 |
| products | cost_invalid | error | cost missing, unparseable or ≤ 0 |
| products | price_below_cost | warning | selling below cost |
| stores | store_key_invalid | error | key missing or not an integer |
| stores | store_key_duplicate | error | duplicate key |
| stores | open_date_invalid | error | open date unparseable |
| stores | physical_store_no_size | warning | physical store without floor size |
| exchange_rates | rate_date_invalid | error | date unparseable |
| exchange_rates | currency_invalid | error | currency code missing or not 3 letters |
| exchange_rates | rate_invalid | error | rate missing or ≤ 0 |
| exchange_rates | rate_duplicate | error | duplicate date + currency |
| exchange_rates | usd_rate_not_one | warning | USD rate ≠ 1 |
| sales | order_key_invalid | error | order number or line item missing |
| sales | order_line_duplicate | error | duplicate order number + line item |
| sales | order_date_invalid | error | order date unparseable |
| sales | quantity_invalid | error | quantity missing or ≤ 0 |
| sales | customer_not_found | error | customer not in `silver_customers` |
| sales | product_not_found | error | product not in `silver_products` |
| sales | store_not_found | error | store not in `silver_stores` |
| sales | fx_rate_not_found | error | no exchange rate for order date + currency |
| sales | delivery_before_order | error | delivery date earlier than order date |
| sales | online_missing_delivery | warning | online order without delivery date |
| sales | instore_has_delivery | warning | in-store sale with a delivery date |

**Gate:** if more than `max_reject_pct` (default 1%) of any table is rejected, the run fails after the rejects are saved.

**Results on the real data:** 0 failures on all 30 rules, 0% rejected.

**Negative test:** 6 synthetic rows (1 valid, 5 broken: invalid date, negative quantity, unknown customer, delivery before order, unknown currency). Only the valid row passed; each broken row was quarantined with the correct rule name and its original raw values.
