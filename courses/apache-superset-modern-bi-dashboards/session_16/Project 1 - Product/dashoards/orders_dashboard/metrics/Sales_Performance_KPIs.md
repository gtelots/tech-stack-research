# Sales Performance KPIs

## Business Context
Sales performance KPIs provide critical insights into the revenue, profitability, and efficiency of your sales operations. These metrics help you evaluate overall business health, identify growth opportunities, and measure the impact of pricing, promotion, and product strategies.

## Dashboard Charts

### Chart 1: Revenue Summary

**Purpose**: Provides a comprehensive view of revenue performance across different time periods with relevant comparisons.

**SQL Query 1: Current Period Revenue**
```sql
WITH today_revenue AS (
    SELECT
        SUM(total_amount) AS revenue,
        COUNT(*) AS order_count,
        SUM(quantity) AS units_sold,
        SUM(total_amount) / NULLIF(COUNT(*), 0) AS average_order_value,
        SUM(quantity) / NULLIF(COUNT(*), 0) AS average_units_per_order
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date::date = CURRENT_DATE
),
yesterday_revenue AS (
    SELECT
        SUM(total_amount) AS revenue,
        COUNT(*) AS order_count,
        SUM(quantity) AS units_sold
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date::date = CURRENT_DATE - INTERVAL '1 day'
),
current_month_revenue AS (
    SELECT
        SUM(total_amount) AS revenue,
        COUNT(*) AS order_count,
        SUM(quantity) AS units_sold
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= DATE_TRUNC('month', CURRENT_DATE)
        AND order_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
),
previous_month_revenue AS (
    SELECT
        SUM(total_amount) AS revenue,
        COUNT(*) AS order_count,
        SUM(quantity) AS units_sold
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
        AND order_date < DATE_TRUNC('month', CURRENT_DATE)
)
SELECT
    -- Today's Revenue
    ROUND(tr.revenue::numeric, 2) AS today_revenue,
    tr.order_count AS today_orders,
    tr.units_sold AS today_units,
    ROUND(tr.average_order_value::numeric, 2) AS today_aov,
    ROUND(tr.average_units_per_order::numeric, 2) AS today_units_per_order,
    
    -- Day-over-Day comparison
    ROUND(100.0 * (tr.revenue - yr.revenue) / NULLIF(yr.revenue, 0), 1) AS revenue_dod_change_pct,
    ROUND(100.0 * (tr.order_count - yr.order_count) / NULLIF(yr.order_count, 0), 1) AS orders_dod_change_pct,
    
    -- Month-to-Date Revenue
    ROUND(cmr.revenue::numeric, 2) AS month_to_date_revenue,
    cmr.order_count AS month_to_date_orders,
    
    -- Month-over-Month comparison (comparing full previous month to current month projection)
    ROUND(pmr.revenue::numeric, 2) AS previous_month_revenue,
    -- Project current month based on daily average so far
    ROUND((cmr.revenue / EXTRACT(DAY FROM CURRENT_DATE)) * 
          EXTRACT(DAY FROM (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day'))::numeric, 2) 
          AS projected_month_revenue,
    -- Projected month-over-month change
    ROUND(100.0 * (
        (cmr.revenue / EXTRACT(DAY FROM CURRENT_DATE)) * 
        EXTRACT(DAY FROM (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day')) - 
        pmr.revenue) / NULLIF(pmr.revenue, 0), 1) AS projected_mom_change_pct
FROM
    today_revenue tr,
    yesterday_revenue yr,
    current_month_revenue cmr,
    previous_month_revenue pmr;
```

**SQL Query 2: Revenue by Product Category**
```sql
WITH current_period AS (
    SELECT
        p.category,
        SUM(o.total_amount) AS revenue,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(o.quantity) AS units_sold
    FROM
        orders o
    JOIN
        products p ON o.product_id = p.product_id
    WHERE
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= DATE_TRUNC('month', CURRENT_DATE)
        AND o.order_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    GROUP BY
        p.category
),
previous_period AS (
    SELECT
        p.category,
        SUM(o.total_amount) AS revenue,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(o.quantity) AS units_sold
    FROM
        orders o
    JOIN
        products p ON o.product_id = p.product_id
    WHERE
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
        AND o.order_date < DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY
        p.category
)
SELECT
    cp.category,
    ROUND(cp.revenue::numeric, 2) AS current_period_revenue,
    cp.order_count AS current_period_orders,
    cp.units_sold AS current_period_units,
    ROUND(100.0 * cp.revenue / SUM(cp.revenue) OVER (), 1) AS percentage_of_total_revenue,
    ROUND(pp.revenue::numeric, 2) AS previous_period_revenue,
    ROUND(100.0 * (cp.revenue - pp.revenue) / NULLIF(pp.revenue, 0), 1) AS revenue_period_change_pct,
    ROUND(100.0 * (cp.units_sold - pp.units_sold) / NULLIF(pp.units_sold, 0), 1) AS units_period_change_pct
FROM
    current_period cp
LEFT JOIN
    previous_period pp ON cp.category = pp.category
ORDER BY
    cp.revenue DESC;
```

**SQL Query 3: Revenue by Payment Method**
```sql
WITH current_period AS (
    SELECT
        payment_method,
        SUM(total_amount) AS revenue,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(quantity) AS units_sold,
        AVG(total_amount) AS average_order_value
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= DATE_TRUNC('month', CURRENT_DATE)
        AND order_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    GROUP BY
        payment_method
),
previous_period AS (
    SELECT
        payment_method,
        SUM(total_amount) AS revenue,
        COUNT(DISTINCT order_id) AS order_count
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
        AND order_date < DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY
        payment_method
)
SELECT
    cp.payment_method,
    ROUND(cp.revenue::numeric, 2) AS current_period_revenue,
    cp.order_count AS current_period_orders,
    ROUND(100.0 * cp.revenue / SUM(cp.revenue) OVER (), 1) AS percentage_of_total_revenue,
    ROUND(cp.average_order_value::numeric, 2) AS average_order_value,
    ROUND(pp.revenue::numeric, 2) AS previous_period_revenue,
    ROUND(100.0 * (cp.revenue - pp.revenue) / NULLIF(pp.revenue, 0), 1) AS revenue_period_change_pct,
    ROUND(100.0 * (cp.order_count - pp.order_count) / NULLIF(pp.order_count, 0), 1) AS orders_period_change_pct
FROM
    current_period cp
LEFT JOIN
    previous_period pp ON cp.payment_method = pp.payment_method
ORDER BY
    cp.revenue DESC;
```

### Chart 2: Average Order Value Trends

**Purpose**: Analyzes the average value of orders over time to identify trends in customer spending patterns and the impact of pricing and promotion strategies.

**SQL Query 1: Daily Average Order Value - Last 30 Days**
```sql
SELECT
    order_date::date AS sale_date,
    COUNT(*) AS order_count,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND((SUM(total_amount) / COUNT(*))::numeric, 2) AS average_order_value,
    ROUND((SUM(quantity) / COUNT(*))::numeric, 2) AS average_units_per_order
FROM
    orders
WHERE
    status != 'Cancelled' AND is_returned = FALSE
    AND order_date >= CURRENT_DATE - INTERVAL '30 days'
    AND order_date < CURRENT_DATE + INTERVAL '1 day'
GROUP BY
    sale_date
ORDER BY
    sale_date;
```

**SQL Query 2: Monthly Average Order Value - Last 12 Months**
```sql
SELECT
    DATE_TRUNC('month', order_date)::date AS month_start,
    TO_CHAR(DATE_TRUNC('month', order_date), 'Month YYYY') AS month_name,
    COUNT(*) AS order_count,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND((SUM(total_amount) / COUNT(*))::numeric, 2) AS average_order_value,
    ROUND(AVG(quantity)::numeric, 2) AS average_units_per_order,
    ROUND(SUM(total_amount) / SUM(quantity), 2) AS average_unit_price
FROM
    orders
WHERE
    status != 'Cancelled' AND is_returned = FALSE
    AND order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY
    month_start, month_name
ORDER BY
    month_start;
```

**SQL Query 3: Average Order Value by Customer Segment**
```sql
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(*) AS order_count,
        SUM(total_amount) AS total_spent
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY
        customer_id
),
customer_segments AS (
    SELECT
        customer_id,
        CASE
            WHEN order_count = 1 THEN 'One-time Buyers'
            WHEN order_count BETWEEN 2 AND 3 THEN 'Occasional Buyers'
            WHEN order_count BETWEEN 4 AND 6 THEN 'Regular Buyers'
            ELSE 'Frequent Buyers'
        END AS customer_segment
    FROM
        customer_orders
)
SELECT
    cs.customer_segment,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue,
    ROUND((SUM(o.total_amount) / COUNT(DISTINCT o.order_id))::numeric, 2) AS average_order_value,
    ROUND((SUM(o.quantity) / COUNT(DISTINCT o.order_id))::numeric, 2) AS average_units_per_order,
    ROUND(SUM(o.total_amount) / SUM(o.quantity), 2) AS average_unit_price
FROM
    orders o
JOIN
    customer_segments cs ON o.customer_id = cs.customer_id
WHERE
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY
    cs.customer_segment
ORDER BY
    CASE
        WHEN cs.customer_segment = 'One-time Buyers' THEN 1
        WHEN cs.customer_segment = 'Occasional Buyers' THEN 2
        WHEN cs.customer_segment = 'Regular Buyers' THEN 3
        ELSE 4
    END;
```

### Chart 3: Sales Conversion Funnel

**Purpose**: Tracks the progression of customers through the sales process, from initial interest to completed purchase, helping identify conversion bottlenecks.

**SQL Query 1: Order Status Distribution**
```sql
SELECT
    status,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage_of_orders,
    ROUND(SUM(total_amount)::numeric, 2) AS total_value,
    ROUND(AVG(total_amount)::numeric, 2) AS average_order_value
FROM
    orders
WHERE
    order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
    status
ORDER BY
    CASE
        WHEN status = 'Cancelled' THEN 1
        WHEN status = 'Processing' THEN 2
        WHEN status = 'Shipped' THEN 3
        WHEN status = 'Completed' THEN 4
        WHEN status = 'Returned' THEN 5
        ELSE 6
    END;
```

**SQL Query 2: Abandonment Rate by Stage**
```sql
-- Note: This query would typically require data from your cart/checkout system
-- The following is a theoretical query showing what would be useful

WITH funnel_stages AS (
    SELECT
        DATE_TRUNC('day', event_timestamp)::date AS event_date,
        COUNT(DISTINCT session_id) FILTER (WHERE event_type = 'product_view') AS product_views,
        COUNT(DISTINCT session_id) FILTER (WHERE event_type = 'add_to_cart') AS add_to_carts,
        COUNT(DISTINCT session_id) FILTER (WHERE event_type = 'begin_checkout') AS begin_checkouts,
        COUNT(DISTINCT session_id) FILTER (WHERE event_type = 'purchase') AS purchases
    FROM
        user_events
    WHERE
        event_timestamp >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY
        event_date
)
SELECT
    AVG(product_views) AS avg_daily_product_views,
    AVG(add_to_carts) AS avg_daily_add_to_carts,
    AVG(begin_checkouts) AS avg_daily_begin_checkouts,
    AVG(purchases) AS avg_daily_purchases,
    
    -- Conversion rates between stages
    ROUND(100.0 * AVG(add_to_carts) / NULLIF(AVG(product_views), 0), 1) AS view_to_cart_rate,
    ROUND(100.0 * AVG(begin_checkouts) / NULLIF(AVG(add_to_carts), 0), 1) AS cart_to_checkout_rate,
    ROUND(100.0 * AVG(purchases) / NULLIF(AVG(begin_checkouts), 0), 1) AS checkout_to_purchase_rate,
    
    -- Overall conversion rate
    ROUND(100.0 * AVG(purchases) / NULLIF(AVG(product_views), 0), 1) AS overall_conversion_rate,
    
    -- Abandonment rates
    ROUND(100.0 * (1 - AVG(add_to_carts) / NULLIF(AVG(product_views), 0)), 1) AS product_abandonment_rate,
    ROUND(100.0 * (1 - AVG(begin_checkouts) / NULLIF(AVG(add_to_carts), 0)), 1) AS cart_abandonment_rate,
    ROUND(100.0 * (1 - AVG(purchases) / NULLIF(AVG(begin_checkouts), 0)), 1) AS checkout_abandonment_rate
FROM
    funnel_stages;

-- Alternative query using just orders data
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE status = 'Cancelled') AS cancelled_orders,
    COUNT(*) FILTER (WHERE status != 'Cancelled') AS completed_orders,
    COUNT(*) FILTER (WHERE is_returned = TRUE) AS returned_orders,
    
    -- Cancellation and return rates
    ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'Cancelled') / NULLIF(COUNT(*), 0), 1) AS cancellation_rate,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_returned = TRUE) / 
           NULLIF(COUNT(*) FILTER (WHERE status != 'Cancelled'), 0), 1) AS return_rate
FROM
    orders
WHERE
    order_date >= CURRENT_DATE - INTERVAL '30 days';
```

**SQL Query 3: Conversion by Sales Channel**
```sql
-- Note: This query assumes you have a sales_channel field in your orders table
-- and that you track conversion data by channel

WITH channel_metrics AS (
    SELECT
        sales_channel,
        COUNT(*) AS completed_orders,
        SUM(total_amount) AS total_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled'
        AND order_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY
        sales_channel
),
channel_traffic AS (
    -- This would typically come from your website/app analytics
    -- Sample data shown for illustration
    SELECT
        'Website' AS sales_channel,
        250000 AS visitors
    UNION ALL
    SELECT
        'Mobile App' AS sales_channel,
        120000 AS visitors
    UNION ALL
    SELECT
        'In-store' AS sales_channel,
        15000 AS visitors
    UNION ALL
    SELECT
        'Phone' AS sales_channel,
        5000 AS visitors
    UNION ALL
    SELECT
        'Marketplace' AS sales_channel,
        80000 AS visitors
)
SELECT
    cm.sales_channel,
    ct.visitors AS channel_visitors,
    cm.completed_orders,
    ROUND(cm.total_revenue::numeric, 2) AS total_revenue,
    ROUND((cm.total_revenue / cm.completed_orders)::numeric, 2) AS average_order_value,
    ROUND(100.0 * cm.completed_orders / NULLIF(ct.visitors, 0), 3) AS conversion_rate,
    ROUND(cm.total_revenue / NULLIF(ct.visitors, 0), 2) AS revenue_per_visitor
FROM
    channel_metrics cm
JOIN
    channel_traffic ct ON cm.sales_channel = ct.sales_channel
ORDER BY
    cm.total_revenue DESC;

-- Alternative query using just orders data
SELECT
    sales_channel,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE status != 'Cancelled') AS completed_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE status != 'Cancelled') / NULLIF(COUNT(*), 0), 1) AS completion_rate,
    ROUND(SUM(CASE WHEN status != 'Cancelled' THEN total_amount ELSE 0 END)::numeric, 2) AS total_revenue,
    ROUND((SUM(CASE WHEN status != 'Cancelled' THEN total_amount ELSE 0 END) / 
           NULLIF(COUNT(*) FILTER (WHERE status != 'Cancelled'), 0))::numeric, 2) AS average_order_value
FROM
    orders
WHERE
    order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
    sales_channel
ORDER BY
    total_revenue DESC;
```

## YouTube Script: Understanding Sales Performance KPIs

Hey everyone! Today we're diving into Sales Performance KPIs - the metrics that tell you not just how many orders you're getting, but how much revenue they're generating and how efficiently your sales process is working.

Let's start with our Revenue Summary. The first query provides a comprehensive overview of your current revenue performance across multiple time frames. It gives you today's numbers compared to yesterday, and the current month compared to last month. What makes this query particularly valuable is that it doesn't just show the raw numbers but also calculates projected performance for the current month based on performance so far. This helps you proactively identify if you're on track to meet monthly goals.

The second query breaks down your revenue by product category. This perspective is crucial because different categories often have different margin structures, seasonal patterns, and growth trajectories. Understanding which categories are driving your revenue helps you make better inventory, marketing, and merchandising decisions. The period-over-period comparisons also help you spot categories that are growing or declining faster than others.

The third query analyzes revenue by payment method. This often reveals surprising insights - for instance, you might discover that customers using certain payment methods have significantly higher average order values. This could inform decisions about which payment options to promote or even influence your checkout design to encourage higher-value payment methods.

Moving to our Average Order Value Trends, the first query tracks daily average order value (AOV) over the past 30 days. AOV is one of the most powerful metrics for growing revenue without necessarily increasing customer acquisition costs. This daily view helps you identify the immediate impact of promotions, pricing changes, or website updates on customer spending patterns.

The second query examines monthly AOV over the past year. This longer-term perspective reveals seasonal patterns and overall trends in customer spending behavior. It also calculates average units per order and average unit price, helping you understand whether changes in AOV are driven by customers buying more items or higher-priced items.

The third query segments AOV by customer purchase frequency. This often reveals that your most frequent buyers have different spending patterns than occasional customers. For example, you might find that repeat customers actually spend less per order but order much more frequently, or vice versa. These insights can dramatically impact how you approach customer segments with different marketing strategies.

Our final chart focuses on the Sales Conversion Funnel. The first query analyzes order status distribution, showing how many orders are at each stage of your fulfillment process. This helps you identify potential bottlenecks - for instance, if you have an unusually high percentage of orders stuck in "Processing" status, that might indicate operational issues that need addressing.

The second query would ideally track abandonment rates at each stage of your purchase funnel - from product views to completed purchases. While the exact implementation depends on your specific tracking setup, understanding where potential customers drop off is crucial for conversion optimization. We've also provided an alternative query that focuses on order cancellation and return rates, which are important post-purchase conversion metrics.

The third query examines conversion rates by sales channel. This helps you understand which channels are most effective not just at generating traffic but at converting that traffic into completed sales. The revenue per visitor metric is particularly valuable as it combines both conversion rate and average order value into a single efficiency metric.

What makes these sales performance KPIs so powerful is how they build on basic order volume metrics to provide a more complete picture of your business health. While growing order volume is important, increasing revenue per order or improving conversion rates can often be more efficient paths to revenue growth.

These metrics also help you identify the most promising optimization opportunities. For instance, if your AOV is declining but your conversion rate is steady, you might focus on cross-selling or premium product promotion. Conversely, if your AOV is strong but conversion is dropping, you might need to address friction in your checkout process.

Remember that these metrics are most effective when viewed together and tracked over time. The relationships between order volume, average order value, and conversion rates reveal the true dynamics of your sales performance and help guide strategic priorities.

In our next video, we'll explore Order Status Tracking, which helps you ensure that orders move efficiently through your fulfillment process. See you then!
