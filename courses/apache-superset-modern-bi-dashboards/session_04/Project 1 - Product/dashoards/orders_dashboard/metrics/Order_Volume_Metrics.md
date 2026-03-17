# Order Volume Metrics

## Business Context
Order volume metrics track the quantity of orders your business receives across different time periods. These metrics help you understand sales momentum, identify unusual patterns, and plan operational resources appropriately to meet demand.

## Dashboard Charts

### Chart 1: Daily Order Count

**Purpose**: Monitors daily order volume to provide immediate visibility into sales activity and highlight day-to-day fluctuations.

**SQL Query 1: Today's Orders vs. Yesterday**
```sql
WITH today_orders AS (
    SELECT
        COUNT(*) AS order_count,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled'
        AND order_date::date = CURRENT_DATE
),
yesterday_orders AS (
    SELECT
        COUNT(*) AS order_count,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled'
        AND order_date::date = CURRENT_DATE - INTERVAL '1 day'
)
SELECT
    to_orders.order_count AS today_order_count,
    ye_orders.order_count AS yesterday_order_count,
    CASE
        WHEN ye_orders.order_count = 0 THEN NULL
        ELSE ROUND(100.0 * (to_orders.order_count - ye_orders.order_count) / ye_orders.order_count, 1)
    END AS order_count_change_pct,
    to_orders.units_sold AS today_units_sold,
    ye_orders.units_sold AS yesterday_units_sold,
    ROUND(to_orders.total_revenue::numeric, 2) AS today_revenue,
    ROUND(ye_orders.total_revenue::numeric, 2) AS yesterday_revenue
FROM
    today_orders to_orders,
    yesterday_orders ye_orders;
```

**SQL Query 2: Hourly Order Distribution Today**
```sql
SELECT
    EXTRACT(HOUR FROM order_date) AS hour_of_day,
    COUNT(*) AS order_count,
    SUM(quantity) AS units_sold,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue
FROM
    orders
WHERE
    status != 'Cancelled'
    AND order_date::date = CURRENT_DATE
GROUP BY
    hour_of_day
ORDER BY
    hour_of_day;
```

**SQL Query 3: Daily Orders - Last 7 Days**
```sql
SELECT
    order_date::date AS order_day,
    COUNT(*) AS order_count,
    SUM(quantity) AS units_sold,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(AVG(total_amount)::numeric, 2) AS average_order_value
FROM
    orders
WHERE
    status != 'Cancelled'
    AND order_date >= CURRENT_DATE - INTERVAL '7 days'
    AND order_date < CURRENT_DATE + INTERVAL '1 day'
GROUP BY
    order_day
ORDER BY
    order_day;
```

### Chart 2: Weekly Order Trends

**Purpose**: Analyzes weekly order patterns to identify medium-term trends and cyclical patterns that might be less visible in daily data.

**SQL Query 1: Current Week vs. Previous Week**
```sql
WITH current_week AS (
    SELECT
        COUNT(*) AS order_count,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled'
        AND order_date >= DATE_TRUNC('week', CURRENT_DATE)
        AND order_date < DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 week'
),
previous_week AS (
    SELECT
        COUNT(*) AS order_count,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled'
        AND order_date >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week'
        AND order_date < DATE_TRUNC('week', CURRENT_DATE)
),
same_week_last_year AS (
    SELECT
        COUNT(*) AS order_count,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled'
        AND order_date >= DATE_TRUNC('week', CURRENT_DATE - INTERVAL '1 year')
        AND order_date < DATE_TRUNC('week', CURRENT_DATE - INTERVAL '1 year') + INTERVAL '1 week'
)
SELECT
    cw.order_count AS current_week_order_count,
    pw.order_count AS previous_week_order_count,
    CASE
        WHEN pw.order_count = 0 THEN NULL
        ELSE ROUND(100.0 * (cw.order_count - pw.order_count) / pw.order_count, 1)
    END AS wow_order_count_change_pct,
    swly.order_count AS same_week_last_year_order_count,
    CASE
        WHEN swly.order_count = 0 THEN NULL
        ELSE ROUND(100.0 * (cw.order_count - swly.order_count) / swly.order_count, 1)
    END AS yoy_order_count_change_pct,
    ROUND(cw.total_revenue::numeric, 2) AS current_week_revenue,
    ROUND(pw.total_revenue::numeric, 2) AS previous_week_revenue,
    CASE
        WHEN pw.total_revenue = 0 THEN NULL
        ELSE ROUND(100.0 * (cw.total_revenue - pw.total_revenue) / pw.total_revenue, 1)
    END AS wow_revenue_change_pct
FROM
    current_week cw,
    previous_week pw,
    same_week_last_year swly;
```

**SQL Query 2: Weekly Orders - Last 10 Weeks**
```sql
SELECT
    DATE_TRUNC('week', order_date)::date AS week_start_date,
    COUNT(*) AS order_count,
    SUM(quantity) AS units_sold,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(AVG(total_amount)::numeric, 2) AS average_order_value,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM
    orders
WHERE
    status != 'Cancelled'
    AND order_date >= CURRENT_DATE - INTERVAL '10 weeks'
GROUP BY
    week_start_date
ORDER BY
    week_start_date;
```

**SQL Query 3: Day of Week Distribution**
```sql
SELECT
    TO_CHAR(order_date, 'Day') AS day_name,
    EXTRACT(DOW FROM order_date) AS day_number,  -- 0 = Sunday, 6 = Saturday
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage_of_orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(AVG(total_amount)::numeric, 2) AS average_order_value
FROM
    orders
WHERE
    status != 'Cancelled'
    AND order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY
    day_name, day_number
ORDER BY
    day_number;
```

### Chart 3: Monthly Order Volume

**Purpose**: Provides a longer-term view of order trends to help identify seasonal patterns and year-over-year growth.

**SQL Query 1: Monthly Orders - Last 12 Months**
```sql
SELECT
    DATE_TRUNC('month', order_date)::date AS month_start_date,
    TO_CHAR(DATE_TRUNC('month', order_date), 'Month YYYY') AS month_name,
    COUNT(*) AS order_count,
    SUM(quantity) AS units_sold,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(AVG(total_amount)::numeric, 2) AS average_order_value,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM
    orders
WHERE
    status != 'Cancelled'
    AND order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY
    month_start_date, month_name
ORDER BY
    month_start_date;
```

**SQL Query 2: Year-over-Year Monthly Comparison**
```sql
WITH current_year_data AS (
    SELECT
        EXTRACT(MONTH FROM order_date) AS month_number,
        TO_CHAR(DATE_TRUNC('month', order_date), 'Month') AS month_name,
        COUNT(*) AS order_count,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled'
        AND order_date >= DATE_TRUNC('year', CURRENT_DATE)
        AND order_date < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year'
    GROUP BY
        month_number, month_name
),
previous_year_data AS (
    SELECT
        EXTRACT(MONTH FROM order_date) AS month_number,
        COUNT(*) AS order_count,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled'
        AND order_date >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
        AND order_date < DATE_TRUNC('year', CURRENT_DATE)
    GROUP BY
        month_number
)
SELECT
    cyd.month_number,
    cyd.month_name,
    cyd.order_count AS current_year_order_count,
    pyd.order_count AS previous_year_order_count,
    CASE
        WHEN pyd.order_count = 0 THEN NULL
        ELSE ROUND(100.0 * (cyd.order_count - pyd.order_count) / pyd.order_count, 1)
    END AS yoy_order_count_change_pct,
    ROUND(cyd.total_revenue::numeric, 2) AS current_year_revenue,
    ROUND(pyd.total_revenue::numeric, 2) AS previous_year_revenue,
    CASE
        WHEN pyd.total_revenue = 0 THEN NULL
        ELSE ROUND(100.0 * (cyd.total_revenue - pyd.total_revenue) / pyd.total_revenue, 1)
    END AS yoy_revenue_change_pct
FROM
    current_year_data cyd
LEFT JOIN
    previous_year_data pyd ON cyd.month_number = pyd.month_number
ORDER BY
    cyd.month_number;
```

**SQL Query 3: Order Growth Trendline**
```sql
WITH monthly_orders AS (
    SELECT
        DATE_TRUNC('month', order_date)::date AS month_start_date,
        COUNT(*) AS order_count,
        ROW_NUMBER() OVER (ORDER BY DATE_TRUNC('month', order_date)) AS month_number
    FROM
        orders
    WHERE
        status != 'Cancelled'
        AND order_date >= CURRENT_DATE - INTERVAL '24 months'
    GROUP BY
        month_start_date
)
SELECT
    month_start_date,
    order_count,
    -- Simple linear regression for trendline
    ROUND(
        REGR_SLOPE(order_count, month_number) OVER () * month_number +
        REGR_INTERCEPT(order_count, month_number) OVER ()
    ) AS trend_value,
    -- 3-month moving average
    ROUND(AVG(order_count) OVER (
        ORDER BY month_start_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    )) AS three_month_moving_avg,
    -- Month-over-month growth
    CASE
        WHEN LAG(order_count) OVER (ORDER BY month_start_date) = 0 THEN NULL
        ELSE ROUND(100.0 * (order_count - LAG(order_count) OVER (ORDER BY month_start_date)) /
            LAG(order_count) OVER (ORDER BY month_start_date), 1)
    END AS mom_growth_pct
FROM
    monthly_orders
ORDER BY
    month_start_date;
```

## YouTube Script: Understanding Order Volume Metrics

Hey everyone! Today we're looking at Order Volume Metrics - the fundamental numbers that tell you how many orders your business is processing. These metrics might seem simple, but they're absolutely critical for understanding sales momentum, planning operations, and identifying both opportunities and problems.

Let's start with our Daily Order Count metrics. The first query gives you a direct comparison between today's orders and yesterday's. This immediate perspective lets you quickly identify if you're having an unusually strong or weak day. What makes this query particularly useful is that it doesn't just show the raw numbers but calculates the percentage change, giving you context for how significant any difference might be.

The second query breaks down today's orders by hour. This hourly distribution is incredibly valuable for operational planning - knowing when your peak ordering hours occur helps you staff customer service appropriately, prepare fulfillment teams, and even time your marketing activities for maximum impact.

The third query provides a rolling 7-day view, allowing you to spot any day-of-week patterns or recent trends. This weekly perspective helps smooth out the noise that can sometimes make daily data misleading - for instance, a slow Tuesday might be concerning until you realize that Tuesdays are typically your slowest day.

Moving to our Weekly Order Trends, the first query compares your current week with both the previous week and the same week last year. This dual comparison is powerful because it gives you both immediate momentum (week-over-week) and long-term growth perspective (year-over-year) in a single view.

The second query in this section shows your order volumes for the last 10 weeks, creating a medium-term trend line that can reveal patterns that might be less obvious in daily data. This is particularly useful for identifying the impact of seasonal factors, marketing campaigns, or gradual shifts in customer behavior.

The third query examines your order distribution by day of the week. Understanding these cyclical patterns is crucial for inventory planning, staffing, and marketing. For example, if you consistently see lower order volumes on weekends, that might be an opportunity for weekend-specific promotions.

Our third chart focuses on Monthly Order Volume, providing the longest-term perspective. The first query shows your monthly orders for the past year, giving you that crucial annual cycle view. Retail businesses often follow strong seasonal patterns, and this query helps you identify and prepare for those predictable fluctuations.

The second query offers a direct year-over-year comparison for each month. This is one of the most valuable perspectives for evaluating true business growth, as it automatically accounts for seasonal patterns. A 15% increase from November to December might be normal holiday seasonality, but a 15% increase compared to last December represents real growth.

The final query calculates an order growth trendline, combining linear regression with moving averages to smooth out volatility while still highlighting meaningful trends. This mathematical approach helps distinguish between random fluctuations and genuine growth or decline patterns.

What makes these order volume metrics so valuable is their simplicity and universality. Unlike more complex analyses, order counts are straightforward and comparable across different business models and industries. Whether you sell high-value services or low-cost consumer goods, an order is an order - a clear sign of customer activity and business health.

These metrics also serve as early warning indicators. A sudden drop in daily orders might signal a website issue, while a gradual decline in the monthly trendline might indicate increasing competition or market saturation that requires strategic attention.

Remember that these metrics are most powerful when viewed together and tracked consistently over time. The combination of daily, weekly, and monthly perspectives gives you both the immediate operational insight and the long-term strategic context needed for informed decision-making.

In our next video, we'll explore Sales Performance KPIs, which build on these order volume metrics to examine the value and composition of your orders. See you then!
