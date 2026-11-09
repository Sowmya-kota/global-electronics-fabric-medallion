# Source Data Profile

Profiled before writing any transformations.

| File | Rows | Encoding | Unique key | Date range |
|---|---|---|---|---|
| Sales.csv | 62,884 | UTF-8 (ASCII) | Order Number + Line Item | 2016-01-01 → 2021-02-20 |
| Customers.csv | 15,266 | **Windows-1252** | CustomerKey | births 1935 → 2002 |
| Products.csv | 2,517 | ASCII | ProductKey | — |
| Stores.csv | 67 | **UTF-8** | StoreKey | opened 2005 → 2019 |
| Exchange_Rates.csv | 11,215 | ASCII | Date + Currency | 2015-01-01 → 2021-02-20 |

## Integrity (all clean)
- No duplicate keys in any table; no orphan customer, product or store keys in Sales.
- Every sale has an exchange rate for its order date and currency.
- Each order has exactly one customer, store, date and currency across its lines (26,326 orders, max 7 lines).
- No sales before a store's open date; no delivery before order; price > cost for every product.

## Findings that shaped the design
| Finding | Impact |
|---|---|
| Customers.csv is Windows-1252; 74 bytes (š, ž, Š, Ž, Ÿ) differ from ISO-8859-1 | Per-file encoding in Bronze; legacy charset setting on Spark 4 |
| Delivery Date blank for all 49,719 in-store lines; only Online (store 0, 13,165 lines) has delivery dates (1–17 days) | Treated as a business rule, not missing data |
| Prices stored as text, e.g. `"$2,899.99 "` | Parsed to DECIMAL in Silver |
| SubcategoryKey / CategoryKey have leading zeros (`0101`) | Kept as text |
| Canadian postcodes (`V3L 5H1`) | Zip code kept as text |
| 25% of city values ALL CAPS | Title-cased only when all caps |
| Product names contain `"` (e.g. `52" LCD`) | CSV quote/escape options set explicitly |
| Prices are USD; exchange rate = local currency per 1 USD | Convert USD → local once, in Gold |
| 2021 has only ~7 weeks of data | Like-for-like date flag in Gold |
| 3,379 customers never purchased; 25 products never sold | Kept in dimensions (valid master data) |
| 5 currencies: USD 54% of lines, EUR 20%, GBP 13%, CAD 9%, AUD 5% | Local-currency reporting supported |
