# Order Trends & Patterns

## Business Context
Understanding the underlying patterns in your order data helps identify seasonal trends, customer purchase behaviors, and potential growth opportunities. This analysis goes beyond simple counts to reveal deeper insights into when, how, and why customers make purchases.

## Dashboard Charts

### Chart 1: Multi-Period Order Analysis

**Purpose**: Analyzes order trends across different time frames (daily, weekly, monthly, yearly) to identify both cyclical patterns and long-term growth trajectories.

**SQL Query 1: Daily Order Pattern Analysis**
```sql
WITH daily_orders AS (
    SELECT
        order_date::date AS day,
        EXTRACT(DOW FROM order_date) AS day_of_week,  -- 0 = Sunday, 6 = Saturday
        EXTRACT(DAY FROM order_date) AS day_of_month,
        COUNT(*) AS order_count,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY
        day, day_of_week, day_of_month
)
SELECT
    day,
    TO_CHAR(day, 'Day') AS day_name,
    day_of_week,
    day_of_month,
    order_count,
    units_sold,
    ROUND(total_revenue::numeric, 2) AS total_revenue,
    
    -- 7-day moving average
    ROUND(AVG(order_count) OVER (
        ORDER BY day
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )::numeric, 1) AS order_count_7day_ma,
    
    -- 7-day moving average for revenue
    ROUND(AVG(total_revenue) OVER (
        ORDER BY day
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )::numeric, 2) AS revenue_7day_ma,
    
    -- Day-over-day change
    ROUND(100.0 * (order_count - LAG(order_count, 1) OVER (ORDER BY day)) / 
           NULLIF(LAG(order_count, 1) OVER (ORDER BY day), 0), 1) AS order_count_dod_change,
    
    -- Week-over-week change (compare to same day last week)
    ROUND(100.0 * (order_count - LAG(order_count, 7) OVER (ORDER BY day)) / 
           NULLIF(LAG(order_count, 7) OVER (ORDER BY day), 0), 1) AS order_count_wow_change
FROM
    daily_orders
ORDER BY
    day DESC;
```

**SQL Query 2: Weekly Seasonality and Growth Analysis**
```sql
WITH weekly_orders AS (
    SELECT
        DATE_TRUNC('week', order_date)::date AS week_start,
        EXTRACT(WEEK FROM order_date) AS week_number,
        EXTRACT(YEAR FROM order_date) AS year,
        COUNT(*) AS order_count,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY
        week_start, week_number, year
),
week_comparison AS (
    SELECT
        w1.week_number,
        w1.year AS current_year,
        w1.week_start AS current_week_start,
        w1.order_count AS current_year_orders,
        w1.total_revenue AS current_year_revenue,
        w2.year AS previous_year,
        w2.week_start AS previous_week_start,
        w2.order_count AS previous_year_orders,
        w2.total_revenue AS previous_year_revenue
    FROM
        weekly_orders w1
    LEFT JOIN
        weekly_orders w2 ON w1.week_number = w2.week_number AND w1.year = w2.year + 1
    WHERE
        w1.week_start >= DATE_TRUNC('year', CURRENT_DATE)
)
SELECT
    week_number,
    TO_CHAR(current_week_start, 'Mon DD, YYYY') AS current_week,
    current_year_orders,
    ROUND(current_year_revenue::numeric, 2) AS current_year_revenue,
    TO_CHAR(previous_week_start, 'Mon DD, YYYY') AS previous_year_week,
    previous_year_orders,
    ROUND(previous_year_revenue::numeric, 2) AS previous_year_revenue,
    ROUND(100.0 * (current_year_orders - previous_year_orders) / 
           NULLIF(previous_year_orders, 0), 1) AS yoy_order_growth,
    ROUND(100.0 * (current_year_revenue - previous_year_revenue) / 
           NULLIF(previous_year_revenue, 0), 1) AS yoy_revenue_growth
FROM
    week_comparison
ORDER BY
    current_week_start;
```

**SQL Query 3: Monthly Trend and Seasonality Analysis**
```sql
WITH monthly_orders AS (
    SELECT
        DATE_TRUNC('month', order_date)::date AS month_start,
        EXTRACT(MONTH FROM order_date) AS month_number,
        EXTRACT(YEAR FROM order_date) AS year,
        COUNT(*) AS order_count,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= CURRENT_DATE - INTERVAL '3 years'
    GROUP BY
        month_start, month_number, year
),
monthly_metrics AS (
    SELECT
        month_start,
        month_number,
        year,
        order_count,
        units_sold,
        total_revenue,
        unique_customers,
        total_revenue / NULLIF(order_count, 0) AS average_order_value,
        order_count / NULLIF(unique_customers, 0) AS orders_per_customer,
        -- Month-over-month growth
        LAG(order_count, 1) OVER (ORDER BY month_start) AS prev_month_orders,
        LAG(total_revenue, 1) OVER (ORDER BY month_start) AS prev_month_revenue,
        -- Year-over-year comparison (same month last year)
        LAG(order_count, 12) OVER (ORDER BY month_start) AS prev_year_orders,
        LAG(total_revenue, 12) OVER (ORDER BY month_start) AS prev_year_revenue
    FROM
        monthly_orders
)
SELECT
    month_start,
    TO_CHAR(month_start, 'Month YYYY') AS month_year,
    order_count,
    units_sold,
    ROUND(total_revenue::numeric, 2) AS total_revenue,
    unique_customers,
    ROUND(average_order_value::numeric, 2) AS average_order_value,
    ROUND(orders_per_customer::numeric, 2) AS orders_per_customer,
    
    -- Month-over-month growth
    ROUND(100.0 * (order_count - prev_month_orders) / NULLIF(prev_month_orders, 0), 1) AS mom_order_growth,
    ROUND(100.0 * (total_revenue - prev_month_revenue) / NULLIF(prev_month_revenue, 0), 1) AS mom_revenue_growth,
    
    -- Year-over-year growth
    ROUND(100.0 * (order_count - prev_year_orders) / NULLIF(prev_year_orders, 0), 1) AS yoy_order_growth,
    ROUND(100.0 * (total_revenue - prev_year_revenue) / NULLIF(prev_year_revenue, 0), 1) AS yoy_revenue_growth
FROM
    monthly_metrics
WHERE
    month_start >= CURRENT_DATE - INTERVAL '24 months'
ORDER BY
    month_start;
```

### Chart 2: Order Size and Composition Analysis

**Purpose**: Examines patterns in order size, units per order, and product mix to understand customer purchasing behavior and identify opportunities for increasing basket size.

**SQL Query 1: Order Size Distribution**
```sql
WITH order_size_ranges AS (
    SELECT
        order_id,
        quantity,
        total_amount,
        CASE
            WHEN quantity = 1 THEN 'Single-item Orders'
            WHEN quantity = 2 THEN '2-item Orders'
            WHEN quantity = 3 THEN '3-item Orders'
            WHEN quantity BETWEEN 4 AND 5 THEN '4-5 Item Orders'
            ELSE '6+ Item Orders'
        END AS quantity_range,
        CASE
            WHEN total_amount < 25 THEN 'Under $25'
            WHEN total_amount >= 25 AND total_amount < 50 THEN '$25-$49.99'
            WHEN total_amount >= 50 AND total_amount < 100 THEN '$50-$99.99'
            WHEN total_amount >= 100 AND total_amount < 250 THEN '$100-$249.99'
            ELSE '$250+'
        END AS value_range
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= CURRENT_DATE - INTERVAL '90 days'
)
SELECT
    quantity_range,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage_of_orders,
    SUM(quantity) AS total_units,
    ROUND(100.0 * SUM(quantity) / SUM(SUM(quantity)) OVER (), 1) AS percentage_of_units,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(100.0 * SUM(total_amount) / SUM(SUM(total_amount)) OVER (), 1) AS percentage_of_revenue,
    ROUND((SUM(total_amount) / COUNT(*))::numeric, 2) AS average_order_value,
    ROUND((SUM(total_amount) / SUM(quantity))::numeric, 2) AS average_unit_price
FROM
    order_size_ranges
GROUP BY
    quantity_range
ORDER BY
    CASE
        WHEN quantity_range = 'Single-item Orders' THEN 1
        WHEN quantity_range = '2-item Orders' THEN 2
        WHEN quantity_range = '3-item Orders' THEN 3
        WHEN quantity_range = '4-5 Item Orders' THEN 4
        ELSE 5
    END;
```

**SQL Query 2: Time-Based Order Size Trends**
```sql
WITH monthly_order_sizes AS (
    SELECT
        DATE_TRUNC('month', order_date)::date AS month,
        COUNT(*) AS total_orders,
        SUM(quantity) AS total_units,
        SUM(total_amount) AS total_revenue,
        AVG(quantity) AS avg_units_per_order,
        SUM(quantity) / COUNT(*) AS units_per_order_ratio,
        AVG(total_amount) AS avg_order_value
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY
        month
)
SELECT
    month,
    TO_CHAR(month, 'Month YYYY') AS month_name,
    total_orders,
    total_units,
    ROUND(total_revenue::numeric, 2) AS total_revenue,
    ROUND(avg_units_per_order::numeric, 2) AS avg_units_per_order,
    ROUND(units_per_order_ratio::numeric, 2) AS units_per_order_ratio,
    ROUND(avg_order_value::numeric, 2) AS avg_order_value,
    
    -- Calculate rate of change
    ROUND(100.0 * (avg_units_per_order - LAG(avg_units_per_order) OVER (ORDER BY month)) / 
           NULLIF(LAG(avg_units_per_order) OVER (ORDER BY month), 0), 1) AS mom_units_change,
    ROUND(100.0 * (avg_order_value - LAG(avg_order_value) OVER (ORDER BY month)) / 
           NULLIF(LAG(avg_order_value) OVER (ORDER BY month), 0), 1) AS mom_aov_change
FROM
    monthly_order_sizes
ORDER BY
    month;
```

**SQL Query 3: Category Mix Within Orders**
```sql
WITH order_categories AS (
    SELECT
        o.order_id,
        p.category,
        COUNT(*) AS category_item_count,
        COUNT(*) OVER (PARTITION BY o.order_id) AS total_order_items,
        COUNT(DISTINCT p.category) OVER (PARTITION BY o.order_id) AS category_count_per_order
    FROM
        orders o
    JOIN
        products p ON o.product_id = p.product_id
    WHERE
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '90 days'
)
SELECT
    -- Category diversity analysis
    category_count_per_order AS unique_categories_in_order,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(100.0 * COUNT(DISTINCT order_id) / 
           (SELECT COUNT(DISTINCT order_id) FROM order_categories), 1) AS percentage_of_orders,
    ROUND(AVG(total_order_items)::numeric, 2) AS avg_items_per_order
FROM
    order_categories
GROUP BY
    category_count_per_order
ORDER BY
    category_count_per_order;
```

### Chart 3: Order Timing Patterns

**Purpose**: Identifies patterns in when customers place orders to optimize marketing, staffing, and operational planning.

**SQL Query 1: Hourly Order Distribution**
```sql
SELECT
    EXTRACT(HOUR FROM order_date) AS hour_of_day,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage_of_orders,
    SUM(total_amount) AS total_revenue,
    ROUND(100.0 * SUM(total_amount) / SUM(SUM(total_amount)) OVER (), 1) AS percentage_of_revenue,
    ROUND((SUM(total_amount) / COUNT(*))::numeric, 2) AS average_order_value
FROM
    orders
WHERE
    status != 'Cancelled' AND is_returned = FALSE
    AND order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY
    hour_of_day
ORDER BY
    hour_of_day;
```

**SQL Query 2: Day of Week vs. Hour of Day Heatmap**
```sql
SELECT
    EXTRACT(DOW FROM order_date) AS day_of_week,
    EXTRACT(HOUR FROM order_date) AS hour_of_day,
    COUNT(*) AS order_count,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND((SUM(total_amount) / COUNT(*))::numeric, 2) AS average_order_value
FROM
    orders
WHERE
    status != 'Cancelled' AND is_returned = FALSE
    AND order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY
    day_of_week, hour_of_day
ORDER BY
    day_of_week, hour_of_day;
```

**SQL Query 3: Day of Month Order Patterns**
```sql
WITH day_of_month_orders AS (
    SELECT
        EXTRACT(DAY FROM order_date) AS day_of_month,
        COUNT(*) AS order_count,
        SUM(total_amount) AS total_revenue,
        EXTRACT(MONTH FROM order_date) AS month,
        EXTRACT(YEAR FROM order_date) AS year
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY
        day_of_month, month, year
),
daily_averages AS (
    SELECT
        day_of_month,
        AVG(order_count) AS avg_order_count,
        AVG(total_revenue) AS avg_revenue
    FROM
        day_of_month_orders
    GROUP BY
        day_of_month
),
monthly_patterns AS (
    SELECT
        CASE
            WHEN day_of_month BETWEEN 1 AND 5 THEN 'Days 1-5'
            WHEN day_of_month BETWEEN 6 AND 10 THEN 'Days 6-10'
            WHEN day_of_month BETWEEN 11 AND 15 THEN 'Days 11-15'
            WHEN day_of_month BETWEEN 16 AND 20 THEN 'Days 16-20'
            WHEN day_of_month BETWEEN 21 AND 25 THEN 'Days 21-25'
            ELSE 'Days 26+'
        END AS date_range,
        AVG(avg_order_count) AS avg_daily_orders,
        AVG(avg_revenue) AS avg_daily_revenue
    FROM
        daily_averages
    GROUP BY
        date_range
)
SELECT
    date_range,
    ROUND(avg_daily_orders::numeric, 1) AS avg_daily_orders,
    ROUND(100.0 * avg_daily_orders / 
           (SELECT AVG(avg_daily_orders) FROM monthly_patterns), 1) AS percentage_of_average,
    ROUND(avg_daily_revenue::numeric, 2) AS avg_daily_revenue
FROM
    monthly_patterns
ORDER BY
    CASE
        WHEN date_range = 'Days 1-5' THEN 1
        WHEN date_range = 'Days 6-10' THEN 2
        WHEN date_range = 'Days 11-15' THEN 3
        WHEN date_range = 'Days 16-20' THEN 4
        WHEN date_range = 'Days 21-25' THEN 5
        ELSE 6
    END;
```

## YouTube Script: Mastering Order Trends & Patterns Analysis

Welcome back everyone! Today we're diving deep into Order Trends and Patterns - the underlying rhythms and cycles that drive your business. Understanding these patterns is crucial for forecasting, planning resources, and identifying growth opportunities that might otherwise remain hidden.

Let's start with our Multi-Period Order Analysis. The first query provides a comprehensive daily pattern analysis over the past 90 days. What makes this query so powerful is how it combines absolute numbers with relative comparisons - not just how many orders you received each day, but how that compares to yesterday and the same day last week. The 7-day moving averages are particularly valuable because they smooth out day-to-day fluctuations while still revealing meaningful trends.

This analysis immediately reveals weekly cycles - perhaps your order volume predictably peaks on weekends and dips mid-week. Recognizing these patterns helps you staff appropriately, time marketing campaigns effectively, and set realistic daily goals.

The second query expands to a weekly view over two years, directly comparing each week to the same week last year. This year-over-year comparison is crucial because it automatically accounts for seasonal patterns. A 20% increase from September to December might be normal holiday seasonality, but a 20% increase compared to last December represents real growth. This perspective helps you distinguish between seasonal cycles and true business expansion.

The third query takes an even broader monthly view over three years. It's particularly comprehensive, tracking not just order counts and revenue but also metrics like unique customers, average order value, and orders per customer. The month-over-month and year-over-year comparisons help you identify both short-term momentum and long-term growth trajectories.

Moving to our Order Size and Composition Analysis, the first query examines your order size distribution. Understanding what percentage of your orders are single-item versus multi-item is crucial for optimization strategies. If 70% of your orders contain just one item, there's likely significant opportunity to increase revenue through cross-selling and bundling. The analysis also reveals whether your large orders have different characteristics than your small ones - perhaps multi-item orders have a lower average unit price but higher total value.

The second query tracks how your average order size changes over time. This temporal perspective helps identify whether seasonal factors affect not just order volume but also order composition. Maybe your holiday orders contain more items on average, or perhaps summer purchases tend to be smaller. These insights can inform your merchandising and promotion strategies throughout the year.

The third query analyzes category diversity within orders. This reveals whether customers typically buy within a single category or across multiple categories. Orders spanning multiple categories often indicate strong cross-selling opportunities and broader customer engagement with your brand. This analysis can directly inform your product recommendation strategy and store layout (both physical and digital).

Our final chart focuses on Order Timing Patterns. The first query breaks down orders by hour of day, revealing when your customers are most active. These hourly patterns are crucial for operational planning - knowing your peak ordering hours helps you staff customer service appropriately, time system maintenance for low-traffic periods, and even schedule marketing campaigns for maximum impact.

The second query creates a day-of-week versus hour-of-day heatmap. This two-dimensional view reveals even more nuanced patterns - perhaps weekday evenings are your busiest time, or weekend mornings see the highest average order values. This granular understanding of order timing helps optimize everything from marketing to inventory management.

The third query examines patterns based on day of month. This often reveals surprising insights related to paydays, bill cycles, or monthly shopping habits. For example, many businesses see spikes in the first few days of the month or around the 15th, coinciding with common paydays. Understanding these monthly rhythms helps with cash flow forecasting and promotional timing.

What makes these order trend analyses so valuable is how they transform historical data into predictive insights. By identifying recurring patterns in your order data, you can anticipate future behavior and plan accordingly. This proactive approach improves operational efficiency, enhances customer experience, and ultimately drives more profitable growth.

These analyses also help you distinguish between different types of changes in your business. Is a sudden spike in orders a random fluctuation, the start of a new trend, or part of a predictable seasonal pattern? Understanding the underlying rhythms of your business helps you respond appropriately to each situation.

Remember that these patterns aren't static - they evolve as your business grows, your product mix changes, and external factors shift consumer behavior. That's why it's important to review these analyses regularly and update your strategies based on emerging patterns.

In our next video, we'll explore Order Processing Efficiency, where we'll look at how to optimize your internal workflows to fulfill orders more quickly and effectively. See you then!
