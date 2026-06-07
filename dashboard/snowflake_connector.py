import snowflake.connector
import pandas as pd
import os
from dotenv import load_dotenv

load_dotenv()
# WHY: Reads your .env file so we never
# hardcode passwords in code

def get_connection():
    """Creates and returns a Snowflake connection"""
    return snowflake.connector.connect(
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        warehouse="LOOP_WH",
        database="LOOP_DB",
        schema="MARTS"
    )
    # WHY schema=MARTS: Our dashboard only reads
    # from mart models — the final business-ready
    # tables. It never touches raw data directly.

def run_query(query):
    """
    Runs a SQL query and returns a pandas DataFrame
    
    WHY return DataFrame: Streamlit and Plotly work
    natively with pandas DataFrames. Every chart
    we build expects a DataFrame as input.
    """
    conn = get_connection()
    try:
        df = pd.read_sql(query, conn)
        df.columns = [col.lower() for col in df.columns]
        # WHY lowercase: Snowflake returns column names
        # in uppercase. We lowercase them so our code
        # reads naturally: df['market'] not df['MARKET']
        return df
    finally:
        conn.close()
        # WHY finally: Ensures connection always closes
        # even if the query crashes. Prevents connection
        # leaks that waste Snowflake credits.