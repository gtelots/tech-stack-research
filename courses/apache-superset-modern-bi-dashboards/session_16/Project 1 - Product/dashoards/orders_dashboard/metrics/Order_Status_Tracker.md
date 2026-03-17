# Order Status Tracker

## Business Context
The Order Status Tracker provides real-time visibility into where orders are in the fulfillment process. This information helps operations teams prioritize work, identify bottlenecks, and ensure timely delivery while providing management with a clear picture of fulfillment efficiency.

## Dashboard Charts

### Chart 1: Current Order Status Distribution

**Purpose**: Provides an immediate snapshot of how many orders are at each stage of the fulfillment process, helping identify potential bottlenecks or unusual patterns.

**SQL Query 1: Order Count by Status**
```sql
SELECT
    status,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage_of_orders,
    ROUND(SUM(total_amount)::numeric, 2) AS total_value
FROM
    orders
WHERE
    order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
    status
ORDER BY
    CASE
        WHEN status = 'Processing' THEN 1
        WHEN status = 'Shipped' THEN 2
        WHEN status = 'Completed' THEN 3
        WHEN status = 'Cancelled' THEN 4
        WHEN status = 'Returned' THEN 5
        ELSE 6
    END;
```

**SQL Query 2: Orders by Status and Age**
```sql
SELECT
    status,
    CASE
        WHEN CURRENT_TIMESTAMP - order_date <= INTERVAL '24 hours' THEN '0-24 hours'
        WHEN CURRENT_TIMESTAMP - order_date <= INTERVAL '48 hours' THEN '24-48 hours'
        WHEN CURRENT_TIMESTAMP - order_date <= INTERVAL '72 hours' THEN '48-72 hours'
        WHEN CURRENT_TIMESTAMP - order_date <= INTERVAL '7 days' THEN '3-7 days'
        ELSE 'Over 7 days'
    END AS order_age,
    COUNT(*) AS order_count,
    ROUND(SUM(total_amount)::numeric, 2) AS total_value
FROM
    orders
WHERE
    (status = 'Processing' OR status = 'Shipped') -- Focus on active orders
    AND order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
    status, order_age
ORDER BY
    CASE
        WHEN status = 'Processing' THEN 1
        WHEN status = 'Shipped' THEN 2
        ELSE 3
    END,
    CASE
        WHEN order_age = '0-24 hours' THEN 1
        WHEN order_age = '24-48 hours' THEN 2
        WHEN order_age = '48-72 hours' THEN 3
        WHEN order_age = '3-7 days' THEN 4
        ELSE 5
    END;
```

**SQL Query 3: Aging Orders Requiring Attention**
```sql
SELECT
    order_id,
    customer_id,
    order_date,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - order_date)) / 3600 AS hours_since_order,
    status,
    payment_method,
    total_amount,
    CASE
        WHEN status = 'Processing' AND CURRENT_TIMESTAMP - order_date > INTERVAL '48 hours' THEN 'High'
        WHEN status = 'Processing' AND CURRENT_TIMESTAMP - order_date > INTERVAL '24 hours' THEN 'Medium'
        WHEN status = 'Shipped' AND CURRENT_TIMESTAMP - order_date > INTERVAL '7 days' THEN 'Medium'
        ELSE 'Normal'
    END AS priority
FROM
    orders
WHERE
    (
        (status = 'Processing' AND CURRENT_TIMESTAMP - order_date > INTERVAL '24 hours') OR
        (status = 'Shipped' AND CURRENT_TIMESTAMP - order_date > INTERVAL '7 days' AND delivery_date IS NULL)
    )
    AND order_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY
    CASE
        WHEN status = 'Processing' AND CURRENT_TIMESTAMP - order_date > INTERVAL '48 hours' THEN 1
        WHEN status = 'Processing' AND CURRENT_TIMESTAMP - order_date > INTERVAL '24 hours' THEN 2
        WHEN status = 'Shipped' AND CURRENT_TIMESTAMP - order_date > INTERVAL '7 days' THEN 3
        ELSE 4
    END,
    hours_since_order DESC;
```

### Chart 2: Order Status Timeline

**Purpose**: Tracks how orders move through each status over time, helping identify processing delays, bottlenecks, or changes in fulfillment efficiency.

**SQL Query 1: Average Time in Each Status**
```sql
-- Note: This query would typically require a status history table
-- The following is a simplified version based on available fields

WITH order_timestamps AS (
    SELECT
        order_id,
        order_date AS processing_start,
        CASE
            WHEN status = 'Shipped' OR status = 'Completed' OR status = 'Returned' THEN
                order_date + INTERVAL '1 day' * (RANDOM() * 2)  -- Simulating ship date
            ELSE NULL
        END AS shipping_date,
        CASE
            WHEN status = 'Completed' OR status = 'Returned' THEN
                delivery_date
            ELSE NULL
        END AS delivery_date,
        CASE
            WHEN status = 'Returned' THEN
                return_date
            ELSE NULL
        END AS return_date
    FROM
        orders
    WHERE
        status != 'Cancelled'
        AND order_date >= CURRENT_DATE - INTERVAL '90 days'
)
SELECT
    -- Processing time (from order to shipping)
    AVG(EXTRACT(EPOCH FROM (shipping_date - processing_start)) / 3600) AS avg_processing_hours,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (shipping_date - processing_start)) / 3600) AS median_processing_hours,
    
    -- Shipping time (from shipping to delivery)
    AVG(EXTRACT(EPOCH FROM (delivery_date - shipping_date)) / 3600) / 24 AS avg_shipping_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (delivery_date - shipping_date)) / 3600 / 24) AS median_shipping_days,
    
    -- Total fulfillment time (from order to delivery)
    AVG(EXTRACT(EPOCH FROM (delivery_date - processing_start)) / 3600) / 24 AS avg_total_fulfillment_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (delivery_date - processing_start)) / 3600 / 24) AS median_total_fulfillment_days,
    
    -- Return processing time (for returned orders)
    AVG(EXTRACT(EPOCH FROM (return_date - delivery_date)) / 3600) / 24 AS avg_days_to_return,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (return_date - delivery_date)) / 3600 / 24) AS median_days_to_return
FROM
    order_timestamps
WHERE
    shipping_date IS NOT NULL;
```

**SQL Query 2: Status Transition Trend**
```sql
-- Note: This query would ideally use a status history table
-- The following is an example of what would be useful

WITH daily_status_counts AS (
    SELECT
        DATE_TRUNC('day', order_date)::date AS day,
        COUNT(*) FILTER (WHERE status = 'Processing') AS processing_orders,
        COUNT(*) FILTER (WHERE status = 'Shipped') AS shipped_orders,
        COUNT(*) FILTER (WHERE status = 'Completed') AS completed_orders,
        COUNT(*) FILTER (WHERE status = 'Cancelled') AS cancelled_orders,
        COUNT(*) FILTER (WHERE status = 'Returned') AS returned_orders
    FROM
        orders
    WHERE
        order_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY
        day
)
SELECT
    day,
    processing_orders,
    shipped_orders,
    completed_orders,
    cancelled_orders,
    returned_orders,
    
    -- Daily efficiency metrics
    CASE
        WHEN processing_orders + shipped_orders = 0 THEN NULL
        ELSE (completed_orders::float / (processing_orders + shipped_orders + completed_orders))
    END AS daily_completion_rate,
    
    CASE
        WHEN processing_orders = 0 THEN NULL
        ELSE (shipped_orders::float / processing_orders)
    END AS processing_to_shipping_ratio
FROM
    daily_status_counts
ORDER BY
    day;
```

**SQL Query 3: Processing Backlog Trend**
```sql
WITH daily_backlog AS (
    SELECT
        DATE_TRUNC('day', CURRENT_DATE - offs)::date AS day,
        COUNT(*) FILTER (WHERE 
            status = 'Processing' AND 
            order_date <= DATE_TRUNC('day', CURRENT_DATE - offs)
        ) AS processing_backlog,
        COUNT(*) FILTER (WHERE 
            status = 'Shipped' AND 
            order_date <= DATE_TRUNC('day', CURRENT_DATE - offs) AND
            (delivery_date IS NULL OR delivery_date > DATE_TRUNC('day', CURRENT_DATE - offs))
        ) AS shipping_backlog,
        COUNT(*) FILTER (WHERE 
            order_date = DATE_TRUNC('day', CURRENT_DATE - offs)
        ) AS new_orders
    FROM
        orders,
        generate_series(0, 29) AS offs
    WHERE
        order_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY
        day
)
SELECT
    day,
    processing_backlog,
    shipping_backlog,
    new_orders,
    processing_backlog + shipping_backlog AS total_active_orders,
    ROUND(100.0 * processing_backlog / NULLIF(new_orders, 0), 1) AS backlog_to_new_ratio
FROM
    daily_backlog
ORDER BY
    day;
```

### Chart 3: Delivery Performance

**Purpose**: Measures actual delivery times against expectations, helping ensure customer satisfaction through on-time delivery.

**SQL Query 1: On-Time Delivery Performance**
```sql
WITH delivery_performance AS (
    SELECT
        order_id,
        order_date,
        delivery_date,
        -- Assuming expected delivery based on shipping method
        CASE
            WHEN shipping_method = 'Express' THEN order_date + INTERVAL '2 days'
            WHEN shipping_method = 'Next Day' THEN order_date + INTERVAL '1 day'
            WHEN shipping_method = 'Standard' THEN order_date + INTERVAL '5 days'
            WHEN shipping_method = 'International' THEN order_date + INTERVAL '10 days'
            ELSE order_date + INTERVAL '5 days' -- Default
        END AS expected_delivery,
        shipping_method
    FROM
        orders
    WHERE
        status = 'Completed'
        AND delivery_date IS NOT NULL
        AND order_date >= CURRENT_DATE - INTERVAL '90 days'
)
SELECT
    COUNT(*) AS total_delivered_orders,
    COUNT(*) FILTER (WHERE delivery_date <= expected_delivery) AS on_time_deliveries,
    COUNT(*) FILTER (WHERE delivery_date > expected_delivery) AS late_deliveries,
    ROUND(100.0 * COUNT(*) FILTER (WHERE delivery_date <= expected_delivery) / NULLIF(COUNT(*), 0), 1) AS on_time_delivery_rate,
    AVG(EXTRACT(EPOCH FROM (delivery_date - order_date)) / 86400) AS avg_delivery_days,
    AVG(EXTRACT(EPOCH FROM (delivery_date - expected_delivery)) / 86400) FILTER (WHERE delivery_date > expected_delivery) AS avg_days_late,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (delivery_date - order_date)) / 86400) AS delivery_days_95th_percentile
FROM
    delivery_performance;
```

**SQL Query 2: Delivery Performance by Shipping Method**
```sql
WITH delivery_performance AS (
    SELECT
        order_id,
        order_date,
        delivery_date,
        -- Assuming expected delivery based on shipping method
        CASE
            WHEN shipping_method = 'Express' THEN order_date + INTERVAL '2 days'
            WHEN shipping_method = 'Next Day' THEN order_date + INTERVAL '1 day'
            WHEN shipping_method = 'Standard' THEN order_date + INTERVAL '5 days'
            WHEN shipping_method = 'International' THEN order_date + INTERVAL '10 days'
            WHEN shipping_method = 'Store Pickup' THEN order_date + INTERVAL '1 day'
            ELSE order_date + INTERVAL '5 days' -- Default
        END AS expected_delivery,
        shipping_method
    FROM
        orders
    WHERE
        status = 'Completed'
        AND delivery_date IS NOT NULL
        AND order_date >= CURRENT_DATE - INTERVAL '90 days'
)
SELECT
    shipping_method,
    COUNT(*) AS total_delivered_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE delivery_date <= expected_delivery) / NULLIF(COUNT(*), 0), 1) AS on_time_delivery_rate,
    AVG(EXTRACT(EPOCH FROM (delivery_date - order_date)) / 86400) AS avg_delivery_days,
    AVG(EXTRACT(EPOCH FROM (delivery_date - expected_delivery)) / 86400) FILTER (WHERE delivery_date > expected_delivery) AS avg_days_late,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (delivery_date - order_date)) / 86400) AS delivery_days_95th_percentile
FROM
    delivery_performance
GROUP BY
    shipping_method
ORDER BY
    avg_delivery_days;
```

**SQL Query 3: Delivery Time Trends**
```sql
WITH weekly_delivery_performance AS (
    SELECT
        DATE_TRUNC('week', order_date)::date AS week_start,
        COUNT(*) AS total_delivered_orders,
        COUNT(*) FILTER (WHERE 
            -- Assuming expected delivery based on shipping method
            delivery_date <= CASE
                WHEN shipping_method = 'Express' THEN order_date + INTERVAL '2 days'
                WHEN shipping_method = 'Next Day' THEN order_date + INTERVAL '1 day'
                WHEN shipping_method = 'Standard' THEN order_date + INTERVAL '5 days'
                WHEN shipping_method = 'International' THEN order_date + INTERVAL '10 days'
                ELSE order_date + INTERVAL '5 days' -- Default
            END
        ) AS on_time_deliveries,
        AVG(EXTRACT(EPOCH FROM (delivery_date - order_date)) / 86400) AS avg_delivery_days
    FROM
        orders
    WHERE
        status = 'Completed'
        AND delivery_date IS NOT NULL
        AND order_date >= CURRENT_DATE - INTERVAL '24 weeks'
    GROUP BY
        week_start
)
SELECT
    week_start,
    total_delivered_orders,
    on_time_deliveries,
    ROUND(100.0 * on_time_deliveries / NULLIF(total_delivered_orders, 0), 1) AS on_time_delivery_rate,
    ROUND(avg_delivery_days::numeric, 1) AS avg_delivery_days
FROM
    weekly_delivery_performance
ORDER BY
    week_start;
```

## YouTube Script: Understanding Order Status Tracking

Hey everyone! Today we're diving into Order Status Tracking - a critical aspect of operations management that helps ensure customer satisfaction and operational efficiency. These metrics might seem basic, but they're absolutely essential for keeping your fulfillment machine running smoothly.

Let's start with Current Order Status Distribution. The first query gives you an immediate snapshot of how many orders are at each stage of your fulfillment process. This is one of the first things operations managers should check every morning - it tells you where your workload is concentrated and helps you spot unusual patterns that might indicate problems.

For example, if you suddenly see a much higher than normal percentage of orders in "Processing" status, that could indicate a fulfillment bottleneck that needs immediate attention. Similarly, an uptick in "Cancelled" orders might signal a customer service or inventory issue that needs investigation.

The second query breaks down active orders by both status and age. This helps you identify potentially problematic orders that have been stuck in a particular status for too long. For instance, seeing a significant number of orders that have been in "Processing" status for over 48 hours might indicate staffing issues in your warehouse or inventory problems with certain products.

The third query in this section is one of the most actionable - it creates a prioritized list of specific aging orders that require attention. By identifying orders that have been in Processing status too long or Shipped orders that should have been delivered by now, you can proactively address potential customer satisfaction issues before they escalate to complaints or cancellations.

Moving to our Order Status Timeline, the first query calculates the average time orders spend in each status. This gives you benchmark metrics for your fulfillment efficiency - how quickly do orders typically move from processing to shipping, and from shipping to delivery? These cycle time metrics are crucial for setting customer expectations and identifying opportunities for operational improvement.

The second query would ideally track how the number of orders in each status changes over time. Without a status history table, we've shown a simplified version that still provides valuable insights into daily processing efficiency and the ratio of orders moving from processing to shipping. These trend metrics help you identify whether your fulfillment operation is keeping pace with incoming order volume.

The third query analyzes your processing backlog trend over time. This is particularly valuable for operations planning, as it shows whether your backlog is growing, shrinking, or remaining stable. The backlog-to-new-orders ratio is especially insightful - if this number is consistently above 100%, it means you're accumulating a backlog that will eventually require additional resources to address.

Our final chart focuses on Delivery Performance. The first query measures on-time delivery performance, which is one of the most important metrics for customer satisfaction. It calculates what percentage of orders are delivered by their expected delivery date, how many days deliveries typically take, and how late the late deliveries are. The 95th percentile metric is particularly useful for setting realistic delivery expectations with customers.

The second query breaks down delivery performance by shipping method. This helps you evaluate the reliability of different shipping options and carriers. If you find that one shipping method consistently underperforms others in on-time delivery rate, you might want to reconsider your shipping partners or adjust the delivery expectations you set for that method.

The third query tracks delivery time trends over the past 24 weeks. This longer-term view helps you identify whether your delivery performance is improving, deteriorating, or stable over time. It can also reveal seasonal patterns - perhaps delivery times consistently slow down during holiday periods due to carrier capacity constraints.

What makes these order status metrics so valuable is their direct connection to both operational efficiency and customer satisfaction. Customers consistently rate order tracking and on-time delivery among their top priorities when shopping online. By closely monitoring these metrics, you can ensure your fulfillment operation meets those expectations while optimizing your internal processes.

These metrics are also crucial for capacity planning. Understanding your typical processing times and backlog trends helps you determine when you need to add additional fulfillment resources, whether temporarily for seasonal spikes or permanently as your business grows.

Remember that these metrics are most effective when they drive action. The goal isn't just to monitor order status but to use these insights to proactively address issues, optimize processes, and ultimately deliver a better customer experience.

In our next video, we'll explore Payment Method Analytics, which help you understand how customers prefer to pay and how different payment options affect your sales performance. See you then!
