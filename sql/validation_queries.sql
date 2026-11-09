-- =====================================================================
-- Validation & analysis queries (Spark SQL in notebooks; add dbo. prefix
-- in the Lakehouse SQL analytics endpoint)
-- =====================================================================

-- 1. Row counts: Bronze vs Silver (expect identical; 0 rejects)
SELECT 'sales' AS tbl, (SELECT COUNT(*) FROM bronze_sales) AS bronze, (SELECT COUNT(*) FROM silver_sales) AS silver
UNION ALL SELECT 'customers', (SELECT COUNT(*) FROM bronze_customers), (SELECT COUNT(*) FROM silver_customers)
UNION ALL SELECT 'products',  (SELECT COUNT(*) FROM bronze_products),  (SELECT COUNT(*) FROM silver_products)
UNION ALL SELECT 'stores',    (SELECT COUNT(*) FROM bronze_stores),    (SELECT COUNT(*) FROM silver_stores)
UNION ALL SELECT 'fx',        (SELECT COUNT(*) FROM bronze_exchange_rates), (SELECT COUNT(*) FROM silver_exchange_rates);

-- 2. Delivery business rule (Online: all delivered 1-17 days; In-store: none)
SELECT CASE WHEN is_online THEN 'Online' ELSE 'In-store' END AS channel,
       COUNT(*) AS order_lines, COUNT(delivery_date) AS with_delivery_date,
       MIN(delivery_days) AS min_days, ROUND(AVG(delivery_days), 2) AS avg_days, MAX(delivery_days) AS max_days
FROM silver_sales GROUP BY is_online;

-- 3. Revenue, profit and margin by year
SELECT d.year, COUNT(DISTINCT f.order_number) AS orders, ROUND(SUM(f.sales_amount_usd),0) AS revenue_usd,
       ROUND(SUM(f.gross_profit_usd),0) AS profit_usd,
       ROUND(SUM(f.gross_profit_usd)/SUM(f.sales_amount_usd)*100,1) AS margin_pct
FROM fact_sales f JOIN dim_date d ON f.order_date_key = d.date_key
GROUP BY d.year ORDER BY d.year;

-- 4. Like-for-like comparison (1 Jan - 20 Feb each year)
SELECT d.year, ROUND(SUM(f.sales_amount_usd),0) AS revenue_jan1_to_feb20
FROM fact_sales f JOIN dim_date d ON f.order_date_key = d.date_key
WHERE d.is_ytd_comparable
GROUP BY d.year ORDER BY d.year;

-- 5. Category performance
SELECT p.category, ROUND(SUM(f.sales_amount_usd),0) AS revenue_usd,
       ROUND(SUM(f.gross_profit_usd)/SUM(f.sales_amount_usd)*100,1) AS margin_pct
FROM fact_sales f JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.category ORDER BY revenue_usd DESC;

-- 6. Currency conversion check (USD local = USD; EUR/GBP smaller; CAD/AUD larger)
SELECT currency_code, ROUND(SUM(sales_amount_usd),0) AS revenue_usd, ROUND(SUM(sales_amount_local),0) AS revenue_local
FROM fact_sales GROUP BY currency_code ORDER BY revenue_usd DESC;

-- 7. Hand-check one order: 68.00 USD x 1.3884 = 94.41 CAD
SELECT order_number, line_item, currency_code, quantity, unit_price_usd, exchange_rate, sales_amount_usd, sales_amount_local
FROM fact_sales WHERE order_number = 366000;

-- 8. Pipeline run history (logged_at is UTC)
SELECT logged_at, status, failed_activity, bronze_sales_rows, silver_sales_rows, fact_sales_rows, dq_rejected_rows, error_message
FROM etl_run_log ORDER BY logged_at DESC;

-- 9. Data-quality history per run
SELECT run_at, table_name, rule_name, severity, failed_rows, total_rows, failed_pct
FROM silver_dq_results ORDER BY run_at DESC, table_name, rule_name;
