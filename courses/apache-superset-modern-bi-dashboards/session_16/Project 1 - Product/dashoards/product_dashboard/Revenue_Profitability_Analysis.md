# Revenue & Profitability Analysis

## Business Context
Understanding which products and categories contribute most to your top and bottom line is essential for strategic decision-making. This analysis identifies your revenue drivers and profit generators, allowing you to focus resources on your most valuable products.

## Dashboard Charts

### Chart 1: Top 10 Products by Revenue

**Purpose**: Identifies the highest revenue-generating products to inform inventory, marketing, and sales strategies.

**SQL Query 1: Top 10 Products by Total Revenue**
```sql
SELECT 
    p.product_id,
    p.name AS product_name,
    p.category,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue,
    COUNT(o.order_id) AS number_of_orders
FROM 
    orders o
JOIN 
    products p ON o.product_id = p.product_id
WHERE 
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    p.product_id, p.name, p.category
ORDER BY 
    total_revenue DESC
LIMIT 10;
```

**SQL Query 2: Top 10 Products by Revenue - Monthly Trend**
```sql
SELECT 
    DATE_TRUNC('month', o.order_date) AS month,
    p.product_id,
    p.name AS product_name,
    ROUND(SUM(o.total_amount)::numeric, 2) AS monthly_revenue
FROM 
    orders o
JOIN 
    products p ON o.product_id = p.product_id
WHERE 
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND p.product_id IN (
        SELECT p.product_id
        FROM orders o
        JOIN products p ON o.product_id = p.product_id
        WHERE o.status != 'Cancelled' AND o.is_returned = FALSE
        GROUP BY p.product_id
        ORDER BY SUM(o.total_amount) DESC
        LIMIT 10
    )
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    month, p.product_id, p.name
ORDER BY 
    month, monthly_revenue DESC;
```

**SQL Query 3: Revenue Contribution by Price Range**
```sql
WITH price_ranges AS (
    SELECT
        CASE
            WHEN price < 25 THEN 'Under $25'
            WHEN price >= 25 AND price < 50 THEN '$25-$49.99'
            WHEN price >= 50 AND price < 100 THEN '$50-$99.99'
            WHEN price >= 100 AND price < 200 THEN '$100-$199.99'
            ELSE '$200+'
        END AS price_range,
        product_id
    FROM products
)
SELECT 
    pr.price_range,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue,
    ROUND(100.0 * SUM(o.total_amount) / (SELECT SUM(total_amount) FROM orders WHERE status != 'Cancelled' AND is_returned = FALSE), 2) AS revenue_percentage
FROM 
    orders o
JOIN 
    price_ranges pr ON o.product_id = pr.product_id
WHERE 
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    pr.price_range
ORDER BY 
    total_revenue DESC;
```

### Chart 2: Category Performance by Revenue and Profit Margin

**Purpose**: Compares category performance based on both revenue generation and profitability, helping identify which product categories to emphasize in your strategy.

**SQL Query 1: Category Revenue and Profit**
```sql
SELECT 
    p.category,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue,
    ROUND(SUM(o.quantity * (p.price - p.cost))::numeric, 2) AS gross_profit,
    ROUND(100.0 * SUM(o.quantity * (p.price - p.cost)) / SUM(o.total_amount), 2) AS profit_margin_percentage
FROM 
    orders o
JOIN 
    products p ON o.product_id = p.product_id
WHERE 
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    p.category
ORDER BY 
    total_revenue DESC;
```

**SQL Query 2: Monthly Category Revenue Trend**
```sql
SELECT 
    DATE_TRUNC('month', o.order_date) AS month,
    p.category,
    ROUND(SUM(o.total_amount)::numeric, 2) AS monthly_revenue,
    ROUND(SUM(o.quantity * (p.price - p.cost))::numeric, 2) AS monthly_profit
FROM 
    orders o
JOIN 
    products p ON o.product_id = p.product_id
WHERE 
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    month, p.category
ORDER BY 
    month, p.category;
```

**SQL Query 3: High-Margin vs Low-Margin Products by Category**
```sql
WITH product_margins AS (
    SELECT
        p.product_id,
        p.name,
        p.category,
        p.price,
        p.cost,
        100.0 * (p.price - p.cost) / p.price AS profit_margin_percentage,
        SUM(o.quantity) AS units_sold
    FROM
        products p
    JOIN
        orders o ON p.product_id = o.product_id
    WHERE
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY
        p.product_id, p.name, p.category, p.price, p.cost
)
SELECT
    category,
    COUNT(*) AS total_products,
    ROUND(AVG(profit_margin_percentage)::numeric, 2) AS avg_margin,
    COUNT(*) FILTER (WHERE profit_margin_percentage >= 50) AS high_margin_products,
    COUNT(*) FILTER (WHERE profit_margin_percentage < 25) AS low_margin_products,
    SUM(units_sold) AS total_units_sold
FROM
    product_margins
GROUP BY
    category
ORDER BY
    avg_margin DESC;
```

### Chart 3: Profit per Product Analysis

**Purpose**: Highlights individual product profit contribution, identifying your most profitable items beyond just revenue generation.

**SQL Query 1: Top 10 Most Profitable Products**
```sql
SELECT 
    p.product_id,
    p.name AS product_name,
    p.category,
    p.price,
    p.cost,
    ROUND(SUM(o.quantity)::numeric) AS total_units_sold,
    ROUND(SUM(o.quantity * (p.price - p.cost))::numeric, 2) AS total_profit,
    ROUND(100.0 * (p.price - p.cost) / p.price, 2) AS profit_margin_percentage
FROM 
    orders o
JOIN 
    products p ON o.product_id = p.product_id
WHERE 
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    p.product_id, p.name, p.category, p.price, p.cost
ORDER BY 
    total_profit DESC
LIMIT 10;
```

**SQL Query 2: Profitability Quadrant Analysis**
```sql
WITH product_metrics AS (
    SELECT
        p.product_id,
        p.name,
        p.category,
        ROUND(100.0 * (p.price - p.cost) / p.price, 2) AS profit_margin_percentage,
        SUM(o.quantity) AS units_sold
    FROM
        products p
    JOIN
        orders o ON p.product_id = o.product_id
    WHERE
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY
        p.product_id, p.name, p.category, p.price, p.cost
),
category_averages AS (
    SELECT
        category,
        AVG(profit_margin_percentage) AS avg_margin,
        AVG(units_sold) AS avg_units
    FROM
        product_metrics
    GROUP BY
        category
)
SELECT
    pm.product_id,
    pm.name,
    pm.category,
    pm.profit_margin_percentage,
    pm.units_sold,
    CASE
        WHEN pm.profit_margin_percentage >= ca.avg_margin AND pm.units_sold >= ca.avg_units THEN 'Star' -- High margin, high volume
        WHEN pm.profit_margin_percentage >= ca.avg_margin AND pm.units_sold < ca.avg_units THEN 'Opportunity' -- High margin, low volume
        WHEN pm.profit_margin_percentage < ca.avg_margin AND pm.units_sold >= ca.avg_units THEN 'Volume Driver' -- Low margin, high volume
        ELSE 'Underperformer' -- Low margin, low volume
    END AS quadrant
FROM
    product_metrics pm
JOIN
    category_averages ca ON pm.category = ca.category;
```

## YouTube Script: Understanding Revenue & Profitability Analysis

Hey everyone! Today we're diving into one of the most crucial aspects of business intelligence: Revenue and Profitability Analysis. This is where we discover which products are truly driving your business success.

Let's start with our first chart: Top 10 Products by Revenue. This shows us the heavy hitters in your product lineup – the items that are bringing in the most money. Our first query is straightforward but powerful. It joins the orders and products tables, filters out cancelled orders and returns, and then calculates total revenue for each product over the past 12 months.

What's great about this query is that it not only shows you the revenue figures but also the number of orders. This helps distinguish between products that sell in high volume at lower prices versus premium products that might sell fewer units but at higher price points.

Our second query takes these top 10 products and breaks down their performance month by month. This reveals important patterns – is a product consistently strong, or does it have seasonal peaks? For instance, you might see certain electronics spike during holiday seasons or specific items trend upward as they gain popularity.

The third query in this section analyzes revenue contribution by price range. This is fascinating because it shows whether your business is driven by budget items, mid-range products, or premium offerings. It calculates the percentage of total revenue coming from each price bracket, which might challenge assumptions about where your business focus should be.

Moving to our second chart, Category Performance by Revenue and Profit Margin gives you a dual perspective on your product categories. The first query here calculates both the total revenue and the gross profit for each category, along with the profit margin percentage. This combination is powerful because high revenue doesn't always mean high profit.

For example, you might discover that your Electronics category drives the most revenue but has slim margins, while your Accessories category brings in less total revenue but with much healthier profit margins. This kind of insight can reshape your marketing and inventory investment strategies.

The second query in this section tracks category performance month by month, showing both revenue and profit trends. This helps identify seasonal patterns at the category level and can inform inventory planning throughout the year.

Our third query for this chart is particularly insightful – it analyzes the distribution of high-margin versus low-margin products within each category. It shows you the average margin per category, along with counts of products that have exceptionally high or low margins. This can reveal categories that might look good on average but actually contain many underperforming products being carried by a few stars.

Finally, our third chart focuses specifically on Profit per Product Analysis. The first query simply ranks products by total profit contribution, factoring in both sales volume and margin. Often, these aren't the same products that top the revenue chart, which makes this perspective so valuable.

The second query here is my personal favorite – the Profitability Quadrant Analysis. It categorizes each product into one of four quadrants based on whether they're above or below average for their category in both profit margin and units sold. This creates a powerful strategic framework:

- "Stars" have above-average margins and sales volumes – these deserve celebration and protection
- "Opportunities" have great margins but lower volumes – these might benefit from increased marketing
- "Volume Drivers" sell well but with thinner margins – these might need cost reduction strategies
- "Underperformers" lag in both metrics – these might be candidates for discontinuation

What makes these queries so powerful is that they transform raw transaction data into actionable business insights. They don't just tell you what happened – they help you understand why it happened and what you might do about it.

Remember, the goal isn't just to know which products make money, but to understand the patterns and relationships that drive profitability across your entire product catalog. This deeper understanding enables more strategic decisions about pricing, promotions, inventory, and product development.

In our next video, we'll explore Inventory Health Assessment, where we'll learn how to ensure you have the right products in the right quantities at the right time. See you then!
