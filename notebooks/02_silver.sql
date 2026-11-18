-- Databricks notebook source
USE CATALOG data_engineering_classic;
USE SCHEMA olist;

-- COMMAND ----------

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT order_id) AS unique_orders
FROM bronze_orders;

-- COMMAND ----------

SELECT order_status,
       COUNT(*) AS orders,
       SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS missing_delivery
FROM bronze_orders
GROUP BY order_status
ORDER BY orders DESC;

-- COMMAND ----------

SELECT customer_city, COUNT(*) AS customers
FROM bronze_customers
GROUP BY customer_city
ORDER BY customers DESC
LIMIT 20;

-- COMMAND ----------

CREATE OR REPLACE TABLE silver_orders AS
SELECT DISTINCT
  order_id,
  customer_id,
  lower(order_status)                          AS order_status,
  to_timestamp(order_purchase_timestamp)       AS purchased_at,
  to_timestamp(order_approved_at)              AS approved_at,
  to_timestamp(order_delivered_customer_date)  AS delivered_at,
  to_timestamp(order_estimated_delivery_date)  AS estimated_delivery_at
FROM bronze_orders
WHERE order_id IS NOT NULL;

-- COMMAND ----------

CREATE OR REPLACE TABLE silver_customers AS
SELECT DISTINCT
  customer_id,
  customer_unique_id,
  initcap(trim(customer_city))  AS city,
  upper(trim(customer_state))   AS state
FROM bronze_customers;

-- COMMAND ----------

CREATE OR REPLACE TABLE silver_products AS
SELECT p.product_id,
       coalesce(t.product_category_name_english, 'unknown') AS category
FROM bronze_products p
LEFT JOIN bronze_category_translation t
  ON p.product_category_name = t.product_category_name;

-- COMMAND ----------

CREATE OR REPLACE TABLE silver_sellers AS
SELECT DISTINCT seller_id,
       initcap(trim(seller_city)) AS city,
       upper(seller_state)        AS state
FROM bronze_sellers;

-- COMMAND ----------

CREATE OR REPLACE TABLE silver_order_items AS
SELECT order_id,
       CAST(order_item_id AS INT)           AS item_seq,
       product_id,
       seller_id,
       CAST(price AS DECIMAL(10,2))         AS price,
       CAST(freight_value AS DECIMAL(10,2)) AS freight
FROM bronze_order_items
WHERE order_id IS NOT NULL
  AND try_cast(price AS DECIMAL(10,2)) > 0;

-- COMMAND ----------

SELECT COUNT(*) FROM quarantine_order_items

-- COMMAND ----------

SELECT COUNT(*) AS quarantined_rows FROM quarantine_order_items;

-- COMMAND ----------

SHOW TABLES IN data_engineering_classic.olist;

-- COMMAND ----------

CREATE OR REPLACE TABLE quarantine_order_items AS
SELECT *, 'missing order id or invalid price' AS reason
FROM bronze_order_items
WHERE order_id IS NULL
   OR try_cast(price AS DECIMAL(10,2)) IS NULL
   OR try_cast(price AS DECIMAL(10,2)) <= 0;


-- COMMAND ----------

CREATE OR REPLACE TABLE quarantine_order_items AS
SELECT *, 'missing order id or invalid price' AS reason
FROM bronze_order_items
WHERE order_id IS NULL
   OR try_cast(price AS DECIMAL(10,2)) IS NULL
   OR try_cast(price AS DECIMAL(10,2)) <= 0;



 
CREATE OR REPLACE TABLE silver_order_items AS
SELECT order_id,
       CAST(order_item_id AS INT)           AS item_seq,
       product_id,
       seller_id,
       CAST(price AS DECIMAL(10,2))         AS price,
       CAST(freight_value AS DECIMAL(10,2)) AS freight
FROM bronze_order_items
WHERE order_id IS NOT NULL
  AND try_cast(price AS DECIMAL(10,2)) > 0;


-- COMMAND ----------

SELECT COUNT(*) FROM quarantine_order_items

-- COMMAND ----------

