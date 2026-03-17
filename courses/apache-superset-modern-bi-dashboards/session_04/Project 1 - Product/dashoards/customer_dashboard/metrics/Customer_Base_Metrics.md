# Customer Base Metrics

## Business Context
Customer base metrics track the size, growth, and overall health of your customer community. These fundamental metrics help you understand your acquisition rate, total customer count, and overall market penetration, providing essential context for evaluating business growth.

## Dashboard Charts

### Chart 1: Customer Count Overview

**Purpose**: Provides a snapshot of your current customer base, active customers, and recent acquisitions to track customer growth and engagement.

**SQL Query 1: Customer Base Summary**
```sql
WITH all_time_customers AS (
    SELECT COUNT(DISTINCT customer_id) AS total_customer_count
    FROM customers
),
recently_active AS (
    SELECT 
        COUNT(DISTINCT customer_id) AS active_30d_count,
        COUNT(DISTINCT CASE WHEN order_date >= CURRENT_DATE - INTERVAL '90 days' THEN customer_id ELSE NULL END) AS active_90d_count,
        COUNT(DISTINCT CASE WHEN order_date >= CURRENT_DATE - INTERVAL '365 days' THEN customer_id ELSE NULL END) AS active_365d_count
    FROM orders
    WHERE status != 'Cancelled'
),
new_customers AS (
    SELECT
        COUNT(DISTINCT customer_id) AS new_30d_count,
        COUNT(DISTINCT CASE WHEN first_order_date >= CURRENT_DATE - INTERVAL '90 days' THEN customer_id ELSE NULL END) AS new_90d_count,
        COUNT(DISTINCT CASE WHEN first_order_date >= CURRENT_DATE - INTERVAL '365 days' THEN customer_id ELSE NULL END) AS new_365d_count
    FROM (
        SELECT 
            customer_id,
            MIN(order_date) AS first_order_date
        FROM orders
        WHERE status != 'Cancelled'
        GROUP BY customer_id
    ) first_orders
    WHERE first_order_date >= CURRENT_DATE - INTERVAL '365 days'
)
SELECT
    atc.total_customer_count,
    ra.active_30d_count,
    ra.active_90d_count,
    ra.active_365d_count,
    nc.new_30d_count,
    nc.new_90d_count,
    nc.new_365d_count,
    ROUND(100.0 * ra.active_30d_count / NULLIF(atc.total_customer_count, 0), 1) AS active_30d_percentage,
    ROUND(100.0 * ra.active_90d_count / NULLIF(atc.total_customer_count, 0), 1) AS active_90d_percentage,
    ROUND(100.0 * ra.active_365d_count / NULLIF(atc.total_customer_count, 0), 1) AS active_365d_percentage,
    ROUND(100.0 * nc.new_365d_count / NULLIF(atc.total_customer_count, 0), 1) AS new_customers_annual_percentage
FROM
    all_time_customers atc,
    recently_active ra,
    new_customers nc;
```

**SQL Query 2: New Customer Acquisition Trend**
```sql
WITH customer_first_orders AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    WHERE status != 'Cancelled'
    GROUP BY customer_id
),
monthly_acquisition AS (
    SELECT
        DATE_TRUNC('month', first_order_date)::date AS month,
        COUNT(*) AS new_customers
    FROM
        customer_first_orders
    WHERE
        first_order_date >= CURRENT_DATE - INTERVAL '24 months'
    GROUP BY
        month
)
SELECT
    month,
    TO_CHAR(month, 'Month YYYY') AS month_name,
    new_customers,
    SUM(new_customers) OVER (ORDER BY month) AS cumulative_new_customers,
    LAG(new_customers, 1) OVER (ORDER BY month) AS previous_month,
    LAG(new_customers, 12) OVER (ORDER BY month) AS same_month_last_year,
    CASE
        WHEN LAG(new_customers, 1) OVER (ORDER BY month) IS NULL THEN NULL
        ELSE ROUND(100.0 * (new_customers - LAG(new_customers, 1) OVER (ORDER BY month)) / 
            NULLIF(LAG(new_customers, 1) OVER (ORDER BY month), 0), 1)
    END AS mom_growth_pct,
    CASE
        WHEN LAG(new_customers, 12) OVER (ORDER BY month) IS NULL THEN NULL
        ELSE ROUND(100.0 * (new_customers - LAG(new_customers, 12) OVER (ORDER BY month)) / 
            NULLIF(LAG(new_customers, 12) OVER (ORDER BY month), 0), 1)
    END AS yoy_growth_pct
FROM
    monthly_acquisition
ORDER BY
    month;
```

**SQL Query 3: Customer Acquisition by Channel**
```sql
-- This assumes you have a field tracking acquisition channel
-- If not available in your current schema, you might need to use alternative logic
-- such as first order sales channel

WITH first_order_channels AS (
    SELECT
        o.customer_id,
        o.sales_channel AS acquisition_channel,
        o.order_date AS acquisition_date,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS order_rank
    FROM
        orders o
    WHERE
        o.status != 'Cancelled'
),
customer_channels AS (
    SELECT
        acquisition_channel,
        acquisition_date
    FROM
        first_order_channels
    WHERE
        order_rank = 1  -- First order only
        AND acquisition_date >= CURRENT_DATE - INTERVAL '12 months'
),
monthly_channel_acquisition AS (
    SELECT
        DATE_TRUNC('month', acquisition_date)::date AS month,
        acquisition_channel,
        COUNT(*) AS new_customers
    FROM
        customer_channels
    GROUP BY
        month, acquisition_channel
)
SELECT
    month,
    TO_CHAR(month, 'Month YYYY') AS month_name,
    acquisition_channel,
    new_customers,
    ROUND(100.0 * new_customers / SUM(new_customers) OVER (PARTITION BY month), 1) AS pct_of_monthly_acquisition,
    LAG(new_customers, 1) OVER (PARTITION BY acquisition_channel ORDER BY month) AS previous_month,
    CASE
        WHEN LAG(new_customers, 1) OVER (PARTITION BY acquisition_channel ORDER BY month) IS NULL THEN NULL
        ELSE ROUND(100.0 * (new_customers - LAG(new_customers, 1) OVER (PARTITION BY acquisition_channel ORDER BY month)) / 
            NULLIF(LAG(new_customers, 1) OVER (PARTITION BY acquisition_channel ORDER BY month), 0), 1)
    END AS mom_growth_pct
FROM
    monthly_channel_acquisition
ORDER BY
    month DESC, new_customers DESC;
```

### Chart 2: Active Customers Analysis

**Purpose**: Tracks customer activity levels over time to understand engagement patterns and identify potential churn risks.

**SQL Query 1: Customer Activity Summary**
```sql
WITH monthly_active_customers AS (
    SELECT
        DATE_TRUNC('month', order_date)::date AS month,
        COUNT(DISTINCT customer_id) AS monthly_active_customers
    FROM
        orders
    WHERE
        status != 'Cancelled'
        AND order_date >= CURRENT_DATE - INTERVAL '13 months'
    GROUP BY
        month
),
rolling_active_customers AS (
    SELECT
        DATE_TRUNC('month', order_date)::date AS month,
        COUNT(DISTINCT customer_id) FILTER (WHERE order_date >= DATE_TRUNC('month', order_date) - INTERVAL '30 days') AS rolling_30d_active,
        COUNT(DISTINCT customer_id) FILTER (WHERE order_date >= DATE_TRUNC('month', order_date) - INTERVAL '90 days') AS rolling_90d_active,
        COUNT(DISTINCT customer_id) FILTER (WHERE order_date >= DATE_TRUNC('month', order_date) - INTERVAL '365 days') AS rolling_365d_active
    FROM
        orders
    WHERE
        status != 'Cancelled'
        AND order_date >= CURRENT_DATE - INTERVAL '13 months'
    GROUP BY
        month
)
SELECT
    mac.month,
    TO_CHAR(mac.month, 'Month YYYY') AS month_name,
    mac.monthly_active_customers,
    rac.rolling_30d_active,
    rac.rolling_90d_active,
    rac.rolling_365d_active,
    -- Month-over-month change for monthly active
    ROUND(100.0 * (mac.monthly_active_customers - LAG(mac.monthly_active_customers, 1) OVER (ORDER BY mac.month)) / 
        NULLIF(LAG(mac.monthly_active_customers, 1) OVER (ORDER BY mac.month), 0), 1) AS monthly_active_mom_change,
    -- Month-over-month change for 90-day active
    ROUND(100.0 * (rac.rolling_90d_active - LAG(rac.rolling_90d_active, 1) OVER (ORDER BY rac.month)) / 
        NULLIF(LAG(rac.rolling_90d_active, 1) OVER (ORDER BY rac.month), 0), 1) AS rolling_90d_mom_change
FROM
    monthly_active_customers mac
JOIN
    rolling_active_customers rac ON mac.month = rac.month
ORDER BY
    mac.month;
```

**SQL Query 2: Customer Activity Frequency**
```sql
WITH customer_order_counts AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date,
        CURRENT_DATE - MAX(order_date) AS days_since_last_order,
        COUNT(*) FILTER (WHERE order_date >= CURRENT_DATE - INTERVAL '90 days') AS orders_last_90_days,
        COUNT(*) FILTER (WHERE order_date >= CURRENT_DATE - INTERVAL '365 days') AS orders_last_365_days
    FROM
        orders
    WHERE
        status != 'Cancelled'
    GROUP BY
        customer_id
),
activity_segments AS (
    SELECT
        customer_id,
        CASE
            WHEN orders_last_90_days >= 3 THEN 'High Activity (3+ orders in 90 days)'
            WHEN orders_last_90_days >= 1 THEN 'Medium Activity (1-2 orders in 90 days)'
            WHEN orders_last_365_days >= 1 THEN 'Low Activity (Orders in last year)'
            WHEN days_since_last_order <= 730 THEN 'Inactive (1-2 years)'
            ELSE 'Dormant (2+ years)'
        END AS activity_segment
    FROM
        customer_order_counts
)
SELECT
    activity_segment,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage_of_customers
FROM
    activity_segments
GROUP BY
    activity_segment
ORDER BY
    CASE
        WHEN activity_segment = 'High Activity (3+ orders in 90 days)' THEN 1
        WHEN activity_segment = 'Medium Activity (1-2 orders in 90 days)' THEN 2
        WHEN activity_segment = 'Low Activity (Orders in last year)' THEN 3
        WHEN activity_segment = 'Inactive (1-2 years)' THEN 4
        ELSE 5
    END;
```

**SQL Query 3: Customer Recency Analysis**
```sql
WITH customer_last_orders AS (
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date,
        CURRENT_DATE - MAX(order_date) AS days_since_last_order
    FROM
        orders
    WHERE
        status != 'Cancelled'
    GROUP BY
        customer_id
),
recency_buckets AS (
    SELECT
        customer_id,
        last_order_date,
        days_since_last_order,
        CASE
            WHEN days_since_last_order < 30 THEN '0-30 days'
            WHEN days_since_last_order < 60 THEN '31-60 days'
            WHEN days_since_last_order < 90 THEN '61-90 days'
            WHEN days_since_last_order < 180 THEN '91-180 days'
            WHEN days_since_last_order < 365 THEN '181-365 days'
            WHEN days_since_last_order < 730 THEN '1-2 years'
            ELSE '2+ years'
        END AS recency_bucket
    FROM
        customer_last_orders
)
SELECT
    recency_bucket,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage_of_customers,
    ROUND(AVG(days_since_last_order)) AS average_days_since_order
FROM
    recency_buckets
GROUP BY
    recency_bucket
ORDER BY
    CASE
        WHEN recency_bucket = '0-30 days' THEN 1
        WHEN recency_bucket = '31-60 days' THEN 2
        WHEN recency_bucket = '61-90 days' THEN 3
        WHEN recency_bucket = '91-180 days' THEN 4
        WHEN recency_bucket = '181-365 days' THEN 5
        WHEN recency_bucket = '1-2 years' THEN 6
        ELSE 7
    END;
```

### Chart 3: Customer Geographic Distribution

**Purpose**: Analyzes where your customers are located to better understand regional market penetration, identify growth opportunities, and optimize marketing and fulfillment strategies.

**SQL Query 1: Customer Distribution by Country**
```sql
SELECT
    country,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage_of_total
FROM
    customers
GROUP BY
    country
ORDER BY
    customer_count DESC;
```

**SQL Query 2: Customer Distribution by State/Region**
```sql
WITH customer_states AS (
    SELECT
        country,
        state,
        COUNT(*) AS customer_count,
        ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY country), 1) AS percentage_of_country
    FROM
        customers
    GROUP BY
        country, state
)
SELECT
    country,
    state,
    customer_count,
    percentage_of_country,
    ROUND(100.0 * customer_count / (SELECT COUNT(*) FROM customers), 1) AS percentage_of_total
FROM
    customer_states
ORDER BY
    country, customer_count DESC;
```

**SQL Query 3: Active vs. Inactive Customers by Geography**
```sql
WITH active_customers AS (
    SELECT DISTINCT
        customer_id
    FROM
        orders
    WHERE
        status != 'Cancelled'
        AND order_date >= CURRENT_DATE - INTERVAL '90 days'
),
geographic_activity AS (
    SELECT
        c.country,
        COUNT(*) AS total_customers,
        COUNT(*) FILTER (WHERE ac.customer_id IS NOT NULL) AS active_customers,
        COUNT(*) FILTER (WHERE ac.customer_id IS NULL) AS inactive_customers
    FROM
        customers c
    LEFT JOIN
        active_customers ac ON c.customer_id = ac.customer_id
    GROUP BY
        c.country
)
SELECT
    country,
    total_customers,
    active_customers,
    inactive_customers,
    ROUND(100.0 * active_customers / NULLIF(total_customers, 0), 1) AS active_percentage
FROM
    geographic_activity
ORDER BY
    total_customers DESC;
```

## YouTube Script: Understanding Customer Base Metrics

Hey everyone! Today we're diving into Customer Base Metrics - the fundamental numbers that tell you how many customers you have, how quickly you're acquiring new ones, and how engaged they are with your business. These metrics are absolutely essential for understanding the health and growth trajectory of your customer community.

Let's start with our Customer Count Overview. The first query gives you a comprehensive snapshot of your customer base from multiple angles. It shows your total all-time customer count, how many customers have been active in the last 30, 90, and 365 days, and how many new customers you've acquired in those same periods.

What makes this query particularly valuable is that it doesn't just show absolute numbers but also calculates important ratios like what percentage of your total customer base is active. This helps you understand whether you're effectively retaining customers or just acquiring new ones who don't stick around.

The second query tracks your new customer acquisition trend over time. It shows month-by-month customer acquisition with both month-over-month and year-over-year growth rates. This historical view helps you identify seasonal patterns, measure the impact of marketing campaigns, and spot long-term trends in your acquisition rate. The cumulative new customer count is especially useful for visualizing your growth trajectory over time.

The third query analyzes customer acquisition by channel. This perspective helps you understand which marketing channels or touchpoints are most effective at bringing in new customers. For example, you might discover that social media brings in the most customers but referrals bring in the highest-value customers. This insight helps you allocate your marketing budget more effectively.

Moving to our Active Customers Analysis, the first query provides a monthly summary of customer activity levels. It tracks not just how many customers placed orders each month but also rolling 30-day, 90-day, and 365-day active customer counts. These rolling metrics smooth out seasonal fluctuations and provide a more stable view of your active customer base over time.

The second query segments your customers by activity frequency. This helps you understand the distribution of engagement across your customer base - how many customers are highly active versus occasional shoppers versus those who haven't purchased in years. This segmentation is crucial for targeted marketing and retention strategies.

The third query focuses specifically on recency - how long it's been since each customer's last purchase. This is one of the most powerful predictors of future buying behavior. Customers who purchased recently are much more likely to buy again compared to those who haven't purchased in years. This recency analysis helps you identify at-risk customers before they become completely inactive.

Our final chart examines Customer Geographic Distribution. The first query shows your customer distribution by country, giving you a high-level view of which markets you're penetrating most effectively. This helps inform international expansion strategies and localization efforts.

The second query dives deeper into state or regional distribution within countries. This more granular geographic analysis can reveal unexpected regional strengths or opportunities for targeted marketing in underserved areas.

The third query compares active versus inactive customer rates across different geographies. This can uncover fascinating insights - perhaps you have high customer retention in certain regions and poor retention in others. These differences might indicate varying levels of market fit, competition, or service quality across regions.

What makes these customer base metrics so valuable is their fundamental nature. While more complex analyses can provide deeper insights, these basic counts and trends are essential for understanding your business's growth trajectory and overall health. They answer the most basic questions any business should be asking: How many customers do we have? Are we gaining or losing customers? And how engaged are they?

These metrics also serve as the foundation for more advanced analyses like customer lifetime value, churn prediction, and segmentation. Without accurate tracking of your customer base, these more sophisticated analyses aren't possible.

Remember that these metrics are most powerful when viewed together and tracked consistently over time. The relationships between total customers, active customers, and new acquisitions reveal the true dynamics of your customer base and help guide strategic priorities.

In our next video, we'll explore Customer Value KPIs, which help you understand not just how many customers you have, but how much revenue and profit they're generating. See you then!
