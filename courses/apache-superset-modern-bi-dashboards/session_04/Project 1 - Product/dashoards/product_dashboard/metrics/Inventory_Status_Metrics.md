# Inventory Status Metrics

## Business Context
Tracking inventory status through simple metrics helps ensure you have the right products available to meet customer demand without tying up excessive capital in slow-moving stock. These metrics provide a quick overview of inventory health without requiring complex analysis.

## Dashboard Charts

### Chart 1: Inventory Health Snapshot

**Purpose**: Provides an overview of current inventory levels, highlighting both potential stockout risks and overstocked items.

**SQL Query 1: Inventory Status Summary**
```sql
SELECT
    COUNT(*) AS total_products,
    COUNT(*) FILTER (WHERE stock_quantity = 0) AS out_of_stock_products,
    COUNT(*) FILTER (WHERE stock_quantity BETWEEN 1 AND 5) AS low_stock_products,
    COUNT(*) FILTER (WHERE stock_quantity > 5) AS healthy_stock_products,
    ROUND(AVG(stock_quantity)::numeric, 0) AS average_stock_level,
    SUM(stock_quantity) AS total_units_in_inventory,
    ROUND(SUM(stock_quantity * price)::numeric, 2) AS total_inventory_value
FROM
    products;
```

**SQL Query 2: Inventory Status by Category**
```sql
SELECT
    category,
    COUNT(*) AS total_products,
    COUNT(*) FILTER (WHERE stock_quantity = 0) AS out_of_stock_products,
    COUNT(*) FILTER (WHERE stock_quantity BETWEEN 1 AND 5) AS low_stock_products,
    COUNT(*) FILTER (WHERE stock_quantity > 5) AS healthy_stock_products,
    ROUND(100.0 * COUNT(*) FILTER (WHERE stock_quantity = 0) / COUNT(*), 1) AS out_of_stock_percentage,
    SUM(stock_quantity) AS total_units_in_stock,
    ROUND(SUM(stock_quantity * price)::numeric, 2) AS inventory_value
FROM
    products
GROUP BY
    category
ORDER BY
    out_of_stock_percentage DESC;
```

**SQL Query 3: Top 10 Products by Inventory Value**
```sql
SELECT
    product_id,
    name,
    category,
    stock_quantity,
    price,
    ROUND((stock_quantity * price)::numeric, 2) AS inventory_value
FROM
    products
WHERE
    stock_quantity > 0
ORDER BY
    inventory_value DESC
LIMIT 10;
```

### Chart 2: Stockout Risk Indicators

**Purpose**: Identifies products at risk of stockout based on current inventory levels and recent sales velocity.

**SQL Query 1: Products at Risk of Stockout**
```sql
WITH recent_sales_velocity AS (
    SELECT
        p.product_id,
        p.name,
        p.category,
        p.stock_quantity,
        COALESCE(SUM(o.quantity), 0) AS units_sold_last_30_days,
        COALESCE(SUM(o.quantity) / 30.0, 0) AS daily_sales_rate
    FROM
        products p
    LEFT JOIN
        orders o ON p.product_id = o.product_id
                AND o.status != 'Cancelled' AND o.is_returned = FALSE
                AND o.order_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY
        p.product_id, p.name, p.category, p.stock_quantity
)
SELECT
    product_id,
    name,
    category,
    stock_quantity,
    ROUND(units_sold_last_30_days::numeric, 0) AS units_sold_last_30_days,
    ROUND(daily_sales_rate::numeric, 2) AS daily_sales_rate,
    CASE
        WHEN daily_sales_rate = 0 THEN NULL
        ELSE ROUND((stock_quantity / daily_sales_rate)::numeric, 0)
    END AS days_of_inventory_left,
    CASE
        WHEN daily_sales_rate = 0 THEN 'No Recent Sales'
        WHEN stock_quantity = 0 THEN 'Out of Stock'
        WHEN stock_quantity / daily_sales_rate <= 7 THEN 'Critical (< 1 week)'
        WHEN stock_quantity / daily_sales_rate <= 14 THEN 'Low (< 2 weeks)'
        WHEN stock_quantity / daily_sales_rate <= 30 THEN 'Warning (< 1 month)'
        ELSE 'Healthy'
    END AS stock_status
FROM
    recent_sales_velocity
WHERE
    (daily_sales_rate > 0 AND stock_quantity / daily_sales_rate <= 30)
    OR stock_quantity = 0
ORDER BY
    CASE
        WHEN stock_quantity = 0 THEN 0
        WHEN daily_sales_rate = 0 THEN 999
        ELSE stock_quantity / daily_sales_rate
    END,
    units_sold_last_30_days DESC
LIMIT 20;
```

**SQL Query 2: Most Frequently Stocked Out Products**
```sql
-- Note: This query assumes you have a stock history table or events
-- The following is a theoretical query showing what would be useful

WITH stockout_history AS (
    SELECT
        product_id,
        COUNT(*) AS stockout_events,
        MAX(event_date) AS last_stockout_date,
        SUM(duration_days) AS total_days_out_of_stock
    FROM
        product_stock_history
    WHERE
        event_type = 'stockout'
        AND event_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY
        product_id
)
SELECT
    p.product_id,
    p.name,
    p.category,
    p.stock_quantity AS current_stock,
    sh.stockout_events,
    sh.last_stockout_date,
    sh.total_days_out_of_stock,
    ROUND(100.0 * sh.total_days_out_of_stock / 90, 1) AS percentage_time_out_of_stock
FROM
    products p
JOIN
    stockout_history sh ON p.product_id = sh.product_id
ORDER BY
    sh.stockout_events DESC, sh.total_days_out_of_stock DESC
LIMIT 20;

-- Alternative query without stock history table
SELECT
    p.product_id,
    p.name,
    p.category,
    p.stock_quantity AS current_stock,
    COUNT(DISTINCT o.order_id) AS orders_last_90_days,
    SUM(o.quantity) AS units_sold_last_90_days,
    ROUND(SUM(o.total_amount)::numeric, 2) AS revenue_last_90_days,
    CASE
        WHEN p.stock_quantity = 0 THEN 'Currently Out of Stock'
        ELSE 'In Stock'
    END AS current_status
FROM
    products p
JOIN
    orders o ON p.product_id = o.product_id
        AND o.status != 'Cancelled'
        AND o.order_date >= CURRENT_DATE - INTERVAL '90 days'
WHERE
    p.stock_quantity = 0 OR p.stock_quantity < 5
GROUP BY
    p.product_id, p.name, p.category, p.stock_quantity
ORDER BY
    units_sold_last_90_days DESC
LIMIT 20;
```

**SQL Query 3: Expected Stockout Dates**
```sql
WITH sales_velocity AS (
    SELECT
        p.product_id,
        p.name,
        p.category,
        p.stock_quantity,
        COALESCE(SUM(o.quantity), 0) AS units_sold_last_30_days,
        COALESCE(SUM(o.quantity) / 30.0, 0) AS daily_sales_rate
    FROM
        products p
    LEFT JOIN
        orders o ON p.product_id = o.product_id
                AND o.status != 'Cancelled' AND o.is_returned = FALSE
                AND o.order_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY
        p.product_id, p.name, p.category, p.stock_quantity
)
SELECT
    product_id,
    name,
    category,
    stock_quantity,
    ROUND(units_sold_last_30_days::numeric, 0) AS units_sold_last_30_days,
    ROUND(daily_sales_rate::numeric, 2) AS daily_sales_rate,
    CASE
        WHEN daily_sales_rate = 0 THEN NULL
        ELSE ROUND((stock_quantity / daily_sales_rate)::numeric, 0)
    END AS days_until_stockout,
    CASE
        WHEN daily_sales_rate = 0 THEN NULL
        ELSE (CURRENT_DATE + (stock_quantity / daily_sales_rate)::integer)::date
    END AS expected_stockout_date,
    CASE
        WHEN daily_sales_rate = 0 THEN 'No Recent Sales'
        WHEN stock_quantity = 0 THEN 'Out of Stock'
        WHEN stock_quantity / daily_sales_rate <= 7 THEN 'Critical (< 1 week)'
        WHEN stock_quantity / daily_sales_rate <= 14 THEN 'Low (< 2 weeks)'
        WHEN stock_quantity / daily_sales_rate <= 30 THEN 'Warning (< 1 month)'
        ELSE 'Healthy'
    END AS stock_status
FROM
    sales_velocity
WHERE
    daily_sales_rate > 0
    AND stock_quantity > 0
    AND stock_quantity / daily_sales_rate <= 30
ORDER BY
    days_until_stockout
LIMIT 20;
```

### Chart 3: Excess Inventory Alerts

**Purpose**: Identifies products with excessive inventory levels that may tie up capital unnecessarily.

**SQL Query 1: Overstocked Products**
```sql
WITH sales_velocity AS (
    SELECT
        p.product_id,
        p.name,
        p.category,
        p.stock_quantity,
        p.price,
        COALESCE(SUM(o.quantity), 0) AS units_sold_last_90_days,
        COALESCE(SUM(o.quantity) / 90.0, 0) AS daily_sales_rate
    FROM
        products p
    LEFT JOIN
        orders o ON p.product_id = o.product_id
                AND o.status != 'Cancelled' AND o.is_returned = FALSE
                AND o.order_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY
        p.product_id, p.name, p.category, p.stock_quantity, p.price
)
SELECT
    product_id,
    name,
    category,
    stock_quantity,
    ROUND(units_sold_last_90_days::numeric, 0) AS units_sold_last_90_days,
    ROUND(daily_sales_rate::numeric, 2) AS daily_sales_rate,
    ROUND(daily_sales_rate * 30, 0) AS monthly_sales_rate,
    CASE
        WHEN daily_sales_rate = 0 THEN NULL
        ELSE ROUND((stock_quantity / daily_sales_rate)::numeric, 0)
    END AS days_of_inventory,
    CASE
        WHEN daily_sales_rate = 0 THEN stock_quantity
        ELSE GREATEST(stock_quantity - (daily_sales_rate * 90), 0)::integer
    END AS excess_units,
    ROUND(
        CASE
            WHEN daily_sales_rate = 0 THEN stock_quantity * price
            ELSE GREATEST(stock_quantity - (daily_sales_rate * 90), 0) * price
        END::numeric,
        2
    ) AS excess_inventory_value
FROM
    sales_velocity
WHERE
    (daily_sales_rate = 0 AND stock_quantity > 10)
    OR (daily_sales_rate > 0 AND stock_quantity > daily_sales_rate * 90)
ORDER BY
    excess_inventory_value DESC
LIMIT 20;
```

**SQL Query 2: No Sales Inventory**
```sql
SELECT
    p.product_id,
    p.name,
    p.category,
    p.stock_quantity,
    p.price,
    ROUND((p.stock_quantity * p.price)::numeric, 2) AS inventory_value,
    p.created_at AS added_to_inventory_date,
    EXTRACT(DAY FROM (CURRENT_DATE - p.created_at)) AS days_in_inventory
FROM
    products p
LEFT JOIN
    orders o ON p.product_id = o.product_id
            AND o.status != 'Cancelled'
            AND o.order_date >= CURRENT_DATE - INTERVAL '90 days'
WHERE
    o.order_id IS NULL
    AND p.stock_quantity > 0
ORDER BY
    inventory_value DESC
LIMIT 20;
```

**SQL Query 3: Total Value of Excess Inventory by Category**
```sql
WITH category_sales AS (
    SELECT
        p.category,
        SUM(o.quantity) / 90.0 AS daily_sales_rate,
        SUM(p.stock_quantity) AS total_stock,
        SUM(p.stock_quantity * p.price) AS total_inventory_value
    FROM
        products p
    LEFT JOIN
        orders o ON p.product_id = o.product_id
                AND o.status != 'Cancelled' AND o.is_returned = FALSE
                AND o.order_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY
        p.category
)
SELECT
    category,
    ROUND(daily_sales_rate::numeric, 2) AS daily_sales_rate,
    ROUND(daily_sales_rate * 30, 0) AS monthly_sales_rate,
    total_stock,
    ROUND(total_inventory_value::numeric, 2) AS total_inventory_value,
    -- Assuming 90 days is optimal inventory level
    GREATEST(total_stock - (daily_sales_rate * 90), 0)::integer AS excess_units,
    ROUND(
        (GREATEST(total_stock - (daily_sales_rate * 90), 0) / NULLIF(total_stock, 0) * total_inventory_value)::numeric,
        2
    ) AS excess_inventory_value,
    ROUND(
        100.0 * GREATEST(total_stock - (daily_sales_rate * 90), 0) / NULLIF(total_stock, 0),
        1
    ) AS excess_percentage
FROM
    category_sales
ORDER BY
    excess_inventory_value DESC;
```

## YouTube Script: Understanding Inventory Status Metrics

Hey everyone! Today we're looking at some straightforward but critical inventory metrics that help you keep the right amount of stock on hand - not too much, not too little, but just right.

Let's start with our Inventory Health Snapshot. The first query gives you an immediate overview of your entire inventory status. It shows how many products are out of stock, how many are running low, and how many have healthy inventory levels. It also calculates your total inventory value - a number your finance team is probably watching closely!

This summary is something you should check daily. If your out-of-stock percentage starts creeping up, you're potentially losing sales. Conversely, if your average stock levels are climbing while sales remain flat, you might be tying up too much capital in inventory.

The second query breaks this information down by category, which helps you pinpoint where inventory issues might be concentrated. For example, you might discover that your Electronics category has a 15% out-of-stock rate while other categories are below 5%. This immediately tells you where to focus your inventory management efforts.

The third query simply shows which products represent the largest inventory investments. This is crucial because inventory isn't just about quantities - it's about capital allocation. A single high-value product with excess inventory might tie up more capital than dozens of lower-value items.

Moving to our second chart, Stockout Risk Indicators helps you proactively prevent inventory shortages. The first query identifies products at risk of stockout based on their current stock levels and recent sales velocity. What makes this query powerful is that it doesn't just look at absolute quantities - it calculates how many days of inventory you have left at the current sales rate.

This creates a clear prioritization for reordering. A product with only 3 days of inventory remaining is obviously more urgent than one with 3 weeks, regardless of the absolute quantity.

The second query would ideally track your most frequently stocked-out products over time, helping identify recurring inventory challenges. Without a stock history table, we've provided an alternative that focuses on high-selling products that are currently out of stock or have very low inventory, which serves a similar purpose.

The third query in this section calculates expected stockout dates for at-risk products. This is incredibly actionable information - instead of just knowing a product is "low on stock," you can see exactly when you're projected to run out. If your average reorder lead time is 14 days and a popular product is expected to stock out in 10 days, that's an urgent situation requiring immediate attention.

Our final chart focuses on Excess Inventory Alerts - the opposite problem. The first query identifies overstocked products based on their sales velocity. It assumes that 90 days of inventory is optimal (though this varies by business) and calculates how much excess inventory value you're carrying beyond that point.

This is crucial because excess inventory directly impacts cash flow and storage costs. The ability to quickly identify where your capital is unnecessarily tied up allows you to make targeted decisions about clearance sales, promotions, or inventory rebalancing.

The second query finds products with no recent sales - items sitting in your warehouse gathering dust. These often represent the clearest opportunities for inventory reduction, especially those that have been in inventory for extended periods without generating sales.

The third query aggregates excess inventory by category, helping you understand where the bulk of your excess inventory value is concentrated. This category-level view is perfect for strategic decisions about which product lines might need broader assortment reviews or promotional strategies.

What makes these inventory metrics so valuable is their actionability. They don't just describe your current state; they highlight specific products that need attention, whether for replenishment or reduction. By focusing on both stockout risks and excess inventory, they help you optimize your inventory investment from both directions.

Remember that the "right" inventory level depends on your business model, product characteristics, and supplier lead times. These metrics provide the visibility you need to make those judgments, helping ensure you have what customers want when they want it, without tying up excessive capital in slow-moving stock.

In our next video, we'll look at Customer Metrics that provide similar straightforward insights into your customer behavior and purchasing patterns. See you then!
