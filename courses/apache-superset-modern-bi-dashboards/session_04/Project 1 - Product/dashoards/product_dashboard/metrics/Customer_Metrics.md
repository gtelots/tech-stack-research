# Customer Metrics

## Business Context
Customer metrics provide insights into purchasing behavior, helping you understand who is buying your products, how often they return, and what they're worth to your business. These straightforward numbers help teams track customer acquisition, retention, and value without complex analysis.

## Dashboard Charts

### Chart 1: Customer Activity Overview

**Purpose**: Provides a snapshot of customer behavior and engagement over recent time periods.

**SQL Query 1: Customer Activity Summary**
```sql
WITH current_month AS (
    SELECT
        COUNT(DISTINCT customer_id) AS active_customers,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(total_amount) AS total_revenue,
        COUNT(DISTINCT order_id)::float / COUNT(DISTINCT customer_id) AS orders_per_customer,
        SUM(total_amount) / COUNT(DISTINCT customer_id) AS revenue_per_customer,
        SUM(total_amount) / COUNT(DISTINCT order_id) AS average_order_value
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= DATE_TRUNC('month', CURRENT_DATE)
        AND order_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
),
previous_month AS (
    SELECT
        COUNT(DISTINCT customer_id) AS active_customers,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(total_amount) AS total_revenue,
        COUNT(DISTINCT order_id)::float / COUNT(DISTINCT customer_id) AS orders_per_customer,
        SUM(total_amount) / COUNT(DISTINCT customer_id) AS revenue_per_customer,
        SUM(total_amount) / COUNT(DISTINCT order_id) AS average_order_value
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
        AND order_date < DATE_TRUNC('month', CURRENT_DATE)
),
last_90_days AS (
    SELECT
        COUNT(DISTINCT customer_id) AS active_customers,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(total_amount) AS total_revenue,
        COUNT(DISTINCT order_id)::float / COUNT(DISTINCT customer_id) AS orders_per_customer,
        SUM(total_amount) / COUNT(DISTINCT customer_id) AS revenue_per_customer,
        SUM(total_amount) / COUNT(DISTINCT order_id) AS average_order_value
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= CURRENT_DATE - INTERVAL '90 days'
)
SELECT
    'Current Month' AS time_period,
    cm.active_customers,
    cm.total_orders,
    ROUND(cm.total_revenue::numeric, 2) AS total_revenue,
    ROUND(cm.orders_per_customer::numeric, 2) AS orders_per_customer,
    ROUND(cm.revenue_per_customer::numeric, 2) AS revenue_per_customer,
    ROUND(cm.average_order_value::numeric, 2) AS average_order_value
FROM
    current_month cm
UNION ALL
SELECT
    'Previous Month' AS time_period,
    pm.active_customers,
    pm.total_orders,
    ROUND(pm.total_revenue::numeric, 2) AS total_revenue,
    ROUND(pm.orders_per_customer::numeric, 2) AS orders_per_customer,
    ROUND(pm.revenue_per_customer::numeric, 2) AS revenue_per_customer,
    ROUND(pm.average_order_value::numeric, 2) AS average_order_value
FROM
    previous_month pm
UNION ALL
SELECT
    'Last 90 Days' AS time_period,
    l90.active_customers,
    l90.total_orders,
    ROUND(l90.total_revenue::numeric, 2) AS total_revenue,
    ROUND(l90.orders_per_customer::numeric, 2) AS orders_per_customer,
    ROUND(l90.revenue_per_customer::numeric, 2) AS revenue_per_customer,
    ROUND(l90.average_order_value::numeric, 2) AS average_order_value
FROM
    last_90_days l90;
```

**SQL Query 2: New vs. Returning Customers**
```sql
WITH customer_first_purchase AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM
        orders
    WHERE
        status != 'Cancelled'
    GROUP BY
        customer_id
),
current_month_customers AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(o.total_amount) AS total_spent
    FROM
        orders o
    WHERE
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= DATE_TRUNC('month', CURRENT_DATE)
        AND o.order_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    GROUP BY
        o.customer_id
)
SELECT
    CASE
        WHEN cfp.first_order_date >= DATE_TRUNC('month', CURRENT_DATE) THEN 'New Customer'
        ELSE 'Returning Customer'
    END AS customer_type,
    COUNT(DISTINCT cmc.customer_id) AS customer_count,
    ROUND(100.0 * COUNT(DISTINCT cmc.customer_id) / 
           SUM(COUNT(DISTINCT cmc.customer_id)) OVER (), 1) AS percentage,
    SUM(cmc.order_count) AS total_orders,
    ROUND(SUM(cmc.total_spent)::numeric, 2) AS total_revenue,
    ROUND((SUM(cmc.total_spent) / COUNT(DISTINCT cmc.customer_id))::numeric, 2) AS avg_revenue_per_customer,
    ROUND((SUM(cmc.order_count)::float / COUNT(DISTINCT cmc.customer_id))::numeric, 2) AS avg_orders_per_customer
FROM
    current_month_customers cmc
JOIN
    customer_first_purchase cfp ON cmc.customer_id = cfp.customer_id
GROUP BY
    customer_type
ORDER BY
    customer_type;
```

**SQL Query 3: Customer Purchase Frequency**
```sql
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS order_count,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date,
        SUM(total_amount) AS total_spent
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        customer_id
),
frequency_segments AS (
    SELECT
        customer_id,
        order_count,
        EXTRACT(DAY FROM (last_order_date - first_order_date)) AS days_between_first_last,
        total_spent,
        CASE
            WHEN order_count = 1 THEN 'One-time Buyers'
            WHEN order_count = 2 THEN 'Two-time Buyers'
            WHEN order_count = 3 THEN 'Three-time Buyers'
            WHEN order_count = 4 THEN '4-5 Orders'
            WHEN order_count BETWEEN 5 AND 10 THEN '5-10 Orders'
            ELSE '10+ Orders'
        END AS frequency_segment
    FROM
        customer_orders
)
SELECT
    frequency_segment,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage_of_customers,
    SUM(total_spent) AS total_revenue,
    ROUND(100.0 * SUM(total_spent) / SUM(SUM(total_spent)) OVER (), 1) AS percentage_of_revenue,
    ROUND((SUM(total_spent) / COUNT(*))::numeric, 2) AS avg_revenue_per_customer
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
        WHEN frequency_segment = '5-10 Orders' THEN 5
        ELSE 6
    END;
```

### Chart 2: Top Customer Analysis

**Purpose**: Identifies and analyzes your most valuable customers to understand their behavior and preferences.

**SQL Query 1: Top 20 Customers by Revenue**
```sql
WITH customer_stats AS (
    SELECT
        o.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.email,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(o.quantity) AS total_units_purchased,
        SUM(o.total_amount) AS total_spent,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date,
        COUNT(DISTINCT p.category) AS product_categories_purchased
    FROM
        orders o
    JOIN
        customers c ON o.customer_id = c.customer_id
    JOIN
        products p ON o.product_id = p.product_id
    WHERE
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        o.customer_id, c.first_name, c.last_name, c.email
)
SELECT
    customer_id,
    customer_name,
    email,
    order_count,
    total_units_purchased,
    ROUND(total_spent::numeric, 2) AS total_spent,
    first_order_date,
    last_order_date,
    EXTRACT(DAY FROM (CURRENT_DATE - last_order_date)) AS days_since_last_order,
    product_categories_purchased,
    ROUND((total_spent / order_count)::numeric, 2) AS average_order_value
FROM
    customer_stats
ORDER BY
    total_spent DESC
LIMIT 20;
```

**SQL Query 2: Top Customers' Preferred Categories**
```sql
WITH top_customers AS (
    SELECT
        customer_id
    FROM (
        SELECT
            customer_id,
            SUM(total_amount) AS total_spent
        FROM
            orders
        WHERE
            status != 'Cancelled' AND is_returned = FALSE
            AND order_date >= CURRENT_DATE - INTERVAL '1 year'
        GROUP BY
            customer_id
        ORDER BY
            total_spent DESC
        LIMIT 100
    ) t
),
category_preferences AS (
    SELECT
        o.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        p.category,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(o.quantity) AS units_purchased,
        SUM(o.total_amount) AS category_spent
    FROM
        orders o
    JOIN
        customers c ON o.customer_id = c.customer_id
    JOIN
        products p ON o.product_id = p.product_id
    WHERE
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '1 year'
        AND o.customer_id IN (SELECT customer_id FROM top_customers)
    GROUP BY
        o.customer_id, c.first_name, c.last_name, p.category
)
SELECT
    customer_id,
    customer_name,
    category,
    order_count,
    units_purchased,
    ROUND(category_spent::numeric, 2) AS category_spent,
    ROUND(100.0 * category_spent / SUM(category_spent) OVER (PARTITION BY customer_id), 1) AS percentage_of_customer_spend
FROM
    category_preferences
ORDER BY
    customer_id, category_spent DESC;
```

**SQL Query 3: Top Customers by Frequency**
```sql
WITH customer_stats AS (
    SELECT
        o.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.email,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(o.quantity) AS total_units_purchased,
        SUM(o.total_amount) AS total_spent,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date,
        EXTRACT(DAY FROM (MAX(o.order_date) - MIN(o.order_date))) AS days_between_first_last,
        CASE
            WHEN COUNT(DISTINCT o.order_id) <= 1 THEN 0
            ELSE EXTRACT(DAY FROM (MAX(o.order_date) - MIN(o.order_date))) / (COUNT(DISTINCT o.order_id) - 1)
        END AS avg_days_between_orders
    FROM
        orders o
    JOIN
        customers c ON o.customer_id = c.customer_id
    WHERE
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY
        o.customer_id, c.first_name, c.last_name, c.email
    HAVING
        COUNT(DISTINCT o.order_id) >= 3
)
SELECT
    customer_id,
    customer_name,
    email,
    order_count,
    ROUND(total_spent::numeric, 2) AS total_spent,
    first_order_date,
    last_order_date,
    EXTRACT(DAY FROM (CURRENT_DATE - last_order_date)) AS days_since_last_order,
    ROUND(avg_days_between_orders::numeric, 1) AS avg_days_between_orders,
    ROUND((total_spent / order_count)::numeric, 2) AS average_order_value
FROM
    customer_stats
ORDER BY
    order_count DESC, avg_days_between_orders ASC
LIMIT 20;
```

### Chart 3: Customer Retention Analysis

**Purpose**: Analyzes customer retention patterns to identify opportunities for improving customer loyalty and lifetime value.

**SQL Query 1: Monthly Cohort Retention**
```sql
WITH first_purchases AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM
        orders
    WHERE
        status != 'Cancelled'
    GROUP BY
        customer_id
),
monthly_activity AS (
    SELECT
        fp.customer_id,
        fp.cohort_month,
        DATE_TRUNC('month', o.order_date) AS activity_month,
        (EXTRACT(YEAR FROM DATE_TRUNC('month', o.order_date)) - 
         EXTRACT(YEAR FROM fp.cohort_month)) * 12 +
        (EXTRACT(MONTH FROM DATE_TRUNC('month', o.order_date)) - 
         EXTRACT(MONTH FROM fp.cohort_month)) AS month_number
    FROM
        first_purchases fp
    JOIN
        orders o ON fp.customer_id = o.customer_id
    WHERE
        o.status != 'Cancelled'
        AND fp.cohort_month >= CURRENT_DATE - INTERVAL '12 months'
        AND fp.cohort_month < CURRENT_DATE - INTERVAL '1 month'  -- Exclude current month as it's incomplete
    GROUP BY
        fp.customer_id, fp.cohort_month, activity_month
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM
        first_purchases
    WHERE
        cohort_month >= CURRENT_DATE - INTERVAL '12 months'
        AND cohort_month < CURRENT_DATE - INTERVAL '1 month'  -- Exclude current month as it's incomplete
    GROUP BY
        cohort_month
),
retention_table AS (
    SELECT
        ma.cohort_month,
        ma.month_number,
        COUNT(DISTINCT ma.customer_id) AS active_customers
    FROM
        monthly_activity ma
    GROUP BY
        ma.cohort_month, ma.month_number
)
SELECT
    TO_CHAR(rt.cohort_month, 'YYYY-MM') AS cohort,
    cs.cohort_size,
    rt.month_number,
    rt.active_customers,
    ROUND(100.0 * rt.active_customers / cs.cohort_size, 1) AS retention_rate
FROM
    retention_table rt
JOIN
    cohort_sizes cs ON rt.cohort_month = cs.cohort_month
WHERE
    rt.month_number <= 11  -- Only show up to 11 months of retention
ORDER BY
    rt.cohort_month, rt.month_number;
```

**SQL Query 2: Customer Recency Analysis**
```sql
WITH recent_purchases AS (
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(total_amount) AS total_spent
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
    GROUP BY
        customer_id
),
recency_segments AS (
    SELECT
        customer_id,
        EXTRACT(DAY FROM (CURRENT_DATE - last_order_date)) AS days_since_last_order,
        order_count,
        total_spent,
        CASE
            WHEN EXTRACT(DAY FROM (CURRENT_DATE - last_order_date)) <= 30 THEN 'Active (0-30 days)'
            WHEN EXTRACT(DAY FROM (CURRENT_DATE - last_order_date)) <= 90 THEN 'Recent (31-90 days)'
            WHEN EXTRACT(DAY FROM (CURRENT_DATE - last_order_date)) <= 180 THEN 'Slipping (91-180 days)'
            WHEN EXTRACT(DAY FROM (CURRENT_DATE - last_order_date)) <= 365 THEN 'At Risk (181-365 days)'
            ELSE 'Inactive (>365 days)'
        END AS recency_segment
    FROM
        recent_purchases
)
SELECT
    recency_segment,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage_of_customers,
    SUM(order_count) AS total_orders,
    ROUND(SUM(total_spent)::numeric, 2) AS total_spent,
    ROUND((SUM(total_spent) / COUNT(*))::numeric, 2) AS avg_customer_value,
    ROUND((SUM(order_count)::float / COUNT(*))::numeric, 2) AS avg_orders_per_customer
FROM
    recency_segments
GROUP BY
    recency_segment
ORDER BY
    CASE
        WHEN recency_segment = 'Active (0-30 days)' THEN 1
        WHEN recency_segment = 'Recent (31-90 days)' THEN 2
        WHEN recency_segment = 'Slipping (91-180 days)' THEN 3
        WHEN recency_segment = 'At Risk (181-365 days)' THEN 4
        ELSE 5
    END;
```

**SQL Query 3: Repeat Purchase Rate by Month**
```sql
WITH monthly_customers AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        customer_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY
        month, customer_id
),
monthly_stats AS (
    SELECT
        month,
        COUNT(DISTINCT customer_id) AS total_customers,
        COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_id ELSE NULL END) AS customers_with_multiple_orders,
        SUM(order_count) AS total_orders
    FROM
        monthly_customers
    GROUP BY
        month
)
SELECT
    TO_CHAR(month, 'YYYY-MM') AS month,
    total_customers,
    customers_with_multiple_orders,
    total_orders,
    ROUND(100.0 * customers_with_multiple_orders / NULLIF(total_customers, 0), 1) AS repeat_purchase_rate,
    ROUND((total_orders::float / total_customers)::numeric, 2) AS orders_per_customer
FROM
    monthly_stats
ORDER BY
    month;
```

## YouTube Script: Understanding Customer Metrics

Hey everyone! Today we're diving into Customer Metrics - the key numbers that help you understand who's buying your products, how often they come back, and what they're worth to your business.

Let's start with our Customer Activity Overview. The first query provides a summary of customer behavior across different time periods - the current month, previous month, and last 90 days. This gives you both immediate and trending perspectives on your customer base.

What makes this query particularly useful is that it doesn't just count customers and orders, but calculates relationship metrics like orders per customer, revenue per customer, and average order value. These numbers tell you how engaged your customers are and how much value each relationship generates.

The second query breaks down your current month's customers into new versus returning segments. This is crucial for understanding the balance between customer acquisition and retention in your business. Are you growing primarily by attracting new customers, or by generating repeat business from existing ones? Both strategies can work, but they require different marketing approaches and have different implications for long-term growth.

The third query in this section analyzes customer purchase frequency over the past year. It segments customers based on how many times they've ordered - from one-time buyers to your most frequent shoppers. What's fascinating about this analysis is seeing how revenue distribution often differs from customer distribution. For example, you might find that customers making 5+ purchases represent only 10% of your customer base but generate 40% of your revenue.

Moving to our second chart, Top Customer Analysis helps you understand your most valuable customers. The first query simply identifies your top 20 customers by revenue. But it goes beyond just ranking them - it provides context around their behavior, including how many orders they've placed, when they first ordered, when they last ordered, and what categories they buy from. This rich profile helps you understand what makes these high-value customers tick.

The second query examines the category preferences of your top customers. This is particularly valuable because it reveals if your best customers have different purchasing patterns than your average customers. Maybe your overall best-selling category is Electronics, but your top customers disproportionately buy from your Premium Accessories category. This insight could influence how you market to high-value prospects.

The third query identifies your most frequent purchasers - customers who order most often. These aren't necessarily your highest-spending customers (though there's often overlap), but they're highly engaged with your brand. The query also calculates the average days between orders, helping you understand their purchasing rhythm. This can inform everything from email marketing frequency to inventory planning.

Our final chart focuses on Customer Retention Analysis. The first query builds a cohort retention table, showing how many customers from each monthly cohort continue to make purchases in subsequent months. This is one of the most powerful analyses for understanding customer lifetime value and business sustainability. Improving your month-3 retention rate by just a few percentage points can have a massive impact on long-term business growth.

The second query segments customers by recency - how recently they've made a purchase. This creates actionable customer groups ranging from "Active" (ordered in the last 30 days) to "Inactive" (no orders in over a year). Each of these segments requires a different re-engagement strategy, and this query helps you size and prioritize those opportunities.

The third query tracks your repeat purchase rate by month - what percentage of customers in each month made multiple purchases. This is a key indicator of customer satisfaction and product-market fit. A high repeat purchase rate suggests customers are finding consistent value in your offerings, while a declining rate might signal emerging competition or product issues.

What makes these customer metrics so valuable is that they shift your focus from products to people. They remind you that behind every transaction is a customer relationship with potential long-term value. A single transaction might be worth $50, but a satisfied customer who orders monthly could be worth thousands over their lifetime.

These metrics also help you balance your marketing investments between acquisition and retention. Finding new customers is important but often expensive. The insights from these queries help you identify opportunities to generate more value from your existing customer base, which is typically more cost-effective.

Remember that these metrics are most powerful when tracked over time, allowing you to identify trends and measure the impact of customer experience initiatives. A sudden drop in repeat purchase rate or average order value might signal a problem requiring immediate attention, while improvements in these metrics validate your customer-focused strategies.

In our next videos, we'll combine insights from all our dashboard components to show how product, inventory, sales, and customer data work together to drive holistic business decision-making. See you then!
