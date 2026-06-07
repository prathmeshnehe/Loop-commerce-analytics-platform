import streamlit as st
import plotly.express as px
import plotly.graph_objects as go
from snowflake_connector import run_query

# ─────────────────────────────────────────
# PAGE CONFIGURATION
# ─────────────────────────────────────────
st.set_page_config(
    page_title="Loop Analytics Dashboard",
    page_icon="🎧",
    layout="wide"
)
# WHY layout=wide: Uses the full browser width
# so charts have more space to breathe

# ─────────────────────────────────────────
# HEADER
# ─────────────────────────────────────────
st.title("🎧 Loop Commerce Analytics Platform")
st.markdown("**Retention & Ad Spend Intelligence Dashboard**")
st.markdown("---")
# WHY markdown: st.markdown lets you write
# formatted text using simple markdown syntax

# ─────────────────────────────────────────
# SIDEBAR NAVIGATION
# ─────────────────────────────────────────
page = st.sidebar.selectbox(
    "Navigate to",
    ["Retention Overview",
     "Cohort Analysis",
     "Channel Performance",
     "Market Performance"]
)
# WHY sidebar: Keeps navigation out of the
# main content area. Standard dashboard UX pattern.

st.sidebar.markdown("---")
st.sidebar.markdown("**Data refreshed from Snowflake**")

# ─────────────────────────────────────────
# PAGE 1 — RETENTION OVERVIEW
# ─────────────────────────────────────────
if page == "Retention Overview":
    st.header("Customer Retention Overview")
    st.markdown(
        "What percentage of customers come back "
        "to buy again? Loop's core business problem."
    )

    # Load data from Snowflake mart
    df = run_query("""
        SELECT
            state,
            total_customers,
            repeat_customers,
            repeat_rate_pct,
            avg_lifetime_value
        FROM LOOP_DB.MARTS.MART_REPEAT_PURCHASE_RATE
        ORDER BY repeat_rate_pct DESC
    """)

    # KPI Cards at the top
    col1, col2, col3 = st.columns(3)
    # WHY columns: Streamlit's column layout puts
    # multiple elements side by side like a grid

    with col1:
        total = df['total_customers'].sum()
        st.metric("Total Customers", f"{total:,}")
        # WHY :, format: Adds comma separators
        # so 99000 shows as 99,000

    with col2:
        repeat = df['repeat_customers'].sum()
        st.metric("Repeat Customers", f"{repeat:,}")

    with col3:
        avg_rate = df['repeat_rate_pct'].mean().round(2)
        st.metric("Avg Repeat Rate", f"{avg_rate}%")

    st.markdown("---")

    # Bar chart — repeat rate by state
    fig = px.bar(
        df,
        x='state',
        y='repeat_rate_pct',
        color='repeat_rate_pct',
        color_continuous_scale='Blues',
        title='Repeat Purchase Rate by State',
        labels={
            'state': 'State',
            'repeat_rate_pct': 'Repeat Rate %'
        }
    )
    st.plotly_chart(fig, use_container_width=True)
    # WHY use_container_width=True: Makes the chart
    # fill the full width of the page automatically

    st.markdown("---")

    # Raw data table toggle
    if st.checkbox("Show raw data"):
        st.dataframe(df)
    # WHY checkbox: Lets users toggle raw data
    # visibility without cluttering the dashboard

# ─────────────────────────────────────────
# PAGE 2 — COHORT ANALYSIS
# ─────────────────────────────────────────
elif page == "Cohort Analysis":
    st.header("Cohort Retention Analysis")
    st.markdown(
        "Of customers who first bought in month X, "
        "how many came back in subsequent months?"
    )

    df = run_query("""
        SELECT
            TO_CHAR(cohort_month, 'YYYY-MM') AS cohort_month,
            months_since_first_purchase,
            active_customers
        FROM LOOP_DB.MARTS.MART_COHORT_RETENTION
        WHERE months_since_first_purchase <= 6
        ORDER BY cohort_month, months_since_first_purchase
    """)

    # Pivot for heatmap
    pivot = df.pivot_table(
        index='cohort_month',
        columns='months_since_first_purchase',
        values='active_customers',
        fill_value=0
    )
    # WHY pivot: A heatmap needs data in a matrix
    # format — rows are cohorts, columns are months

    fig = go.Figure(data=go.Heatmap(
        z=pivot.values,
        x=[f"Month {i}" for i in pivot.columns],
        y=pivot.index,
        colorscale='Blues',
        text=pivot.values,
        texttemplate="%{text}",
    ))
    fig.update_layout(
        title='Cohort Retention Heatmap',
        xaxis_title='Months Since First Purchase',
        yaxis_title='Cohort Month'
    )
    st.plotly_chart(fig, use_container_width=True)

# ─────────────────────────────────────────
# PAGE 3 — CHANNEL PERFORMANCE
# ─────────────────────────────────────────
elif page == "Channel Performance":
    st.header("Ad Channel Performance")
    st.markdown(
        "Which acquisition channel drives "
        "the highest return on ad spend?"
    )

    df = run_query("""
        SELECT
            channel,
            market,
            total_spend,
            total_revenue,
            overall_roas,
            cost_per_order
        FROM LOOP_DB.MARTS.MART_CHANNEL_LTV
        ORDER BY overall_roas DESC
    """)

    col1, col2 = st.columns(2)

    with col1:
        fig = px.bar(
            df.groupby('channel')['overall_roas']
              .mean()
              .reset_index(),
            x='channel',
            y='overall_roas',
            color='overall_roas',
            color_continuous_scale='Greens',
            title='Average ROAS by Channel',
            labels={
                'channel': 'Channel',
                'overall_roas': 'ROAS'
            }
        )
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        fig = px.bar(
            df.groupby('channel')['cost_per_order']
              .mean()
              .reset_index(),
            x='channel',
            y='cost_per_order',
            color='cost_per_order',
            color_continuous_scale='Reds',
            title='Average Cost Per Order by Channel',
            labels={
                'channel': 'Channel',
                'cost_per_order': 'Cost Per Order ($)'
            }
        )
        st.plotly_chart(fig, use_container_width=True)

    st.markdown("---")

    # Market filter
    markets = df['market'].unique().tolist()
    selected_market = st.selectbox("Filter by Market", 
                                    ["All"] + markets)
    # WHY selectbox: Lets users filter data
    # interactively without rewriting any code

    if selected_market != "All":
        df = df[df['market'] == selected_market]

    st.dataframe(df)

# ─────────────────────────────────────────
# PAGE 4 — MARKET PERFORMANCE
# ─────────────────────────────────────────
elif page == "Market Performance":
    st.header("Market Performance")
    st.markdown(
        "Which markets are growing fastest "
        "by revenue and order volume?"
    )

    df = run_query("""
        SELECT
            market,
            month,
            total_orders,
            unique_customers,
            total_revenue,
            avg_order_value
        FROM LOOP_DB.MARTS.MART_MARKET_PERFORMANCE
        ORDER BY month, total_revenue DESC
    """)

    df['month'] = df['month'].astype(str)

    # Top markets by total revenue
    top_markets = (
        df.groupby('market')['total_revenue']
          .sum()
          .nlargest(10)
          .index
          .tolist()
    )
    df_top = df[df['market'].isin(top_markets)]

    fig = px.line(
        df_top,
        x='month',
        y='total_revenue',
        color='market',
        title='Monthly Revenue by Top 10 Markets',
        labels={
            'month': 'Month',
            'total_revenue': 'Revenue ($)',
            'market': 'Market'
        }
    )
    st.plotly_chart(fig, use_container_width=True)

    col1, col2 = st.columns(2)

    with col1:
        fig = px.bar(
            df.groupby('market')['total_orders']
              .sum()
              .nlargest(10)
              .reset_index(),
            x='market',
            y='total_orders',
            title='Top 10 Markets by Total Orders',
            color='total_orders',
            color_continuous_scale='Blues'
        )
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        fig = px.bar(
            df.groupby('market')['avg_order_value']
              .mean()
              .nlargest(10)
              .reset_index(),
            x='market',
            y='avg_order_value',
            title='Top 10 Markets by Avg Order Value',
            color='avg_order_value',
            color_continuous_scale='Greens'
        )
        st.plotly_chart(fig, use_container_width=True)