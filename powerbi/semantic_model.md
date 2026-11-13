# Semantic model: sm_global_electronics

Definition exported from Fabric with DAX `INFO.VIEW.*` functions (13 Nov 2026). Lineage tags and model/workspace IDs are omitted. Measure DAX with explanations: [`dax_measures.md`](dax_measures.md).

## Tables

| Table | Storage mode | Data category | Rows |
|---|---|---|---|
| fact_sales | Direct Lake | Regular | 62,884 |
| dim_customer | Direct Lake | Regular | 15,266 |
| dim_date | Direct Lake | Time (marked as date table, key = `date`) | 2,192 |
| dim_product | Direct Lake | Regular | 2,517 |
| dim_store | Direct Lake | Regular | 67 |

## Relationships

| From (many) | To (one) | Active | Cross-filter |
|---|---|---|---|
| fact_sales[order_date_key] | dim_date[date_key] | Yes | Single |
| fact_sales[customer_key] | dim_customer[customer_key] | Yes | Single |
| fact_sales[store_key] | dim_store[store_key] | Yes | Single |
| fact_sales[product_key] | dim_product[product_key] | Yes | Single |
| fact_sales[delivery_date_key] | dim_date[date_key] | No (used via USERELATIONSHIP) | Single |

## Columns

Hidden columns stay usable in measures and relationships but are not shown to report users.

### fact_sales

| Column | Type | Visible | Sort by |
|---|---|---|---|
| order_number | Integer | Yes |  |
| line_item | Integer | Hidden |  |
| order_date_key | Integer | Hidden |  |
| delivery_date_key | Integer | Hidden |  |
| customer_key | Integer | Hidden |  |
| store_key | Integer | Hidden |  |
| product_key | Integer | Hidden |  |
| currency_code | Text | Yes |  |
| is_online | True/False | Yes |  |
| delivery_days | Integer | Hidden |  |
| quantity | Integer | Hidden |  |
| unit_price_usd | Currency | Hidden |  |
| unit_cost_usd | Currency | Hidden |  |
| exchange_rate | Number | Hidden |  |
| sales_amount_usd | Number | Hidden |  |
| cost_amount_usd | Number | Hidden |  |
| gross_profit_usd | Number | Hidden |  |
| sales_amount_local | Number | Hidden |  |
| cost_amount_local | Number | Hidden |  |
| gross_profit_local | Number | Hidden |  |
| _batch_id | Text | Hidden |  |
| _processed_at | Date | Hidden |  |

### dim_customer

| Column | Type | Visible | Sort by |
|---|---|---|---|
| customer_key | Integer | Hidden |  |
| customer_name | Text | Yes |  |
| gender | Text | Yes |  |
| age | Integer | Yes |  |
| age_band | Text | Yes |  |
| birth_date | Date | Yes |  |
| city | Text | Yes |  |
| state_code | Text | Yes |  |
| state | Text | Yes |  |
| zip_code | Text | Yes |  |
| country | Text | Yes |  |
| continent | Text | Yes |  |
| _batch_id | Text | Hidden |  |
| _processed_at | Date | Hidden |  |

### dim_date

| Column | Type | Visible | Sort by |
|---|---|---|---|
| date_key | Integer | Hidden |  |
| date | Date | Yes |  |
| year | Integer | Yes |  |
| quarter_num | Integer | Hidden |  |
| quarter | Text | Yes | quarter_num |
| month_num | Integer | Hidden |  |
| month_name | Text | Yes | month_num |
| month_short | Text | Yes | month_num |
| year_month | Text | Yes | year_month_num |
| year_month_num | Integer | Hidden |  |
| day_of_month | Integer | Yes |  |
| day_of_week_num | Integer | Hidden |  |
| day_name | Text | Yes | day_of_week_num |
| iso_week | Integer | Yes |  |
| is_weekend | True/False | Yes |  |
| is_in_data_range | True/False | Yes |  |
| is_ytd_comparable | True/False | Yes |  |
| _batch_id | Text | Hidden |  |
| _processed_at | Date | Hidden |  |

### dim_product

| Column | Type | Visible | Sort by |
|---|---|---|---|
| product_key | Integer | Hidden |  |
| product_name | Text | Yes |  |
| brand | Text | Yes |  |
| color | Text | Yes |  |
| subcategory_key | Text | Hidden |  |
| subcategory | Text | Yes |  |
| category_key | Text | Hidden |  |
| category | Text | Yes |  |
| unit_cost_usd | Currency | Yes |  |
| unit_price_usd | Currency | Yes |  |
| unit_margin_usd | Currency | Yes |  |
| unit_margin_pct | Currency | Yes |  |
| _batch_id | Text | Hidden |  |
| _processed_at | Date | Hidden |  |

### dim_store

| Column | Type | Visible | Sort by |
|---|---|---|---|
| store_key | Integer | Hidden |  |
| store_name | Text | Yes |  |
| store_type | Text | Yes |  |
| country | Text | Yes |  |
| state | Text | Yes |  |
| square_meters | Integer | Yes |  |
| open_date | Date | Yes |  |
| store_age_years | Integer | Yes |  |
| _batch_id | Text | Hidden |  |
| _processed_at | Date | Hidden |  |

## Measures (25)

| Measure | Display folder | Format | Description |
|---|---|---|---|
| Revenue | 1.Sales | `$#,0;($#,0);$#,0` |  |
| Cost | 1.Sales | `$#,0;($#,0);$#,0` |  |
| Gross Profit | 1.Sales | `$#,0;($#,0);$#,0` |  |
| Gross Margin % | 1.Sales | `0.0%;-0.0%;0.0%` |  |
| Orders | 1.Sales | `#,0` |  |
| Units Sold | 1.Sales | `#,0` |  |
| Avg Order Value | 1.Sales | `$#,0.00;($#,0.00);$#,0.00` | Revenue ÷ distinct orders (value of one order, not one line). |
| Customers | 1.Sales | `#,0` |  |
| Units per Order | 1.Sales | `0.0` |  |
| Avg Unit Price | 1.Sales | `$#,0.00;($#,0.00);$#,0.00` |  |
| Revenue % of Total | 1.Sales | `0.0%;-0.0%;0.0%` |  |
| Revenue PY | 2.Time Comparison | `$#,0;($#,0);$#,0` |  |
| Revenue YoY % | 2.Time Comparison | `0.0%;-0.0%;0.0%` |  |
| Revenue LFL | 2.Time Comparison | `$#,0;($#,0);$#,0` |  |
| Revenue LFL PY | 2.Time Comparison | `$#,0;($#,0);$#,0` |  |
| Revenue LFL YoY % | 2.Time Comparison | `0.0%;-0.0%;0.0%` | Growth vs prior year using only 1 Jan – 20 Feb of each year, because 2021 data ends 20 Feb. |
| Online Revenue | 3.Channel & Delivery | `$#,0;($#,0);$#,0` |  |
| Online Revenue % | 3.Channel & Delivery | `0.0%;-0.0%;0.0%` |  |
| Avg Delivery Days | 3.Channel & Delivery | `0.0` |  |
| Orders Delivered | 3.Channel & Delivery | `#,0` |  |
| Revenue (Local) | 4.Currency & Stores | `#,0` | Revenue in the order’s own currency. Blank when several currencies are selected. |
| Selling Sq Meters | 4.Currency & Stores | `#,0` |  |
| Revenue per Sq Meter | 4.Currency & Stores | `$#,0;($#,0);$#,0` | Revenue ÷ floor space of stores with sales in the current selection. Excludes stores with no sales. |
| Stores Without Sales | — | `0` |  |
| Last Sale Date | — | `General Date` |  |

## Row-level security

| Role | Table | Filter | Permission |
|---|---|---|---|
| Country Manager | dim_customer | `[country] = "Germany"` | Read |

Validation and design notes: see the RLS section of the main [README](../README.md).
