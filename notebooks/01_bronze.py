# Databricks notebook source
from pyspark.sql import functions as F

RAW = "/Volumes/data_engineering_classic/olist/raw/archive (2)"

files = {
    "customers":            "olist_customers_dataset.csv",
    "orders":               "olist_orders_dataset.csv",
    "order_items":          "olist_order_items_dataset.csv",
    "payments":             "olist_order_payments_dataset.csv",
    "reviews":              "olist_order_reviews_dataset.csv",
    "products":             "olist_products_dataset.csv",
    "sellers":              "olist_sellers_dataset.csv",
    "geolocation":          "olist_geolocation_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
}

for name, file in files.items():
    df = (spark.read
            .option("header", True)
            .option("multiLine", True)
            .option("escape", '"')
            .csv(f"{RAW}/{file}")
            .withColumn("ingested_at", F.current_timestamp())
            .withColumn("source_file", F.col("_metadata.file_path")))
    df.write.mode("overwrite").saveAsTable(f"data_engineering_classic.olist.bronze_{name}")
    print(f"bronze_{name}: {df.count():,} rows")

# COMMAND ----------

display(spark.sql("""
    SELECT review_score, COUNT(*) AS n
    FROM data_engineering_classic.olist.bronze_reviews
    GROUP BY review_score
    ORDER BY review_score
"""))