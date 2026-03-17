# Product Return Analysis

## Business Context
Product returns represent both a direct cost to the business and a potential indicator of product quality issues or customer expectation mismatches. This analysis helps identify products with concerning return rates, understand why customers are returning items, and develop strategies to address the root causes.

## Dashboard Charts

### Chart 1: Return Rate by Product

**Purpose**: Identifies products with the highest return rates to highlight potential quality issues or mismatched customer expectations.

**SQL Query 1: Top Products by Return Rate**
```sql
WITH product_orders AS (
    SELECT 
        p.product_id,
        p.name,
        p.category,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.quantity) AS total_units_sold,
        COUNT(DISTINCT CASE WHEN o.is_returned = TRUE THEN o.order_id ELSE NULL END) AS returned_orders,
        SUM(CASE WHEN o.is_returned = TRUE THEN o.quantity ELSE 0 END) AS returned_units
    FROM 
        products p
    JOIN 
        orders o ON p.product_id = o.product_id
    WHERE 
        o.status != 'Cancelled'
        AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        p.product_id, p.name, p.category
    HAVING 
        COUNT(DISTINCT o.order_id) >= 10  -- Minimum threshold for statistical relevance
)
SELECT 
    product_id,
    name,
    category,
    total_orders,
    total_units_sold,
    returned_orders,
    returned_units,
    ROUND(100.0 * returned_orders / NULLIF(total_orders, 0), 2) AS order_return_rate_percent,
    ROUND(100.0 * returned_units / NULLIF(total_units_sold, 0), 2) AS unit_return_rate_percent
FROM 
    product_orders
ORDER BY 
    unit_return_rate_percent DESC, total_units_sold DESC
LIMIT 20;
```

**SQL Query 2: Return Rate by Price Range**
```sql
WITH price_ranges AS (
    SELECT
        product_id,
        CASE
            WHEN price < 25 THEN 'Under $25'
            WHEN price >= 25 AND price < 50 THEN '$25-$49.99'
            WHEN price >= 50 AND price < 100 THEN '$50-$99.99'
            WHEN price >= 100 AND price < 200 THEN '$100-$199.99'
            ELSE '$200+'
        END AS price_range
    FROM products
),
price_range_order AS (
    -- This ensures consistent ordering
    SELECT 'Under $25' AS price_range, 1 AS sort_order
    UNION SELECT '$25-$49.99', 2
    UNION SELECT '$50-$99.99', 3
    UNION SELECT '$100-$199.99', 4
    UNION SELECT '$200+', 5
)
SELECT 
    pro.price_range,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.quantity) AS total_units_sold,
    COUNT(DISTINCT CASE WHEN o.is_returned = TRUE THEN o.order_id ELSE NULL END) AS returned_orders,
    SUM(CASE WHEN o.is_returned = TRUE THEN o.quantity ELSE 0 END) AS returned_units,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.is_returned = TRUE THEN o.order_id ELSE NULL END) / 
          NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS order_return_rate_percent,
    ROUND(100.0 * SUM(CASE WHEN o.is_returned = TRUE THEN o.quantity ELSE 0 END) / 
          NULLIF(SUM(o.quantity), 0), 2) AS unit_return_rate_percent
FROM 
    orders o
JOIN 
    price_ranges pr ON o.product_id = pr.product_id
JOIN
    price_range_order pro ON pr.price_range = pro.price_range
WHERE 
    o.status != 'Cancelled'
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    pro.price_range, pro.sort_order
ORDER BY 
    pro.sort_order;
```

**SQL Query 3: Return Rate Trend Over Time**
```sql
SELECT 
    DATE_TRUNC('month', o.order_date) AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN o.is_returned = TRUE THEN o.order_id ELSE NULL END) AS returned_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.is_returned = TRUE THEN o.order_id ELSE NULL END) / 
          NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS return_rate_percent,
    -- Average days to return
    AVG(
        CASE 
            WHEN o.is_returned = TRUE AND o.return_date IS NOT NULL AND o.delivery_date IS NOT NULL 
            THEN EXTRACT(EPOCH FROM (o.return_date - o.delivery_date)) / 86400 
            ELSE NULL 
        END
    ) AS avg_days_to_return
FROM 
    orders o
WHERE 
    o.status != 'Cancelled'
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    month
ORDER BY 
    month;
```

### Chart 2: Return Reasons Analysis

**Purpose**: Examines the most common reasons for returns to identify recurring issues and improvement opportunities.

**SQL Query 1: Top Return Reasons Overall**
```sql
SELECT 
    return_reason,
    COUNT(DISTINCT order_id) AS number_of_returns,
    ROUND(100.0 * COUNT(DISTINCT order_id) / (
        SELECT COUNT(DISTINCT order_id) FROM orders 
        WHERE is_returned = TRUE AND return_reason IS NOT NULL
        AND order_date >= CURRENT_DATE - INTERVAL '12 months'
    ), 2) AS percentage_of_returns,
    SUM(total_amount) AS total_returned_value
FROM 
    orders
WHERE 
    is_returned = TRUE
    AND return_reason IS NOT NULL
    AND order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    return_reason
ORDER BY 
    number_of_returns DESC;
```

**SQL Query 2: Return Reasons by Category**
```sql
WITH category_returns AS (
    SELECT 
        p.category,
        o.return_reason,
        COUNT(DISTINCT o.order_id) AS number_of_returns
    FROM 
        orders o
    JOIN 
        products p ON o.product_id = p.product_id
    WHERE 
        o.is_returned = TRUE
        AND o.return_reason IS NOT NULL
        AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        p.category, o.return_reason
),
category_totals AS (
    SELECT 
        category,
        SUM(number_of_returns) AS total_category_returns
    FROM 
        category_returns
    GROUP BY 
        category
)
SELECT 
    cr.category,
    cr.return_reason,
    cr.number_of_returns,
    ROUND(100.0 * cr.number_of_returns / ct.total_category_returns, 2) AS percentage_of_category_returns
FROM 
    category_returns cr
JOIN 
    category_totals ct ON cr.category = ct.category
ORDER BY 
    cr.category, cr.number_of_returns DESC;
```

**SQL Query 3: Return Reasons by Price Range**
```sql
WITH price_range_returns AS (
    SELECT 
        CASE
            WHEN p.price < 25 THEN 'Under $25'
            WHEN p.price >= 25 AND p.price < 50 THEN '$25-$49.99'
            WHEN p.price >= 50 AND p.price < 100 THEN '$50-$99.99'
            WHEN p.price >= 100 AND p.price < 200 THEN '$100-$199.99'
            ELSE '$200+'
        END AS price_range,
        o.return_reason,
        COUNT(DISTINCT o.order_id) AS number_of_returns
    FROM 
        orders o
    JOIN 
        products p ON o.product_id = p.product_id
    WHERE 
        o.is_returned = TRUE
        AND o.return_reason IS NOT NULL
        AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        price_range, o.return_reason
),
price_range_order AS (
    -- This ensures consistent ordering
    SELECT 'Under $25' AS price_range, 1 AS sort_order
    UNION SELECT '$25-$49.99', 2
    UNION SELECT '$50-$99.99', 3
    UNION SELECT '$100-$199.99', 4
    UNION SELECT '$200+', 5
),
price_range_totals AS (
    SELECT 
        prr.price_range,
        SUM(prr.number_of_returns) AS total_range_returns
    FROM 
        price_range_returns prr
    GROUP BY 
        prr.price_range
)
SELECT 
    pro.price_range,
    prr.return_reason,
    prr.number_of_returns,
    ROUND(100.0 * prr.number_of_returns / prt.total_range_returns, 2) AS percentage_of_range_returns
FROM 
    price_range_returns prr
JOIN 
    price_range_totals prt ON prr.price_range = prt.price_range
JOIN
    price_range_order pro ON prr.price_range = pro.price_range
ORDER BY 
    pro.sort_order, prr.number_of_returns DESC;
```

### Chart 3: Return Impact Analysis

**Purpose**: Quantifies the financial and operational impact of returns, helping prioritize improvement initiatives based on business impact.

**SQL Query 1: Financial Impact of Returns by Category**
```sql
SELECT 
    p.category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN o.is_returned = TRUE THEN o.order_id ELSE NULL END) AS returned_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.is_returned = TRUE THEN o.order_id ELSE NULL END) / 
          NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS return_rate_percent,
    SUM(CASE WHEN o.is_returned = TRUE THEN o.total_amount ELSE 0 END) AS returned_revenue,
    -- Estimated return processing cost (assuming $10 per return)
    COUNT(DISTINCT CASE WHEN o.is_returned = TRUE THEN o.order_id ELSE NULL END) * 10 AS estimated_processing_cost,
    -- Total financial impact
    SUM(CASE WHEN o.is_returned = TRUE THEN o.total_amount ELSE 0 END) + 
    (COUNT(DISTINCT CASE WHEN o.is_returned = TRUE THEN o.order_id ELSE NULL END) * 10) AS total_financial_impact
FROM 
    orders o
JOIN 
    products p ON o.product_id = p.product_id
WHERE 
    o.status != 'Cancelled'
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    p.category
ORDER BY 
    total_financial_impact DESC;
```

**SQL Query 2: Return Timing Analysis**
```sql
SELECT 
    p.category,
    AVG(
        CASE 
            WHEN o.is_returned = TRUE AND o.return_date IS NOT NULL AND o.delivery_date IS NOT NULL 
            THEN EXTRACT(EPOCH FROM (o.return_date - o.delivery_date)) / 86400 
            ELSE NULL 
        END
    ) AS avg_days_to_return,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY (
            CASE 
                WHEN o.is_returned = TRUE AND o.return_date IS NOT NULL AND o.delivery_date IS NOT NULL 
                THEN EXTRACT(EPOCH FROM (o.return_date - o.delivery_date)) / 86400 
                ELSE NULL 
            END
        )
    ) AS median_days_to_return,
    MIN(
        CASE 
            WHEN o.is_returned = TRUE AND o.return_date IS NOT NULL AND o.delivery_date IS NOT NULL 
            THEN EXTRACT(EPOCH FROM (o.return_date - o.delivery_date)) / 86400 
            ELSE NULL 
        END
    ) AS min_days_to_return,
    MAX(
        CASE 
            WHEN o.is_returned = TRUE AND o.return_date IS NOT NULL AND o.delivery_date IS NOT NULL 
            THEN EXTRACT(EPOCH FROM (o.return_date - o.delivery_date)) / 86400 
            ELSE NULL 
        END
    ) AS max_days_to_return,
    COUNT(DISTINCT CASE WHEN o.is_returned = TRUE THEN o.order_id ELSE NULL END) AS number_of_returns
FROM 
    orders o
JOIN 
    products p ON o.product_id = p.product_id
WHERE 
    o.is_returned = TRUE
    AND o.return_date IS NOT NULL
    AND o.delivery_date IS NOT NULL
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    p.category
ORDER BY 
    number_of_returns DESC;
```

**SQL Query 3: Customer Repeat Purchase After Return Analysis**
```sql
WITH customer_returns AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_return_date
    FROM 
        orders
    WHERE 
        is_returned = TRUE
        AND order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        customer_id
),
post_return_purchases AS (
    SELECT 
        cr.customer_id,
        COUNT(DISTINCT o.order_id) AS orders_after_return,
        SUM(o.total_amount) AS spent_after_return
    FROM 
        customer_returns cr
    JOIN 
        orders o ON cr.customer_id = o.customer_id
               AND o.order_date > cr.first_return_date
               AND o.status != 'Cancelled'
               AND o.is_returned = FALSE
    GROUP BY 
        cr.customer_id
)
SELECT 
    COUNT(DISTINCT cr.customer_id) AS customers_with_returns,
    COUNT(DISTINCT CASE WHEN prp.orders_after_return > 0 THEN cr.customer_id ELSE NULL END) AS customers_who_purchased_again,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN prp.orders_after_return > 0 THEN cr.customer_id ELSE NULL END) / 
          NULLIF(COUNT(DISTINCT cr.customer_id), 0), 2) AS retention_rate_percent,
    ROUND(AVG(COALESCE(prp.orders_after_return, 0))::numeric, 2) AS avg_orders_after_return,
    ROUND(AVG(COALESCE(prp.spent_after_return, 0))::numeric, 2) AS avg_spent_after_return
FROM 
    customer_returns cr
LEFT JOIN 
    post_return_purchases prp ON cr.customer_id = prp.customer_id;
```

## YouTube Script: Mastering Product Return Analysis

Hey everyone! Welcome back to our product dashboard series. Today we're diving into a topic that might not be the most exciting but is absolutely critical for retail success: Product Return Analysis. Returns might seem like just a cost of doing business, but when analyzed properly, they can reveal incredible insights about product quality, customer expectations, and operational efficiency.

Let's start with our first chart: Return Rate by Product. Our first query identifies the top products by return rate, showing both order-level returns (how many orders contained returned items) and unit-level returns (how many individual units were sent back). This distinction is important because sometimes a single problematic product might be driving returns across many orders.

What makes this query especially useful is that it sets a minimum threshold of 10 orders before including a product in the analysis. This ensures statistical relevance and prevents one-off returns from skewing your view. The results are sorted by return rate, but also show total sales volume, giving you context for how significant these return issues are to your overall business.

Our second query looks at return rates by price range. This perspective is fascinating because it often reveals how customer expectations change at different price points. For example, you might find that premium products ($200+) have higher return rates because customers have higher expectations for quality and functionality. Or conversely, you might discover that budget items have higher returns due to quality issues. Either way, these insights help you manage expectations and quality standards appropriately for each price segment.

The third query in this section tracks return rates over time, which helps identify seasonal patterns or sudden spikes that might indicate product quality issues. It also calculates the average days between delivery and return, which is valuable for understanding the customer decision process and for managing reverse logistics.

Moving to our second chart, Return Reasons Analysis helps you understand not just how many products are coming back, but why they're coming back. The first query here simply ranks return reasons by frequency and shows what percentage of total returns each reason represents. This immediately highlights your biggest areas for improvement.

The second query breaks down return reasons by product category. This intersection is incredibly valuable because different categories often have different primary return drivers. For example, clothing items might be returned primarily for sizing issues, electronics for functionality problems, and home goods for style or appearance mismatches. Understanding these category-specific patterns helps you target improvements more precisely.

The third query examines return reasons by price range. This perspective might reveal that customers return luxury items for different reasons than budget items. For instance, in higher price ranges, returns might be more driven by product quality issues, while in lower price ranges, returns might be more about mismatched expectations or impulse purchases.

Our final chart focuses on Return Impact Analysis, which quantifies the business consequences of returns. The first query calculates the financial impact of returns by category, including both the direct revenue impact and the estimated processing costs. This helps prioritize improvement initiatives based on their potential ROI.

The second query provides a detailed analysis of return timing across categories. Understanding how quickly customers decide to return items can inform your policies and procedures. For example, categories with quick returns might indicate clear quality or fit issues that customers identify immediately, while categories with longer return windows might involve more complex customer decision processes.

The third query in this section examines customer behavior after returns, specifically looking at whether customers make additional purchases after returning an item. This retention analysis is crucial because it helps distinguish between returns that represent a lost customer versus returns that are just part of the normal shopping process for loyal customers.

What makes these queries so powerful for business intelligence is that they transform return data from a pure cost center perspective into a source of actionable insights. They don't just tell you how many products came back – they help you understand why they came back, what it's costing you, and how to address the root causes.

For example, the financial impact query doesn't just show the direct cost of returns; it estimates the total impact including processing costs, giving you a more complete picture for decision-making. Similarly, the customer repeat purchase analysis helps you balance the immediate cost of returns against the long-term value of retained customers.

The goal of return analysis isn't just to reduce return rates – it's to improve the overall customer experience and product quality in ways that naturally lead to fewer returns. By targeting the specific products, categories, price points, and reasons driving your returns, you can make focused improvements that have measurable business impact.

Remember that some level of returns is unavoidable in retail, but understanding the patterns can transform returns from a pure cost into a valuable source of business intelligence.

In our next video, we'll explore Seasonal and Trend Analysis, where we'll learn how to identify patterns over time that can help you better anticipate customer demand and optimize your inventory planning. See you then!
