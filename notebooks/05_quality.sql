-- Databricks notebook source
USE CATALOG data_engineering_classic;
USE SCHEMA olist;

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS dq_results
  (run_at TIMESTAMP, check_name STRING, passed BOOLEAN, detail STRING);

-- COMMAND ----------

INSERT INTO dq_results
SELECT current_timestamp(), 'unique order ids in silver_orders',
       COUNT(*) = COUNT(DISTINCT order_id),
       concat(COUNT(*) - COUNT(DISTINCT order_id), ' duplicates')
FROM silver_orders;

-- COMMAND ----------

INSERT INTO dq_results
SELECT current_timestamp(), 'every fact row has a customer',
       COUNT(*) = 0, concat(COUNT(*), ' orphan rows')
FROM fact_order_items f
LEFT JOIN dim_customer c USING (customer_id)
WHERE c.customer_id IS NULL;

-- COMMAND ----------

INSERT INTO dq_results
SELECT current_timestamp(), 'gold revenue matches silver revenue',
       abs(g.rev - s.rev) < 0.01, concat('gold=', g.rev, ' silver=', s.rev)
FROM (SELECT SUM(revenue) AS rev FROM gold_monthly_revenue) g,
     (SELECT SUM(price + freight) AS rev FROM silver_order_items) s;

-- COMMAND ----------

SELECT * FROM dq_results ORDER BY run_at DESC;

-- COMMAND ----------

