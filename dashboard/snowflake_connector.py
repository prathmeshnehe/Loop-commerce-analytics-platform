import snowflake.connector
import pandas as pd
import streamlit as st

def get_connection():
    return snowflake.connector.connect(
        account=st.secrets["snowflake"]["account"],
        user=st.secrets["snowflake"]["user"],
        password=st.secrets["snowflake"]["password"],
        warehouse=st.secrets["snowflake"]["warehouse"],
        database=st.secrets["snowflake"]["database"],
        schema=st.secrets["snowflake"]["schema"]
    )

@st.cache_data(ttl=3600)
def run_query(query):
    conn = get_connection()
    try:
        df = pd.read_sql(query, conn)
        df.columns = [col.lower() for col in df.columns]
        return df
    finally:
        conn.close()