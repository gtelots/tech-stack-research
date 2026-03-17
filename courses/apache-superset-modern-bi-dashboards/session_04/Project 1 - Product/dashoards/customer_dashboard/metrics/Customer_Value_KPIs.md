# Customer Value KPIs

## Business Context
Customer value KPIs measure how much revenue and profit customers generate, helping you understand the financial impact of your customer relationships. These metrics provide essential insights for marketing investment decisions, pricing strategies, and customer retention initiatives.

## Dashboard Charts

### Chart 1: Revenue per Customer

**Purpose**: Tracks how much revenue customers generate on average, helping measure the financial value of your customer relationships and the impact of customer-focused initiatives.

**SQL Query 1: Average Revenue Per Customer**
```sql
WITH time_periods AS (
    -- Current month MTD
    SELECT 
        'Current Month (MTD)' AS time_period,
        DATE_TRUNC('month', CURRENT_DATE)::date AS start_date,
        CURRENT_DATE AS end_date
    UNION ALL
    -- Previous month
    SELECT
        'Previous Month' AS time_period,
        DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')::date AS start_date,
        (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 day')::date AS end_date
    UNION ALL
    -- Last 30 days
    SELECT
        'Last 30 Days' AS time_period,
        (CURRENT_DATE - INTERVAL '30 days')::date AS start_date,
        CURRENT_DATE AS end_date
    UNION ALL
    -- Last 90 days
    SELECT
        'Last 90 Days' AS time_period,
        (CURRENT_DATE - INTERVAL '90 days')::date AS start_date,
        CURRENT_DATE AS end_date
    UNION ALL
    -- Last 365 days
    SELECT
        'Last 365 Days' AS time_period,
        (CURRENT_DATE - INTERVAL '365 days')::date AS start_date,
        CURRENT_DATE AS end_date
),
period_metrics AS (
    SELECT
        tp.time_period,
        tp.start_date,
        tp.end_date,
        COUNT(DISTINCT o.customer_id) AS unique_customers,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS total_revenue
    FROM
        time_periods tp
    LEFT JOIN
        orders o ON o.order_date >= tp.start_date 
               AND o.order_date <= tp.end_date
               AND o.status != 'Cancelled'
               AND o.is_returned = FALSE
    GROUP BY
        tp.time_period, tp.start_date, tp.end_date
)
SELECT
    time_period,
    unique_customers,
    total_orders,
    ROUND(total_revenue::numeric, 2) AS total_revenue,
    ROUND((total_revenue / NULLIF(unique_customers, 0))::numeric, 2) AS average_revenue_per_customer,
    ROUND((total_orders::float / NULLIF(unique_customers, 0))::numeric, 2) AS average_orders_per_customer,
    ROUND((total_revenue / NULLIF(total_orders, 0))::numeric, 2) AS average_order_value
FROM
    period_metrics
ORDER BY
    CASE
        WHEN time_period = 'Current Month (MTD)' THEN 1
        WHEN time_period = 'Previous Month' THEN 2
        WHEN time_period = 'Last 30 Days' THEN 3
        WHEN time_period = 'Last 90 Days' THEN 4
        WHEN time_period = 'Last 365 Days' THEN 5
        ELSE 6
    END;
```

**SQL Query 2: Monthly Revenue Per Customer Trend**
```sql
WITH monthly_customer_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::date AS month,
        COUNT(DISTINCT o.customer_id) AS unique_customers,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS total_revenue
    FROM
        orders o
    WHERE
        o.status != 'Cancelled'
        AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '24 months'
    GROUP BY
        month
)
SELECT
    month,
    TO_CHAR(month, 'Month YYYY') AS month_name,
    unique_customers,
    total_orders,
    ROUND(total_revenue::numeric, 2) AS total_revenue,
    ROUND((total_revenue / NULLIF(unique_customers, 0))::numeric, 2) AS average_revenue_per_customer,
    ROUND((total_orders::float / NULLIF(unique_customers, 0))::numeric, 2) AS average_orders_per_customer,
    ROUND((total_revenue / NULLIF(total_orders, 0))::numeric, 2) AS average_order_value,
    -- Month-over-month change
    ROUND(100.0 * ((total_revenue / NULLIF(unique_customers, 0)) - 
           LAG(total_revenue / NULLIF(unique_customers, 0), 1) OVER (ORDER BY month)) / 
           NULLIF(LAG(total_revenue / NULLIF(unique_customers, 0), 1) OVER (ORDER BY month), 0), 1) AS arpc_mom_change,
    -- Year-over-year change
    ROUND(100.0 * ((total_revenue / NULLIF(unique_customers, 0)) - 
           LAG(total_revenue / NULLIF(unique_customers, 0), 12) OVER (ORDER BY month)) / 
           NULLIF(LAG(total_revenue / NULLIF(unique_customers, 0), 12) OVER (ORDER BY month), 0), 1) AS arpc_yoy_change
FROM
    monthly_customer_revenue
ORDER BY
    month;
```

**SQL Query 3: Revenue Per Customer by Purchase Frequency**
```sql
WITH customer_metrics AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(o.total_amount) AS total_spend,
        MAX(o.order_date) AS last_order_date
    FROM
        orders o
    WHERE
        o.status != 'Cancelled'
        AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '365 days'
    GROUP BY
        o.customer_id
),
frequency_segments AS (
    SELECT
        customer_id,
        order_count,
        total_spend,
        CASE
            WHEN order_count = 1 THEN 'One-time Buyers'
            WHEN order_count = 2 THEN 'Two-time Buyers'
            WHEN order_count = 3 THEN 'Three-time Buyers'
            WHEN order_count BETWEEN 4 AND 5 THEN '4-5 Orders'
            WHEN order_count BETWEEN 6 AND 10 THEN '6-10 Orders'
            ELSE '11+ Orders'
        END AS frequency_segment
    FROM
        customer_metrics
    WHERE
        last_order_date >= CURRENT_DATE - INTERVAL '365 days'
)
SELECT
    frequency_segment,
    COUNT(*) AS customer_count,
    SUM(total_spend) AS total_revenue,
    ROUND((SUM(total_spend) / COUNT(*))::numeric, 2) AS average_revenue_per_customer,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage_of_customers,
    ROUND(100.0 * SUM(total_spend) / SUM(SUM(total_spend)) OVER (), 1) AS percentage_of_revenue
FROM
    frequency_segments
GROUP BY
    frequency_segment
ORDER BY
    CASE
        WHEN frequency_segment = 'One-time Buyers' THEN 1
        WHEN frequency_segment = 'Two-time Buyers' THEN 2
        WHEN frequency_segment = 'Three-time Buyers' THEN 3
        WHEN frequency_segment = '4-5 Orders' THEN 4
        WHEN frequency_segment = '6-10 Orders' THEN 5
        ELSE 6
    END;
```

### Chart 2: Customer Spend Distribution

**Purpose**: Examines how total customer spending is distributed across your customer base, helping identify your most valuable customers and opportunities for growth.

**SQL Query 1: Customer Revenue Segments**
```sql
WITH customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(o.total_amount) AS total_spend
    FROM
        orders o
    WHERE
        o.status != 'Cancelled'
        AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '365 days'
    GROUP BY
        o.customer_id
),
revenue_segments AS (
    SELECT
        customer_id,
        total_spend,
        CASE
            WHEN total_spend < 100 THEN 'Under $100'
            WHEN total_spend >= 100 AND total_spend < 250 THEN '$100-$249'
            WHEN total_spend >= 250 AND total_spend < 500 THEN '$250-$499'
            WHEN total_spend >= 500 AND total_spend < 1000 THEN '$500-$999'
            WHEN total_spend >= 1000 AND total_spend < 2500 THEN '$1,000-$2,499'
            ELSE '$2,500+'
        END AS revenue_segment
    FROM
        customer_revenue
)
SELECT
    revenue_segment,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage_of_customers,
    ROUND(SUM(total_spend)::numeric, 2) AS total_revenue,
    ROUND(100.0 * SUM(total_spend) / SUM(SUM(total_spend)) OVER (), 1) AS percentage_of_revenue,
    ROUND((SUM(total_spend) / COUNT(*))::numeric, 2) AS average_spend_in_segment
FROM
    revenue_segments
GROUP BY
    revenue_segment
ORDER BY
    CASE
        WHEN revenue_segment = 'Under $100' THEN 1
        WHEN revenue_segment = '$100-$249' THEN 2
        WHEN revenue_segment = '$250-$499' THEN 3
        WHEN revenue_segment = '$500-$999' THEN 4
        WHEN revenue_segment = '$1,000-$2,499' THEN 5
        ELSE 6
    END;
```

**SQL Query 2: Spend Concentration Analysis**
```sql
WITH customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(o.total_amount) AS total_spend
    FROM
        orders o
    WHERE
        o.status != 'Cancelled'
        AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '365 days'
    GROUP BY
        o.customer_id
),
customer_percentiles AS (
    SELECT
        customer_id,
        total_spend,
        NTILE(10) OVER (ORDER BY total_spend DESC) AS spend_decile,
        NTILE(5) OVER (ORDER BY total_spend DESC) AS spend_quintile,
        NTILE(4) OVER (ORDER BY total_spend DESC) AS spend_quartile
    FROM
        customer_revenue
),
decile_analysis AS (
    SELECT
        spend_decile,
        COUNT(*) AS customer_count,
        SUM(total_spend) AS decile_revenue,
        MIN(total_spend) AS min_spend,
        MAX(total_spend) AS max_spend,
        AVG(total_spend) AS avg_spend
    FROM
        customer_percentiles
    GROUP BY
        spend_decile
),
total_revenue AS (
    SELECT SUM(total_spend) AS grand_total FROM customer_revenue
)
SELECT
    spend_decile AS decile,
    customer_count,
    ROUND(decile_revenue::numeric, 2) AS decile_revenue,
    ROUND(100.0 * decile_revenue / tr.grand_total, 1) AS percentage_of_total_revenue,
    ROUND(min_spend::numeric, 2) AS minimum_spend,
    ROUND(max_spend::numeric, 2) AS maximum_spend,
    ROUND(avg_spend::numeric, 2) AS average_spend
FROM
    decile_analysis,
    total_revenue tr
ORDER BY
    spend_decile;
```

**SQL Query 3: Pareto Analysis (80/20 Rule)**
```sql
WITH customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(o.total_amount) AS total_spend
    FROM
        orders o
    WHERE
        o.status != 'Cancelled'
        AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '365 days'
    GROUP BY
        o.customer_id
),
ranked_customers AS (
    SELECT
        customer_id,
        total_spend,
        ROW_NUMBER() OVER (ORDER BY total_spend DESC) AS spend_rank
    FROM
        customer_revenue
),
cumulative_revenue AS (
    SELECT
        spend_rank,
        customer_id,
        total_spend,
        SUM(total_spend) OVER (ORDER BY spend_rank ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_spend,
        (SELECT SUM(total_spend) FROM customer_revenue) AS total_revenue
    FROM
        ranked_customers
),
pareto_segments AS (
    SELECT
        spend_rank,
        customer_id,
        total_spend,
        cumulative_spend,
        total_revenue,
        100.0 * cumulative_spend / total_revenue AS cumulative_percentage,
        CASE
            WHEN 100.0 * cumulative_spend / total_revenue <= 50 THEN 'Top 50% Revenue'
            WHEN 100.0 * cumulative_spend / total_revenue <= 80 THEN 'Next 30% Revenue'
            ELSE 'Bottom 20% Revenue'
        END AS revenue_segment
    FROM
        cumulative_revenue
)
SELECT
    revenue_segment,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customer_revenue), 1) AS percentage_of_customers,
    ROUND(SUM(total_spend)::numeric, 2) AS segment_revenue,
    ROUND(100.0 * SUM(total_spend) / (SELECT SUM(total_spend) FROM customer_revenue), 1) AS percentage_of_revenue
FROM
    pareto_segments
GROUP BY
    revenue_segment
ORDER BY
    CASE
        WHEN revenue_segment = 'Top 50% Revenue' THEN 1
        WHEN revenue_segment = 'Next 30% Revenue' THEN 2
        ELSE 3
    END;
```

### Chart 3: Repeat Purchase Value

**Purpose**: Analyzes how customer value changes with repeat purchases, helping quantify the financial benefit of customer retention and identify opportunities to increase purchase frequency.

**SQL Query 1: First vs. Repeat Order Value**
```sql
WITH order_sequence AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.total_amount,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS order_number
    FROM
        orders o
    WHERE
        o.status != 'Cancelled'
        AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '365 days'
),
order_types AS (
    SELECT
        order_id,
        total_amount,
        CASE
            WHEN order_number = 1 THEN 'First Purchase'
            ELSE 'Repeat Purchase'
        END AS purchase_type
    FROM
        order_sequence
)
SELECT
    purchase_type,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage_of_orders,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(100.0 * SUM(total_amount) / SUM(SUM(total_amount)) OVER (), 1) AS percentage_of_revenue,
    ROUND((SUM(total_amount) / COUNT(*))::numeric, 2) AS average_order_value
FROM
    order_types
GROUP BY
    purchase_type
ORDER BY
    CASE WHEN purchase_type = 'First Purchase' THEN 1 ELSE 2 END;
```

**SQL Query 2: Order Value by Purchase Number**
```sql
WITH order_sequence AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        o.total_amount,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS order_number
    FROM
        orders o
    WHERE
        o.status != 'Cancelled'
        AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '2 years'
),
order_number_stats AS (
    SELECT
        CASE
            WHEN order_number <= 5 THEN order_number::text
            WHEN order_number BETWEEN 6 AND 10 THEN '6-10'
            ELSE '11+'
        END AS purchase_number,
        COUNT(*) AS order_count,
        SUM(total_amount) AS total_revenue,
        AVG(total_amount) AS average_order_value
    FROM
        order_sequence
    GROUP BY
        CASE
            WHEN order_number <= 5 THEN order_number::text
            WHEN order_number BETWEEN 6 AND 10 THEN '6-10'
            ELSE '11+'
        END
)
SELECT
    purchase_number,
    order_count,
    ROUND(total_revenue::numeric, 2) AS total_revenue,
    ROUND(average_order_value::numeric, 2) AS average_order_value,
    ROUND(100.0 * order_count / SUM(order_count) OVER (), 1) AS percentage_of_orders,
    ROUND(100.0 * total_revenue / SUM(total_revenue) OVER (), 1) AS percentage_of_revenue
FROM
    order_number_stats
ORDER BY
    CASE
        WHEN purchase_number ~ '^[0-9]$' THEN CAST(purchase_number AS integer)
        WHEN purchase_number = '6-10' THEN 6
        ELSE 11
    END;
```

**SQL Query 3: Customer Value Growth Over Time**
```sql
WITH monthly_customer_cohorts AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date))::date AS cohort_month
    FROM
        orders
    WHERE
        status != 'Cancelled'
    GROUP BY
        customer_id
),
customer_monthly_spend AS (
    SELECT
        mcc.customer_id,
        mcc.cohort_month,
        DATE_TRUNC('month', o.order_date)::date AS purchase_month,
        SUM(o.total_amount) AS monthly_spend
    FROM
        monthly_customer_cohorts mcc
    JOIN
        orders o ON mcc.customer_id = o.customer_id
    WHERE
        o.status != 'Cancelled'
        AND o.is_returned = FALSE
        AND mcc.cohort_month >= CURRENT_DATE - INTERVAL '24 months'
        AND mcc.cohort_month < CURRENT_DATE - INTERVAL '6 months'  -- Ensure enough time to observe behavior
    GROUP BY
        mcc.customer_id, mcc.cohort_month, purchase_month
),
customer_cumulative_value AS (
    SELECT
        customer_id,
        cohort_month,
        purchase_month,
        monthly_spend,
        EXTRACT(MONTH FROM AGE(purchase_month, cohort_month)) + 
        EXTRACT(YEAR FROM AGE(purchase_month, cohort_month)) * 12 AS months_since_first_purchase,
        SUM(monthly_spend) OVER (
            PARTITION BY customer_id
            ORDER BY purchase_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_spend
    FROM
        customer_monthly_spend
),
cohort_monthly_value AS (
    SELECT
        cohort_month,
        months_since_first_purchase,
        COUNT(DISTINCT customer_id) AS customer_count,
        SUM(monthly_spend) AS total_monthly_revenue,
        AVG(cumulative_spend) AS avg_cumulative_value
    FROM
        customer_cumulative_value
    WHERE
        months_since_first_purchase <= 12  -- Limit to first year for clarity
    GROUP BY
        cohort_month, months_since_first_purchase
),
cohort_summary AS (
    SELECT
        months_since_first_purchase,
        AVG(avg_cumulative_value) AS avg_value_across_cohorts
    FROM
        cohort_monthly_value
    GROUP BY
        months_since_first_purchase
)
SELECT
    months_since_first_purchase,
    ROUND(avg_value_across_cohorts::numeric, 2) AS average_cumulative_value,
    ROUND(avg_value_across_cohorts - LAG(avg_value_across_cohorts, 1) OVER (ORDER BY months_since_first_purchase), 2) AS incremental_value
FROM
    cohort_summary
ORDER BY
    months_since_first_purchase;
```

## YouTube Script: Understanding Customer Value KPIs

Hey everyone! Welcome back to our Customer Dashboard series. Today we're diving into Customer Value KPIs - metrics that help you understand how much revenue your customers generate. These are some of the most important numbers for any business because they directly connect your customer relationships to your financial results.

Let's start with Revenue per Customer. The first query provides a comprehensive view of customer value across different time periods - the current month, previous month, last 30 days, last 90 days, and last year. What makes this query particularly valuable is that it calculates three interconnected metrics: average revenue per customer, average orders per customer, and average order value. Together, these metrics reveal how your customer value is structured.

For example, if your average revenue per customer is $100, that could mean they place one $100 order or ten $10 orders. These two scenarios represent very different customer relationships and require different optimization strategies. This query helps you understand which levers to pull to increase customer value.

The second query tracks monthly revenue per customer over time. The trend line this creates is one of the most important indicators of business health. If your average revenue per customer is consistently growing, that's a sign your business is becoming more efficient at monetizing customer relationships - whether through better products, improved marketing, or stronger customer relationships.

The month-over-month and year-over-year comparisons provide context for these changes, helping you distinguish between seasonal patterns and genuine improvements in customer monetization.

The third query breaks down revenue per customer by purchase frequency. This often reveals fascinating patterns - perhaps your one-time buyers spend very little, but customers who purchase 4-5 times have significantly higher spending. This insight helps you quantify the value of moving customers from one frequency segment to another.

Moving to our Customer Spend Distribution analysis, the first query segments customers based on their total annual spending. This helps you understand how your revenue is distributed across different customer value tiers. Often, businesses discover that a small percentage of high-spending customers generate a disproportionate amount of revenue, while many customers spend very little.

The second query takes this analysis further with a decile analysis - dividing your customer base into 10 equal groups based on spending. This reveals your revenue concentration even more clearly. For example, you might discover that your top 10% of customers generate 50% of your revenue, while your bottom 50% generate just 10%. These insights inform targeting, service levels, and retention priorities.

The third query performs a Pareto analysis, named after the famous 80/20 rule (where 80% of effects come from 20% of causes). It identifies what percentage of your customers generate the top 50% and 80% of revenue. This analysis often confirms the classic 80/20 distribution but sometimes reveals even more extreme concentration, like 90/10.

Our final chart focuses on Repeat Purchase Value. The first query compares the value of first purchases versus repeat purchases. This simple comparison can be eye-opening - repeat purchases often have significantly higher average order values than first purchases. This quantifies the value of customer retention in the most direct terms.

The second query breaks down order value by purchase number - first purchase, second purchase, third purchase, and so on. This sequence often shows a pattern where average order value increases with each subsequent purchase as customers become more comfortable with your brand and products. Understanding this progression helps you set appropriate expectations for new customer acquisition economics.

The third query tracks customer value growth over time, showing how the cumulative value of customer cohorts increases month by month after their first purchase. This is one of the most powerful visualizations for understanding the long-term value of acquiring a customer. It shows that the initial purchase is often just a fraction of what customers will spend over their lifetime.

What makes these customer value KPIs so valuable is how directly they connect to business financials. While metrics like customer counts and engagement are important, these revenue metrics directly impact your top line. They help answer crucial questions like "How much can we afford to spend to acquire a customer?" and "What's the financial impact of improving retention?"

These metrics also help you identify your most valuable customer segments - not just in terms of demographics or behaviors, but in actual revenue contribution. This insight helps prioritize marketing, product development, and customer service efforts to focus on the customers who matter most to your business.

Remember that these metrics can vary dramatically across different business models. Subscription businesses might see very consistent revenue per customer, while e-commerce businesses might have much more variable patterns. The key is understanding what patterns are normal for your specific business model and tracking changes over time.

In our next video, we'll explore Retention Tracker metrics, which help you understand how effectively you're keeping customers engaged and purchasing over time. See you then!
