/* ==============================================================
   Sales Performance Dashboard — SQL Server Analysis Queries
   Author  : Ilham Hafizt
   Tools   : SQL Server (T-SQL / SSMS)
   Database: sales_db
   Table   : dbo.sales_transactions
   Source  : sales_data_clean.csv (hasil cleaning Python)
   ============================================================== */


-- ============================================================
-- 0. SETUP — Buat Database & Tabel, Import Data
-- ============================================================

-- Buat database
CREATE DATABASE sales_db;
GO

USE sales_db;
GO

-- Buat tabel transaksi
CREATE TABLE dbo.sales_transactions (
    order_id          VARCHAR(15)     NOT NULL PRIMARY KEY,
    order_date        DATE            NOT NULL,
    order_year        SMALLINT        NOT NULL,
    order_month       TINYINT         NOT NULL,
    order_month_name  VARCHAR(15)     NOT NULL,
    order_quarter     CHAR(2)         NOT NULL,
    customer_name     VARCHAR(100)    NOT NULL,
    customer_segment  VARCHAR(30)     NOT NULL,
    product_name      VARCHAR(60)     NOT NULL,
    category          VARCHAR(30)     NOT NULL,
    region            VARCHAR(50)     NOT NULL,
    sales_channel     VARCHAR(30)     NOT NULL,
    payment_method    VARCHAR(30)     NOT NULL,
    salesperson       VARCHAR(60)     NOT NULL,
    quantity          INT             NOT NULL,
    unit_price        BIGINT          NOT NULL,
    discount_percent  DECIMAL(5,2)    NOT NULL DEFAULT 0,
    discount_amount   BIGINT          NOT NULL DEFAULT 0,
    gross_sales       BIGINT          NOT NULL,
    net_sales         BIGINT          NOT NULL,
    rating            DECIMAL(3,1)    NULL
);
GO

-- Import menggunakan BULK INSERT (jalankan dari SSMS)
BULK INSERT dbo.sales_transactions
FROM 'C:\Users\YourUser\sales_data_clean.csv'  -- sesuaikan path
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

PRINT 'Data berhasil diimpor: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' baris';


-- ============================================================
-- 1. RINGKASAN EKSEKUTIF (KPI Utama)
-- ============================================================
SELECT
    COUNT(DISTINCT order_id)                                AS total_orders,
    SUM(quantity)                                           AS total_qty_sold,
    FORMAT(SUM(gross_sales), 'N0')                         AS total_gross_sales,
    FORMAT(SUM(net_sales), 'N0')                           AS total_net_sales,
    FORMAT(SUM(discount_amount), 'N0')                     AS total_discount_given,
    CAST(
        100.0 * SUM(discount_amount) / SUM(gross_sales)
        AS DECIMAL(5,2))                                    AS discount_rate_pct,
    ROUND(AVG(CAST(rating AS FLOAT)), 2)                   AS avg_customer_rating,
    COUNT(DISTINCT customer_name)                          AS unique_customers,
    COUNT(DISTINCT product_name)                           AS unique_products
FROM dbo.sales_transactions;
GO


-- ============================================================
-- 2. TREND PENJUALAN BULANAN (untuk Line Chart)
-- ============================================================
SELECT
    order_year,
    order_month,
    order_month_name,
    order_quarter,
    COUNT(order_id)              AS total_orders,
    SUM(quantity)                AS total_qty,
    SUM(gross_sales)             AS gross_sales,
    SUM(net_sales)               AS net_sales,
    SUM(discount_amount)         AS total_discount,
    ROUND(AVG(CAST(rating AS FLOAT)), 2) AS avg_rating,
    -- MoM Growth
    SUM(net_sales) - LAG(SUM(net_sales)) OVER (
        ORDER BY order_year, order_month)               AS mom_growth_rp,
    CAST(
        100.0 * (SUM(net_sales) - LAG(SUM(net_sales)) OVER (ORDER BY order_year, order_month))
        / NULLIF(LAG(SUM(net_sales)) OVER (ORDER BY order_year, order_month), 0)
    AS DECIMAL(6,2))                                    AS mom_growth_pct
FROM dbo.sales_transactions
GROUP BY order_year, order_month, order_month_name, order_quarter
ORDER BY order_year, order_month;
GO


-- ============================================================
-- 3. PERFORMA PER PRODUK (untuk Bar/Table Chart)
-- ============================================================
SELECT
    product_name,
    category,
    COUNT(order_id)                                     AS total_orders,
    SUM(quantity)                                       AS total_qty,
    SUM(gross_sales)                                    AS gross_sales,
    SUM(net_sales)                                      AS net_sales,
    SUM(discount_amount)                                AS total_discount,
    ROUND(AVG(CAST(discount_percent AS FLOAT)), 2)     AS avg_discount_pct,
    ROUND(AVG(CAST(rating AS FLOAT)), 2)               AS avg_rating,
    -- Ranking per net_sales
    RANK() OVER (ORDER BY SUM(net_sales) DESC)         AS rank_by_net_sales
FROM dbo.sales_transactions
GROUP BY product_name, category
ORDER BY net_sales DESC;
GO


-- ============================================================
-- 4. PERFORMA PER REGION (untuk Map/Bar Chart)
-- ============================================================
SELECT
    region,
    COUNT(DISTINCT order_id)                           AS total_orders,
    COUNT(DISTINCT customer_name)                     AS unique_customers,
    SUM(quantity)                                      AS total_qty,
    SUM(net_sales)                                     AS net_sales,
    ROUND(AVG(CAST(rating AS FLOAT)), 2)              AS avg_rating,
    -- Proporsi kontribusi
    CAST(
        100.0 * SUM(net_sales) /
        SUM(SUM(net_sales)) OVER ()
    AS DECIMAL(5,2))                                   AS contribution_pct
FROM dbo.sales_transactions
GROUP BY region
ORDER BY net_sales DESC;
GO


-- ============================================================
-- 5. ANALISIS SALURAN PENJUALAN & SEGMEN PELANGGAN
-- ============================================================
SELECT
    sales_channel,
    customer_segment,
    COUNT(order_id)                                    AS total_orders,
    SUM(net_sales)                                     AS net_sales,
    ROUND(AVG(CAST(net_sales AS FLOAT)), 0)           AS avg_order_value,
    ROUND(AVG(CAST(rating AS FLOAT)), 2)              AS avg_rating,
    CAST(
        100.0 * SUM(net_sales) /
        SUM(SUM(net_sales)) OVER ()
    AS DECIMAL(5,2))                                   AS contribution_pct
FROM dbo.sales_transactions
GROUP BY sales_channel, customer_segment
ORDER BY net_sales DESC;
GO


-- ============================================================
-- 6. PERFORMA SALESPERSON (untuk Leaderboard)
-- ============================================================
SELECT
    salesperson,
    COUNT(DISTINCT order_id)                           AS total_orders,
    SUM(quantity)                                      AS total_qty,
    SUM(net_sales)                                     AS net_sales,
    ROUND(AVG(CAST(net_sales AS FLOAT)), 0)           AS avg_order_value,
    ROUND(AVG(CAST(rating AS FLOAT)), 2)              AS avg_rating,
    COUNT(DISTINCT customer_name)                     AS customers_handled,
    RANK() OVER (ORDER BY SUM(net_sales) DESC)        AS rank_overall
FROM dbo.sales_transactions
GROUP BY salesperson
ORDER BY net_sales DESC;
GO


-- ============================================================
-- 7. ANALISIS QUARTERLY YoY (Year-over-Year)
-- ============================================================
WITH quarterly AS (
    SELECT
        order_year,
        order_quarter,
        SUM(net_sales)          AS net_sales,
        COUNT(order_id)         AS total_orders,
        SUM(quantity)           AS total_qty
    FROM dbo.sales_transactions
    GROUP BY order_year, order_quarter
)
SELECT
    curr.order_year,
    curr.order_quarter,
    curr.net_sales                                     AS current_net_sales,
    prev.net_sales                                     AS prev_year_net_sales,
    curr.net_sales - ISNULL(prev.net_sales, 0)        AS yoy_growth_rp,
    CAST(
        100.0 * (curr.net_sales - ISNULL(prev.net_sales, 0))
        / NULLIF(prev.net_sales, 0)
    AS DECIMAL(6,2))                                   AS yoy_growth_pct,
    curr.total_orders,
    curr.total_qty
FROM quarterly curr
LEFT JOIN quarterly prev
    ON curr.order_quarter = prev.order_quarter
    AND curr.order_year   = prev.order_year + 1
ORDER BY curr.order_year, curr.order_quarter;
GO


-- ============================================================
-- 8. ANALISIS METODE PEMBAYARAN
-- ============================================================
SELECT
    payment_method,
    COUNT(order_id)                                    AS total_orders,
    SUM(net_sales)                                     AS net_sales,
    ROUND(AVG(CAST(net_sales AS FLOAT)), 0)           AS avg_order_value,
    CAST(
        100.0 * COUNT(order_id) /
        SUM(COUNT(order_id)) OVER ()
    AS DECIMAL(5,2))                                   AS order_share_pct
FROM dbo.sales_transactions
GROUP BY payment_method
ORDER BY net_sales DESC;
GO


-- ============================================================
-- 9. TOP 10 CUSTOMER BERDASARKAN NET SALES
-- ============================================================
SELECT TOP 10
    customer_name,
    customer_segment,
    region,
    COUNT(DISTINCT order_id)                           AS total_orders,
    SUM(quantity)                                      AS total_qty,
    SUM(net_sales)                                     AS total_net_sales,
    ROUND(AVG(CAST(rating AS FLOAT)), 2)              AS avg_rating
FROM dbo.sales_transactions
WHERE customer_name <> 'Unknown Customer'
GROUP BY customer_name, customer_segment, region
ORDER BY total_net_sales DESC;
GO


-- ============================================================
-- 10. VIEW UNTUK LOOKER STUDIO (Export-Ready)
-- ============================================================
CREATE OR ALTER VIEW vw_sales_looker AS
SELECT
    t.order_id,
    CONVERT(VARCHAR(10), t.order_date, 120)    AS order_date,
    t.order_year,
    t.order_month,
    t.order_month_name,
    t.order_quarter,
    t.customer_name,
    t.customer_segment,
    t.product_name,
    t.category,
    t.region,
    t.sales_channel,
    t.payment_method,
    t.salesperson,
    t.quantity,
    t.unit_price,
    t.discount_percent,
    t.discount_amount,
    t.gross_sales,
    t.net_sales,
    t.rating,
    -- Label bulan untuk sorting
    CAST(t.order_year AS VARCHAR(4)) + '-' +
        RIGHT('0' + CAST(t.order_month AS VARCHAR(2)), 2) AS year_month
FROM dbo.sales_transactions t;
GO

PRINT 'View vw_sales_looker berhasil dibuat.';

-- Export view ke CSV untuk Looker Studio
-- (Jalankan query berikut lalu Save Results As CSV di SSMS)
SELECT * FROM vw_sales_looker ORDER BY order_date;
GO
