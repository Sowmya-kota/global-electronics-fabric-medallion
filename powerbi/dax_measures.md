# DAX Measures: sm_global_electronics

All 25 measures live on `fact_sales`, grouped into display folders. Each one was tested in **DAX query view** against values computed independently from the Gold tables before it was added to the model.

Each entry gives the **business question**, the **DAX**, and the **trap** it avoids.

---

## 1. Sales

### Revenue
*How much did we sell?*
```dax
Revenue = SUM ( fact_sales[sales_amount_usd] )
```
Revenue is calculated once, upstream in the Gold notebook (quantity × unit price), so DAX stays simple and every tool reports the same number.

### Cost · Gross Profit
```dax
Cost = SUM ( fact_sales[cost_amount_usd] )
Gross Profit = SUM ( fact_sales[gross_profit_usd] )
```

### Gross Margin %
*Out of every dollar sold, how much is profit?*
```dax
Gross Margin % = DIVIDE ( [Gross Profit], [Revenue] )
```
**Trap:** averaging line-level margins gives **54.9%**; the true margin is **58.6%**. Ratios must be sum ÷ sum. `DIVIDE` returns blank instead of an error on zero.

### Orders
```dax
Orders = DISTINCTCOUNT ( fact_sales[order_number] )
```
**Trap:** the fact grain is the order *line*. `COUNTROWS` returns 62,884; the real order count is **26,326**.

### Units Sold
```dax
Units Sold = SUM ( fact_sales[quantity] )
```

### Avg Order Value
*How much is spent per order?*
```dax
Avg Order Value = DIVIDE ( [Revenue], [Orders] )
```
**Trap:** `AVERAGE(sales_amount_usd)` gives the average line value ($886.64), not the order value (**$2,117.89**).

### Customers
*How many customers actually bought?*
```dax
Customers = DISTINCTCOUNT ( fact_sales[customer_key] )
```
**Traps:** the customer table has 15,266 rows, but only **11,887** customers ever purchased. Distinct counts don't add up: customers by year sum to 21,087.

### Units per Order · Avg Unit Price
*Did baskets shrink because customers bought fewer items, or cheaper ones?*
```dax
Units per Order = DIVIDE ( [Units Sold], [Orders] )
Avg Unit Price = DIVIDE ( [Revenue], [Units Sold] )
```
These decompose AOV: units per order stayed flat (~7.5) while the average unit price fell from $319 to $267, so the cause is a product-mix shift.

### Revenue % of Total
*What share of revenue does each category bring?*
```dax
Revenue % of Total =
DIVIDE ( [Revenue], CALCULATE ( [Revenue], REMOVEFILTERS ( dim_product ) ) )
```
`REMOVEFILTERS(dim_product)` clears only product filters, so a year filter still applies (share of *that year's* revenue).

---

## 2. Time Comparison

### Revenue PY · Revenue YoY %
```dax
Revenue PY =
IF (
    HASONEVALUE ( dim_date[year] ),
    CALCULATE ( [Revenue], REMOVEFILTERS ( dim_date ), SAMEPERIODLASTYEAR ( dim_date[date] ) )
)

Revenue YoY % = DIVIDE ( [Revenue] - [Revenue PY], [Revenue PY] )
```
- `REMOVEFILTERS(dim_date)` clears the current year filter before shifting dates, so the measure works whether or not the date table is marked.
- `HASONEVALUE` returns blank when several years are in context, where "previous year" has no meaning. A visual with months on the axis therefore needs a single-year filter.

### Revenue LFL · LFL PY · LFL YoY % (like-for-like)
*Is 2021 really collapsing?* The 2021 data ends on 20 Feb, so it's compared on the same 1 Jan – 20 Feb window every year (`dim_date[is_ytd_comparable]`, built in Gold).
```dax
Revenue LFL =
CALCULATE ( [Revenue], KEEPFILTERS ( dim_date[is_ytd_comparable] = TRUE () ) )

Revenue LFL PY =
IF (
    HASONEVALUE ( dim_date[year] ),
    VAR _year = SELECTEDVALUE ( dim_date[year] )
    RETURN
        CALCULATE (
            [Revenue],
            REMOVEFILTERS ( dim_date ),
            dim_date[year] = _year - 1,
            dim_date[is_ytd_comparable] = TRUE ()
        )
)

Revenue LFL YoY % = DIVIDE ( [Revenue LFL] - [Revenue LFL PY], [Revenue LFL PY] )
```
**Trap:** naive YoY for 2021 is **–88.8%**; like-for-like is **–70.2%**. `KEEPFILTERS` adds the window on top of user selections instead of replacing them.

---

## 3. Channel & Delivery

### Online Revenue · Online Revenue %
```dax
Online Revenue = CALCULATE ( [Revenue], fact_sales[is_online] = TRUE () )
Online Revenue % = DIVIDE ( [Online Revenue], [Revenue] )
```

### Avg Delivery Days
```dax
Avg Delivery Days = AVERAGE ( fact_sales[delivery_days] )
```
**Trap:** in-store sales have no delivery, and Silver keeps them as NULL, not 0. `AVERAGE` ignores blanks; zeros would have dragged the average to about 1 day.

### Orders Delivered (role-playing date)
*How many orders were delivered each year?* This is the operations view, by delivery date.
```dax
Orders Delivered =
CALCULATE (
    [Orders],
    USERELATIONSHIP ( fact_sales[delivery_date_key], dim_date[date_key] ),
    NOT ISBLANK ( fact_sales[delivery_date_key] )
)
```
`USERELATIONSHIP` activates the inactive delivery-date relationship for this measure only. **Trap found during testing:** without the `NOT ISBLANK` filter, 20,746 in-store orders appeared under a "(Blank)" year, because fact rows with no matching key fall into the dimension's blank member.

---

## 4. Currency & Stores

### Revenue (Local)
*What did each market earn in its own currency?*
```dax
Revenue (Local) =
IF ( HASONEVALUE ( fact_sales[currency_code] ), SUM ( fact_sales[sales_amount_local] ) )
```
**Trap:** summing local amounts across currencies gives **55,349,466**, a plausible-looking but meaningless number (AUD + EUR + GBP…). The measure is blank unless exactly one currency is in context.

### Selling Sq Meters · Revenue per Sq Meter
*Which stores use their floor space best?*
```dax
Selling Sq Meters =
SUMX ( FILTER ( dim_store, [Revenue] > 0 ), dim_store[square_meters] )

Revenue per Sq Meter = DIVIDE ( [Revenue], [Selling Sq Meters] )
```
**Trap (denominator):** 9 physical stores never traded. Dividing by all floor space ranks Canada #3 ($506); using only trading stores ranks it #1 (**$750**). `[Revenue]` inside `FILTER` is evaluated per store through **context transition**.

### Stores Without Sales · Last Sale Date
```dax
Stores Without Sales =
COUNTROWS (
    FILTER ( dim_store, dim_store[store_type] = "Physical" && ISBLANK ( [Revenue] ) )
)

Last Sale Date = MAXX ( fact_sales, RELATED ( dim_date[date] ) )
```
Result: **9** stores with no sales; `Last Sale Date` identifies the 5 that closed mid-period (e.g. Australia – Northern Territory, last sale 29 Apr 2016), which explains the bottom of the productivity ranking.

---

## Concepts demonstrated

| Concept | Measures |
|---|---|
| Filter context, sum ÷ sum ratios | Gross Margin %, AOV |
| `DISTINCTCOUNT` vs `COUNTROWS` | Orders, Customers |
| `CALCULATE` with `REMOVEFILTERS` / `KEEPFILTERS` | Revenue % of Total, Revenue PY, Revenue LFL |
| Time intelligence (`SAMEPERIODLASTYEAR`), `VAR` | Revenue PY, Revenue LFL PY |
| Role-playing dimension (`USERELATIONSHIP`) | Orders Delivered |
| Guards (`HASONEVALUE`) | Revenue PY, Revenue (Local) |
| Iterators and context transition (`SUMX`, `FILTER`, `MAXX`, `RELATED`) | Selling Sq Meters, Stores Without Sales, Last Sale Date |
