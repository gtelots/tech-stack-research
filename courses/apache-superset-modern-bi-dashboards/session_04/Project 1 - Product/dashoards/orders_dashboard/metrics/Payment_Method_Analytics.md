# Payment Method Analytics

## Business Context
Payment Method Analytics provide insights into how customers prefer to pay and how different payment options affect your business. These metrics help optimize your payment strategy to maximize conversion rates, minimize processing costs, and enhance the customer experience.

## Dashboard Charts

### Chart 1: Payment Method Distribution

**Purpose**: Analyzes which payment methods customers prefer, helping to ensure you offer the right mix of payment options for your target market.

**SQL Query 1: Orders by Payment Method**
```sql
SELECT
    payment_method,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percentage_of_orders,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(100.0 * SUM(total_amount) / SUM(SUM(total_amount)) OVER (), 1) AS percentage_of_revenue,
    ROUND((SUM(total_amount) / COUNT(*))::numeric, 2) AS average_order_value
FROM
    orders
WHERE
    status != 'Cancelled' AND is_returned = FALSE
    AND order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
    payment_method
ORDER BY
    order_count DESC;
```

**SQL Query 2: Payment Method Trends**
```sql
WITH monthly_payment_methods AS (
    SELECT
        DATE_TRUNC('month', order_date)::date AS month,
        payment_method,
        COUNT(*) AS order_count,
        SUM(total_amount) AS total_revenue
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY
        month, payment_method
),
monthly_totals AS (
    SELECT
        month,
        SUM(order_count) AS total_orders,
        SUM(total_revenue) AS total_revenue
    FROM
        monthly_payment_methods
    GROUP BY
        month
)
SELECT
    mpm.month,
    mpm.payment_method,
    mpm.order_count,
    ROUND(100.0 * mpm.order_count / mt.total_orders, 1) AS percentage_of_orders,
    ROUND(mpm.total_revenue::numeric, 2) AS total_revenue,
    ROUND(100.0 * mpm.total_revenue / mt.total_revenue, 1) AS percentage_of_revenue
FROM
    monthly_payment_methods mpm
JOIN
    monthly_totals mt ON mpm.month = mt.month
ORDER BY
    mpm.month, mpm.order_count DESC;
```

**SQL Query 3: Payment Method by Order Value Range**
```sql
WITH order_value_ranges AS (
    SELECT
        order_id,
        payment_method,
        CASE
            WHEN total_amount < 50 THEN 'Under $50'
            WHEN total_amount >= 50 AND total_amount < 100 THEN '$50-$99.99'
            WHEN total_amount >= 100 AND total_amount < 200 THEN '$100-$199.99'
            WHEN total_amount >= 200 AND total_amount < 500 THEN '$200-$499.99'
            ELSE '$500+'
        END AS order_value_range
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= CURRENT_DATE - INTERVAL '90 days'
),
range_totals AS (
    SELECT
        order_value_range,
        COUNT(*) AS total_range_orders
    FROM
        order_value_ranges
    GROUP BY
        order_value_range
)
SELECT
    ovr.order_value_range,
    ovr.payment_method,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / rt.total_range_orders, 1) AS percentage_of_range
FROM
    order_value_ranges ovr
JOIN
    range_totals rt ON ovr.order_value_range = rt.order_value_range
GROUP BY
    ovr.order_value_range, ovr.payment_method, rt.total_range_orders
ORDER BY
    CASE
        WHEN ovr.order_value_range = 'Under $50' THEN 1
        WHEN ovr.order_value_range = '$50-$99.99' THEN 2
        WHEN ovr.order_value_range = '$100-$199.99' THEN 3
        WHEN ovr.order_value_range = '$200-$499.99' THEN 4
        ELSE 5
    END,
    order_count DESC;
```

### Chart 2: Payment Performance Metrics

**Purpose**: Evaluates how different payment methods affect key business metrics like conversion rates, authorization rates, and processing costs.

**SQL Query 1: Payment Method Success Rates**
```sql
-- Note: This query would typically require data from your payment processor
-- The following is a theoretical query showing what would be useful

WITH payment_attempts AS (
    SELECT
        payment_method,
        COUNT(*) AS attempt_count,
        COUNT(*) FILTER (WHERE payment_status = 'successful') AS successful_count,
        COUNT(*) FILTER (WHERE payment_status = 'failed' AND failure_reason = 'declined') AS declined_count,
        COUNT(*) FILTER (WHERE payment_status = 'failed' AND failure_reason = 'error') AS error_count,
        COUNT(*) FILTER (WHERE payment_status = 'abandoned') AS abandoned_count
    FROM
        payment_transactions
    WHERE
        transaction_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY
        payment_method
)
SELECT
    payment_method,
    attempt_count,
    successful_count,
    ROUND(100.0 * successful_count / NULLIF(attempt_count, 0), 1) AS success_rate,
    declined_count,
    ROUND(100.0 * declined_count / NULLIF(attempt_count, 0), 1) AS decline_rate,
    error_count,
    ROUND(100.0 * error_count / NULLIF(attempt_count, 0), 1) AS error_rate,
    abandoned_count,
    ROUND(100.0 * abandoned_count / NULLIF(attempt_count, 0), 1) AS abandonment_rate
FROM
    payment_attempts
ORDER BY
    attempt_count DESC;

-- Alternative query using just orders data
SELECT
    payment_method,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE status != 'Cancelled') AS completed_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE status != 'Cancelled') / NULLIF(COUNT(*), 0), 1) AS completion_rate,
    COUNT(*) FILTER (WHERE status = 'Cancelled') AS cancelled_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'Cancelled') / NULLIF(COUNT(*), 0), 1) AS cancellation_rate
FROM
    orders
WHERE
    order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
    payment_method
ORDER BY
    total_orders DESC;
```

**SQL Query 2: Average Processing Time by Payment Method**
```sql
-- Note: This query would typically require detailed payment processing timestamps
-- The following is a theoretical query showing what would be useful

SELECT
    payment_method,
    COUNT(*) AS transaction_count,
    ROUND(AVG(EXTRACT(EPOCH FROM (payment_confirmed_at - payment_initiated_at)))::numeric, 2) AS avg_processing_seconds,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (payment_confirmed_at - payment_initiated_at)))::numeric, 2) AS median_processing_seconds,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (payment_confirmed_at - payment_initiated_at)))::numeric, 2) AS p95_processing_seconds
FROM
    payment_transactions
WHERE
    payment_status = 'successful'
    AND transaction_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
    payment_method
ORDER BY
    avg_processing_seconds;

-- Alternative query using order timestamps
SELECT
    payment_method,
    COUNT(*) AS order_count,
    ROUND(AVG(EXTRACT(EPOCH FROM (created_at - order_date)))::numeric, 2) AS avg_order_processing_seconds
FROM
    orders
WHERE
    status != 'Cancelled'
    AND order_date >= CURRENT_DATE - INTERVAL '30 days'
    AND created_at > order_date
GROUP BY
    payment_method
ORDER BY
    avg_order_processing_seconds;
```

**SQL Query 3: Payment Processing Costs**
```sql
-- Note: This query would typically require payment fee data
-- The following is a theoretical query showing what would be useful

WITH payment_costs AS (
    SELECT
        payment_method,
        -- Different payment methods typically have different fee structures
        CASE
            WHEN payment_method = 'Credit Card' THEN 0.029 * total_amount + 0.30  -- 2.9% + $0.30
            WHEN payment_method = 'PayPal' THEN 0.034 * total_amount + 0.30        -- 3.4% + $0.30
            WHEN payment_method = 'Bank Transfer' THEN 1.50                       -- Flat $1.50
            WHEN payment_method = 'Cash on Delivery' THEN 5.00                    -- Flat $5.00
            WHEN payment_method = 'Gift Card' THEN 0                              -- No fee
            ELSE 0.03 * total_amount                                            -- Default 3%
        END AS processing_fee,
        total_amount
    FROM
        orders
    WHERE
        status != 'Cancelled' AND is_returned = FALSE
        AND order_date >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT
    payment_method,
    COUNT(*) AS order_count,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(SUM(processing_fee)::numeric, 2) AS total_processing_fees,
    ROUND(100.0 * SUM(processing_fee) / NULLIF(SUM(total_amount), 0), 2) AS effective_fee_percentage,
    ROUND((SUM(processing_fee) / COUNT(*))::numeric, 2) AS average_fee_per_order
FROM
    payment_costs
GROUP BY
    payment_method
ORDER BY
    effective_fee_percentage;
```

### Chart 3: Customer Payment Preferences

**Purpose**: Examines how different customer segments prefer to pay, helping tailor payment options to specific target markets.

**SQL Query 1: Payment Method by Customer Segment**
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
        AND order_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY
        customer_id
),
customer_segments AS (
    SELECT
        customer_id,
        CASE
            WHEN order_count = 1 THEN 'One-time Customers'
            WHEN order_count BETWEEN 2 AND 3 THEN 'Occasional Customers'
            WHEN order_count BETWEEN 4 AND 6 THEN 'Regular Customers'
            ELSE 'Loyal Customers'
        END AS customer_segment
    FROM
        customer_orders
)
SELECT
    cs.customer_segment,
    o.payment_method,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY cs.customer_segment), 1) AS percentage_of_segment_orders,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue,
    ROUND(100.0 * SUM(o.total_amount) / SUM(SUM(o.total_amount)) OVER (PARTITION BY cs.customer_segment), 1) AS percentage_of_segment_revenue
FROM
    orders o
JOIN
    customer_segments cs ON o.customer_id = cs.customer_id
WHERE
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY
    cs.customer_segment, o.payment_method
ORDER BY
    CASE
        WHEN cs.customer_segment = 'One-time Customers' THEN 1
        WHEN cs.customer_segment = 'Occasional Customers' THEN 2
        WHEN cs.customer_segment = 'Regular Customers' THEN 3
        ELSE 4
    END,
    order_count DESC;
```

**SQL Query 2: Payment Method by Customer Geography**
```sql
SELECT
    c.country,
    o.payment_method,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY c.country), 1) AS percentage_of_country_orders,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue
FROM
    orders o
JOIN
    customers c ON o.customer_id = c.customer_id
WHERE
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY
    c.country, o.payment_method
HAVING
    COUNT(*) >= 10  -- Minimum threshold for statistical relevance
ORDER BY
    c.country, order_count DESC;
```

**SQL Query 3: Customer Payment Method Switching**
```sql
WITH customer_payment_history AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        payment_method,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_sequence
    FROM
        orders
    WHERE
        status != 'Cancelled'
        AND order_date >= CURRENT_DATE - INTERVAL '12 months'
),
customer_first_payment AS (
    SELECT
        customer_id,
        payment_method AS first_payment_method
    FROM
        customer_payment_history
    WHERE
        order_sequence = 1
),
payment_switches AS (
    SELECT
        cph.customer_id,
        COUNT(DISTINCT cph.order_id) AS total_orders,
        COUNT(DISTINCT cph.payment_method) AS payment_methods_used,
        SUM(CASE 
                WHEN LAG(cph.payment_method) OVER (PARTITION BY cph.customer_id ORDER BY cph.order_date) 
                     IS DISTINCT FROM cph.payment_method 
                THEN 1 
                ELSE 0 
            END) AS payment_switches
    FROM
        customer_payment_history cph
    GROUP BY
        cph.customer_id
)
SELECT
    AVG(payment_methods_used) AS avg_payment_methods_per_customer,
    ROUND(100.0 * COUNT(*) FILTER (WHERE payment_methods_used > 1) / COUNT(*), 1) AS percentage_using_multiple_methods,
    ROUND(100.0 * SUM(payment_switches) / SUM(GREATEST(total_orders - 1, 0)), 1) AS payment_method_switch_rate,
    COUNT(*) AS total_customers
FROM
    payment_switches
WHERE
    total_orders > 1;  -- Only include customers with at least 2 orders
```

## YouTube Script: Understanding Payment Method Analytics

Hey everyone! Today we're exploring Payment Method Analytics - metrics that help you understand how customers prefer to pay and how different payment options affect your business. These insights might not be the first things you think about when analyzing your business, but they can have a surprising impact on conversion rates, average order values, and processing costs.

Let's start with Payment Method Distribution. The first query gives you a clear picture of which payment methods your customers prefer. This is fundamental information for optimizing your checkout process - you want to prominently feature the most popular payment options while ensuring you offer enough variety to meet different customer preferences.

What makes this query particularly useful is that it shows not just the percentage of orders but also the percentage of revenue for each payment method. Often, these numbers differ significantly - for example, credit cards might account for 60% of orders but 70% of revenue, indicating higher average order values when customers use this payment method.

The second query tracks payment method trends over time. This helps you identify shifts in customer payment preferences, which can happen for various reasons - changing demographics in your customer base, the introduction of new payment technologies, or even macroeconomic factors affecting consumer behavior. By monitoring these trends, you can adjust your payment strategy proactively.

The third query examines payment method preferences across different order value ranges. This often reveals fascinating patterns - perhaps customers tend to use PayPal for smaller purchases but prefer credit cards for larger ones. Or maybe alternative payment methods are more popular for certain price brackets. These insights can help you optimize your checkout flow based on cart value.

Moving to our Payment Performance Metrics, the first query would ideally analyze success rates for different payment methods. While we've provided a theoretical query based on payment processor data, we've also included an alternative that uses just orders data to compare completion versus cancellation rates by payment method. Either way, the goal is to identify payment options that might be causing friction in the checkout process.

The second query looks at processing times by payment method. Transaction speed matters - slower payment processing can lead to abandoned carts and frustrated customers. While the ideal query would use detailed payment timestamps, even the alternative using order creation times can provide insight into which payment methods might be introducing delays in your order process.

The third query analyzes processing costs across payment methods. Different payment options come with different fee structures - from percentage-based fees for credit cards to flat fees for bank transfers. Understanding these costs helps you balance customer preferences against your profit margins. You might even consider incentivizing customers to use lower-cost payment methods for certain order types.

Our final chart focuses on Customer Payment Preferences across different segments. The first query examines how payment preferences vary between one-time customers, occasional customers, regular customers, and loyal customers. These differences can be striking - new customers might gravitate toward PayPal for its buyer protection, while loyal customers might prefer the convenience of saved credit cards.

The second query looks at payment preferences by geography. This is crucial for international businesses, as payment preferences vary dramatically by country. Credit cards might dominate in the US, while bank transfers are more common in Germany, and digital wallets lead in China. Understanding these regional differences helps you offer the right payment mix for each market you serve.

The third query analyzes customer payment method switching behavior. It calculates what percentage of customers use multiple payment methods and how often they switch between methods. A high switching rate might indicate that customers are experiencing issues with certain payment types or that they're carefully optimizing which payment method to use for different purchase types.

What makes payment method analytics so valuable is their direct impact on both customer experience and your bottom line. The right payment options can reduce cart abandonment, increase conversion rates, and even drive higher average order values. Meanwhile, optimizing for lower-cost payment methods can significantly impact your profit margins, especially for businesses with thin margins.

These metrics also help you identify opportunities for improvement in your checkout process. If a particular payment method has a high abandonment rate or unusually low average order values, that's a sign that something might be causing friction for customers using that method.

Remember that payment preferences evolve over time as new technologies emerge and consumer habits change. By regularly monitoring these metrics, you can ensure your payment strategy remains aligned with customer preferences while optimizing for business performance.

This completes our tour of the Orders Dashboard simple metrics. In our next series, we'll dive into more detailed analytics that provide deeper insights into order patterns, processing efficiency, and optimization opportunities. See you then!
