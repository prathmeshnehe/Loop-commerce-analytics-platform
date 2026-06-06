import os
import pandas as pd
import numpy as np
import snowflake.connector
from dotenv import load_dotenv
from faker import Faker
import random
from datetime import datetime, timedelta

# ─────────────────────────────────────────
# WHAT THIS FILE DOES:
# 1. Reads your Snowflake credentials from .env
# 2. Reads all Olist CSV files from data/raw/
# 3. Generates a fake ad_spend table
# 4. Loads everything into Snowflake RAW schema
# ─────────────────────────────────────────

load_dotenv()
# WHY: Reads your .env file so we can use
# credentials without hardcoding them

fake = Faker()

# ─────────────────────────────────────────
# STEP 1: CONNECT TO SNOWFLAKE
# ─────────────────────────────────────────
def get_connection():
    return snowflake.connector.connect(
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
        database=os.getenv("SNOWFLAKE_DATABASE"),
        schema=os.getenv("SNOWFLAKE_SCHEMA")
    )
# WHY: os.getenv() reads values from your .env file
# We never hardcode passwords directly in code

# ─────────────────────────────────────────
# STEP 2: GENERATE FAKE AD SPEND DATA
# ─────────────────────────────────────────
def generate_ad_spend(days=365):
    channels = ['paid_social', 'organic', 'referral', 'tiktok', 'email']
    markets = ['US', 'EU', 'UK', 'APAC']
    records = []

    start_date = datetime(2022, 1, 1)

    for day in range(days):
        current_date = start_date + timedelta(days=day)
        for channel in channels:
            for market in markets:
                records.append({
                    'date': current_date.strftime('%Y-%m-%d'),
                    'channel': channel,
                    'market': market,
                    'spend_amount': round(random.uniform(100, 5000), 2),
                    'impressions': random.randint(1000, 100000),
                    'clicks': random.randint(50, 5000)
                })

    return pd.DataFrame(records)
# WHY: Loop's real challenge is knowing which
# channel drives profitable customers.
# We simulate this data since Olist doesn't have it.

# ─────────────────────────────────────────
# STEP 3: LOAD A DATAFRAME INTO SNOWFLAKE
# ─────────────────────────────────────────
def load_dataframe(conn, df, table_name):
    # Use Snowflake's write_pandas helper for robust bulk upload
    # write_pandas handles NULLs, type conversion and batching
    from snowflake.connector.pandas_tools import write_pandas

    # Normalize column names to uppercase to match Snowflake conventions
    df.columns = [col.upper() for col in df.columns]

    # Ensure pandas NaN are preserved (write_pandas will map them to NULL)
    # but coerce problematic numpy NaNs to pandas NA
    df = df.replace({np.nan: pd.NA})

    # Drop existing table so schema inferred by write_pandas is clean
    cur = conn.cursor()
    cur.execute(f"DROP TABLE IF EXISTS {table_name}")
    cur.close()

    success, nchunks, nrows, _ = write_pandas(
        conn,
        df,
        table_name,
        auto_create_table=True,
        overwrite=False,
    )

    if not success:
        raise RuntimeError(f"write_pandas failed for {table_name}")

    print(f"✅ Loaded {nrows} rows into {table_name}")

# ─────────────────────────────────────────
# STEP 4: MAP CSV FILES TO TABLE NAMES
# ─────────────────────────────────────────
CSV_TABLE_MAP = {
    "data/raw/olist_customers_dataset.csv": "RAW_CUSTOMERS",
    "data/raw/olist_orders_dataset.csv": "RAW_ORDERS",
    "data/raw/olist_order_items_dataset.csv": "RAW_ORDER_ITEMS",
    "data/raw/olist_order_payments_dataset.csv": "RAW_ORDER_PAYMENTS",
    "data/raw/olist_order_reviews_dataset.csv": "RAW_ORDER_REVIEWS",
    "data/raw/olist_products_dataset.csv": "RAW_PRODUCTS",
    "data/raw/olist_sellers_dataset.csv": "RAW_SELLERS",
    "data/raw/olist_geolocation_dataset.csv": "RAW_GEOLOCATION",
}
# WHY: This dictionary maps each CSV file path to the
# Snowflake table name it should be loaded into.
# Keeping this separate from the logic makes it
# easy to add new files later

# ─────────────────────────────────────────
# STEP 5: MAIN — RUN EVERYTHING
# ─────────────────────────────────────────
def main():
    print("Connecting to Snowflake...")
    conn = get_connection()
    print("✅ Connected!")

    # Load all Olist CSV files
    for csv_path, table_name in CSV_TABLE_MAP.items():
        print(f"Loading {csv_path} → {table_name}")
        df = pd.read_csv(csv_path)
        load_dataframe(conn, df, table_name)

    # Generate and load fake ad spend
    print("Generating ad spend data...")
    ad_spend_df = generate_ad_spend(days=365)
    load_dataframe(conn, ad_spend_df, "RAW_AD_SPEND")

    conn.close()
    print("\n🎉 All data loaded into Snowflake successfully!")

if __name__ == "__main__":
    main()