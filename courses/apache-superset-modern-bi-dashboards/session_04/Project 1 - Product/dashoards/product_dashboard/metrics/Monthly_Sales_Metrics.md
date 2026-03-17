# Monthly Sales Metrics

## Business Context
Monthly sales metrics provide essential information about recent sales performance. These straightforward numbers help teams quickly understand current sales trends, identify potential issues, and track progress toward goals without requiring complex analysis.

## Dashboard Charts

### Chart 1: Current Month Sales Summary

**Purpose**: Provides a snapshot of the current month's sales performance, with comparison to previous periods.

**SQL Query 1: Current Month Overview**
```sql
WITH current_month AS (
    SELECT
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue,
        SUM(total_amount) / COUNT(DISTINCT order_id) AS average_order_value,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= DATE_TRUNC('month', CURRENT_DATE)
        AND order_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
),
previous_month AS (
    SELECT
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue,
        SUM(total_amount) / COUNT(DISTINCT order_id) AS average_order_value,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
        AND order_date < DATE_TRUNC('month', CURRENT_DATE)
),
same_month_last_year AS (
    SELECT
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue,
        SUM(total_amount) / COUNT(DISTINCT order_id) AS average_order_value,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 year')
        AND order_date < DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 year') + INTERVAL '1 month'
)
SELECT
    cm.total_orders,
    cm.units_sold,
    ROUND(cm.total_revenue::numeric, 2) AS total_revenue,
    ROUND(cm.average_order_value::numeric, 2) AS average_order_value,
    cm.unique_customers,
    -- Month over Month changes
    ROUND(100.0 * (cm.total_orders - pm.total_orders) / NULLIF(pm.total_orders, 0), 1) AS mom_orders_change_pct,
    ROUND(100.0 * (cm.units_sold - pm.units_sold) / NULLIF(pm.units_sold, 0), 1) AS mom_units_change_pct,
    ROUND(100.0 * (cm.total_revenue - pm.total_revenue) / NULLIF(pm.total_revenue, 0), 1) AS mom_revenue_change_pct,
    -- Year over Year changes
    ROUND(100.0 * (cm.total_orders - smly.total_orders) / NULLIF(smly.total_orders, 0), 1) AS yoy_orders_change_pct,
    ROUND(100.0 * (cm.units_sold - smly.units_sold) / NULLIF(smly.units_sold, 0), 1) AS yoy_units_change_pct,
    ROUND(100.0 * (cm.total_revenue - smly.total_revenue) / NULLIF(smly.total_revenue, 0), 1) AS yoy_revenue_change_pct
FROM
    current_month cm,
    previous_month pm,
    same_month_last_year smly;
```

**SQL Query 2: Daily Sales Trend for Current Month**
```sql
SELECT
    order_date::date AS sale_date,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue
FROM
    orders
WHERE
    status != 'Cancelled' AND is_returned = FALSE
    AND order_date >= DATE_TRUNC('month', CURRENT_DATE)
    AND order_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
GROUP BY
    sale_date
ORDER BY
    sale_date;
```

**SQL Query 3: Top 5 Products This Month**
```sql
SELECT
    p.product_id,
    p.name,
    p.category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.quantity) AS units_sold,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue
FROM
    orders o
JOIN
    products p ON o.product_id = p.product_id
WHERE
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= DATE_TRUNC('month', CURRENT_DATE)
    AND o.order_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
GROUP BY
    p.product_id, p.name, p.category
ORDER BY
    units_sold DESC
LIMIT 5;
```

### Chart 2: Monthly Progress Tracker

**Purpose**: Tracks progress toward monthly sales goals and compares with previous month performance.

**SQL Query 1: Month-to-Date vs. Previous Month**
```sql
WITH month_to_date AS (
    SELECT
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= DATE_TRUNC('month', CURRENT_DATE)
        AND order_date <= CURRENT_DATE
),
same_days_last_month AS (
    SELECT
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
        AND order_date <= (DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month') + 
                          (CURRENT_DATE - DATE_TRUNC('month', CURRENT_DATE)))
),
full_last_month AS (
    SELECT
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(quantity) AS units_sold,
        SUM(total_amount) AS total_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
        AND order_date < DATE_TRUNC('month', CURRENT_DATE)
)
SELECT
    EXTRACT(DAY FROM CURRENT_DATE) AS days_elapsed,
    EXTRACT(DAY FROM (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day')) AS days_in_month,
    ROUND(100.0 * EXTRACT(DAY FROM CURRENT_DATE) / 
           EXTRACT(DAY FROM (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day')), 1) 
           AS percentage_of_month_elapsed,
    -- MTD Numbers
    mtd.total_orders,
    mtd.units_sold,
    ROUND(mtd.total_revenue::numeric, 2) AS mtd_revenue,
    -- Comparisons
    sdlm.total_orders AS same_period_last_month_orders,
    sdlm.units_sold AS same_period_last_month_units,
    ROUND(sdlm.total_revenue::numeric, 2) AS same_period_last_month_revenue,
    -- Growth
    ROUND(100.0 * (mtd.total_orders - sdlm.total_orders) / NULLIF(sdlm.total_orders, 0), 1) AS order_growth_pct,
    ROUND(100.0 * (mtd.units_sold - sdlm.units_sold) / NULLIF(sdlm.units_sold, 0), 1) AS units_growth_pct,
    ROUND(100.0 * (mtd.total_revenue - sdlm.total_revenue) / NULLIF(sdlm.total_revenue, 0), 1) AS revenue_growth_pct,
    -- Projected
    ROUND((mtd.total_revenue / EXTRACT(DAY FROM CURRENT_DATE) * 
           EXTRACT(DAY FROM (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day')))::numeric, 2) 
           AS projected_monthly_revenue,
    ROUND(flm.total_revenue::numeric, 2) AS last_month_total_revenue
FROM
    month_to_date mtd,
    same_days_last_month sdlm,
    full_last_month flm;
```

**SQL Query 2: Daily Revenue vs. Target**
```sql
WITH monthly_target AS (
    -- This would typically come from a targets table; using sample data here
    SELECT
        -- Sample target: 5% growth from same month last year
        1.05 * (
            SELECT SUM(total_amount)
            FROM orders
            WHERE status != 'Cancelled' AND is_returned = FALSE
            AND order_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 year')
            AND order_date < DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 year') + INTERVAL '1 month'
        ) AS revenue_target
),
daily_sales AS (
    SELECT
        order_date::date AS sale_date,
        SUM(total_amount) AS daily_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= DATE_TRUNC('month', CURRENT_DATE)
        AND order_date <= CURRENT_DATE
    GROUP BY
        sale_date
),
cumulative_sales AS (
    SELECT
        sale_date,
        daily_revenue,
        SUM(daily_revenue) OVER (ORDER BY sale_date) AS cumulative_revenue
    FROM
        daily_sales
),
days_in_month AS (
    SELECT EXTRACT(DAY FROM (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day')) AS days
)
SELECT
    cs.sale_date,
    ROUND(cs.daily_revenue::numeric, 2) AS daily_revenue,
    ROUND(cs.cumulative_revenue::numeric, 2) AS cumulative_revenue,
    ROUND((mt.revenue_target / dim.days * EXTRACT(DAY FROM cs.sale_date))::numeric, 2) AS target_to_date,
    ROUND(mt.revenue_target::numeric, 2) AS monthly_target,
    ROUND(100.0 * cs.cumulative_revenue / (mt.revenue_target / dim.days * EXTRACT(DAY FROM cs.sale_date)), 1) 
        AS percent_of_target_achieved
FROM
    cumulative_sales cs,
    monthly_target mt,
    days_in_month dim
ORDER BY
    cs.sale_date;
```

**SQL Query 3: Category Performance MTD**
```sql
WITH current_month AS (
    SELECT
        p.category,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.quantity) AS units_sold,
        SUM(o.total_amount) AS total_revenue
    FROM
        orders o
    JOIN
        products p ON o.product_id = p.product_id
    WHERE
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= DATE_TRUNC('month', CURRENT_DATE)
        AND o.order_date <= CURRENT_DATE
    GROUP BY
        p.category
),
previous_month_same_period AS (
    SELECT
        p.category,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.quantity) AS units_sold,
        SUM(o.total_amount) AS total_revenue
    FROM
        orders o
    JOIN
        products p ON o.product_id = p.product_id
    WHERE
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
        AND o.order_date <= (DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month') + 
                            (CURRENT_DATE - DATE_TRUNC('month', CURRENT_DATE)))
    GROUP BY
        p.category
)
SELECT
    cm.category,
    cm.total_orders,
    cm.units_sold,
    ROUND(cm.total_revenue::numeric, 2) AS total_revenue,
    pmsp.total_orders AS prev_month_orders,
    pmsp.units_sold AS prev_month_units,
    ROUND(pmsp.total_revenue::numeric, 2) AS prev_month_revenue,
    ROUND(100.0 * (cm.total_orders - pmsp.total_orders) / NULLIF(pmsp.total_orders, 0), 1) AS order_growth_pct,
    ROUND(100.0 * (cm.units_sold - pmsp.units_sold) / NULLIF(pmsp.units_sold, 0), 1) AS units_growth_pct,
    ROUND(100.0 * (cm.total_revenue - pmsp.total_revenue) / NULLIF(pmsp.total_revenue, 0), 1) AS revenue_growth_pct
FROM
    current_month cm
LEFT JOIN
    previous_month_same_period pmsp ON cm.category = pmsp.category
ORDER BY
    cm.total_revenue DESC;
```

## YouTube Script: Understanding Monthly Sales Metrics

Hi everyone! Today we're looking at some simple but extremely powerful monthly sales metrics that help you keep your finger on the pulse of your business. These are the numbers you'll want to check every morning to understand how your month is shaping up.

Let's start with our Current Month Sales Summary. The first query provides a comprehensive snapshot of your current month's performance. What makes this query so useful is that it doesn't just show your current numbers - it puts them in context by comparing them to both the previous month and the same month last year.

This gives you two crucial perspectives: the month-over-month comparison shows your short-term momentum, while the year-over-year comparison accounts for seasonal patterns. For example, a 5% drop from November to December might look concerning until you see that you're actually up 15% compared to last December.

The second query breaks down your daily sales trend for the current month. This helps you identify any unusual patterns or disruptions. Maybe you had a big spike from a promotion, or perhaps you see a sudden drop that coincides with a website issue. This day-by-day view gives you that visibility.

The third query simply shows your top 5 products for the month. This is one of those metrics that often contains surprises - sometimes a product that wasn't on your radar suddenly jumps into the top 5, signaling a trend you might want to capitalize on with additional inventory or marketing.

Moving to our second chart, the Monthly Progress Tracker helps you understand whether you're on pace to hit your goals. The first query here compares your month-to-date performance with the same number of days from last month. This is crucial because comparing the first week of a month to the entire previous month isn't meaningful - you need to compare apples to apples.

What's particularly valuable about this query is that it also calculates your projected monthly revenue based on current performance. If you're 15 days into a 30-day month and have generated $50,000, it projects that you'll finish around $100,000 - assuming consistent performance.

The second query tracks your daily revenue against your monthly target. It creates a day-by-day target line and shows whether you're ahead or behind. This is incredibly actionable because it tells you immediately if you need to make adjustments to hit your goals - like running a promotion or increasing marketing spend.

The third query examines category performance for the month-to-date. This helps you identify which product categories are driving your success or causing concerns. Maybe your overall sales are up 10%, but when you look at categories, you realize that's entirely driven by Electronics while Apparel is actually down 5%. This granular view helps you direct your attention where it's needed most.

What makes these metrics so valuable is their simplicity and immediacy. Unlike complex analyses that might take time to prepare and interpret, these numbers give you instant insights into your current performance and trajectory. They're perfect for daily monitoring and quick decision-making.

Remember that these metrics are most effective when monitored consistently. Small changes day-to-day might not mean much, but developing an intuitive feel for what's normal allows you to quickly spot meaningful deviations that require action.

In our next video, we'll look at Inventory Status Metrics that provide similar straightforward insights into your current inventory health. See you then!
