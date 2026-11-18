-- Databricks notebook source
USE CATALOG data_engineering_classic;
USE SCHEMA olist;

-- COMMAND ----------

CREATE OR REPLACE TABLE dim_customer AS SELECT * FROM silver_customers;
CREATE OR REPLACE TABLE dim_product  AS SELECT * FROM silver_products;
CREATE OR REPLACE TABLE dim_seller   AS SELECT * FROM silver_sellers;

-- COMMAND ----------

CREATE OR REPLACE TABLE dim_date AS
SELECT d AS date, year(d) AS year, month(d) AS month,
       date_format(d, 'MMM yyyy') AS month_name, dayofweek(d) AS day_of_week
FROM (SELECT explode(sequence(DATE'2016-01-01', DATE'2018-12-31', INTERVAL 1 DAY)) AS d);

-- COMMAND ----------

CREATE OR REPLACE TABLE fact_order_items AS
SELECT i.order_id, i.item_seq, o.customer_id, i.product_id, i.seller_id,
       o.purchased_at, to_date(o.purchased_at) AS purchase_date,
       o.delivered_at, o.estimated_delivery_at,
       datediff(o.delivered_at, o.estimated_delivery_at) AS delay_days,
       i.price, i.freight
FROM silver_order_items i
JOIN silver_orders o ON i.order_id = o.order_id;

-- COMMAND ----------

SELECT (SELECT COUNT(*) FROM fact_order_items) AS fact_rows,
       (SELECT COUNT(*) FROM silver_order_items) AS silver_item_rows;

-- COMMAND ----------

CREATE OR REPLACE TABLE gold_monthly_revenue AS
SELECT date_trunc('month', purchased_at)        AS month,
       COUNT(DISTINCT order_id)                 AS orders,
       ROUND(SUM(price + freight), 2)           AS revenue,
       ROUND(SUM(price + freight) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM fact_order_items
GROUP BY 1
ORDER BY 1;

-- COMMAND ----------

CREATE OR REPLACE TABLE gold_category_revenue AS
SELECT p.category, ROUND(SUM(f.price), 2) AS revenue, COUNT(*) AS items_sold,
       RANK() OVER (ORDER BY SUM(f.price) DESC) AS revenue_rank
FROM fact_order_items f
JOIN dim_product p USING (product_id)
GROUP BY p.category;

-- COMMAND ----------

CREATE OR REPLACE TABLE gold_delivery_by_state AS
SELECT c.state,
       COUNT(DISTINCT f.order_id)                                    AS delivered_orders,
       ROUND(AVG(f.delay_days), 1)                                   AS avg_delay_days,
       ROUND(100 * AVG(CASE WHEN f.delay_days > 0 THEN 1 ELSE 0 END), 1) AS pct_late
FROM fact_order_items f
JOIN dim_customer c USING (customer_id)
WHERE f.delivered_at IS NOT NULL
GROUP BY c.state
ORDER BY pct_late DESC;

-- COMMAND ----------

SELECT ROUND(100 * AVG(CASE WHEN n > 1 THEN 1 ELSE 0 END), 1) AS repeat_customer_pct
FROM (SELECT c.customer_unique_id, COUNT(DISTINCT f.order_id) AS n
      FROM fact_order_items f
      JOIN dim_customer c USING (customer_id)
      GROUP BY c.customer_unique_id);