-- Databricks notebook source
USE CATALOG data_engineering_classic;
USE SCHEMA olist;

-- COMMAND ----------

CREATE OR REPLACE TABLE silver_orders_inc AS
SELECT * FROM silver_orders WHERE purchased_at < '2018-01-01';

-- COMMAND ----------

CREATE OR REPLACE TABLE data_engineering_classic.olist.silver_orders_inc AS
SELECT * FROM data_engineering_classic.olist.silver_orders
WHERE purchased_at < '2018-01-01';

-- COMMAND ----------

SELECT COUNT(*) AS orders_before_merge
FROM data_engineering_classic.olist.silver_orders_inc;

-- COMMAND ----------

MERGE INTO data_engineering_classic.olist.silver_orders_inc AS t
USING (SELECT * FROM data_engineering_classic.olist.silver_orders
       WHERE purchased_at >= '2018-01-01' AND purchased_at < '2018-02-01') AS s
ON t.order_id = s.order_id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;

-- COMMAND ----------

MERGE INTO data_engineering_classic.olist.silver_orders_inc AS t
USING (SELECT * FROM data_engineering_classic.olist.silver_orders
       WHERE purchased_at >= '2018-01-01' AND purchased_at < '2018-02-01') AS s
ON t.order_id = s.order_id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;

-- COMMAND ----------

SELECT COUNT(*) AS orders_after_merge
FROM data_engineering_classic.olist.silver_orders_inc;

-- COMMAND ----------

DESCRIBE HISTORY data_engineering_classic.olist.silver_orders_inc;

-- COMMAND ----------

