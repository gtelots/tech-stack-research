# Inventory Health Assessment

## Business Context
Efficient inventory management is crucial for optimizing working capital and ensuring product availability. This analysis helps identify overstocked items, potential stockouts, and optimal inventory levels across your product catalog.

## Dashboard Charts

### Chart 1: Inventory Turnover Analysis

**Purpose**: Evaluates how quickly inventory is sold and replaced, identifying slow-moving items that tie up capital and fast-moving items that may risk stockouts.

**SQL Query 1: Inventory Turnover Ratio by Category**
```sql
WITH sales_data AS (
    SELECT 
        p.category,
        SUM(o.quantity) AS units_sold
    FROM 
        orders o
    JOIN 
        products p ON o.product_id = p.product_id
    WHERE 
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        p.category
),
inventory_data AS (
    SELECT 
        category,
        SUM(stock_quantity) AS current_stock
    FROM 
        products
    GROUP BY 
        category
)
SELECT 
    i.category,
    i.current_stock AS total_inventory,
    s.units_sold AS annual_units_sold,
    CASE 
        WHEN i.current_stock = 0 THEN NULL
        ELSE ROUND((s.units_sold / i.current_stock)::numeric, 2)
    END AS inventory_turnover_ratio,
    CASE 
        WHEN i.current_stock = 0 THEN NULL
        ELSE ROUND((365 / NULLIF((s.units_sold / i.current_stock), 0))::numeric, 1)
    END AS days_of_inventory
FROM 
    inventory_data i
JOIN 
    sales_data s ON i.category = s.category
ORDER BY 
    inventory_turnover_ratio DESC;
```

**SQL Query 2: Low Turnover Products (Slow Moving)**
```sql
WITH product_sales AS (
    SELECT 
        p.product_id,
        p.name,
        p.category,
        p.stock_quantity,
        p.price,
        ROUND(p.price * p.stock_quantity, 2) AS inventory_value,
        COALESCE(SUM(o.quantity), 0) AS units_sold
    FROM 
        products p
    LEFT JOIN 
        orders o ON p.product_id = o.product_id 
                AND o.status != 'Cancelled' 
                AND o.is_returned = FALSE
                AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        p.product_id, p.name, p.category, p.stock_quantity, p.price
)
SELECT 
    product_id,
    name,
    category,
    stock_quantity,
    units_sold,
    inventory_value,
    CASE 
        WHEN stock_quantity = 0 THEN NULL
        WHEN units_sold = 0 THEN 0
        ELSE ROUND((units_sold / stock_quantity)::numeric, 2)
    END AS turnover_ratio,
    CASE 
        WHEN stock_quantity = 0 THEN NULL
        WHEN units_sold = 0 THEN 999
        ELSE ROUND((365 / (units_sold / stock_quantity))::numeric, 0)
    END AS days_of_inventory
FROM 
    product_sales
WHERE 
    stock_quantity > 0 AND (units_sold / stock_quantity) < 2  -- Less than 2 turns per year
ORDER BY 
    turnover_ratio ASC, inventory_value DESC
LIMIT 20;
```

**SQL Query 3: High Turnover Products (Risk of Stockout)**
```sql
WITH product_sales AS (
    SELECT 
        p.product_id,
        p.name,
        p.category,
        p.stock_quantity,
        COALESCE(SUM(o.quantity), 0) AS units_sold,
        CASE 
            WHEN p.stock_quantity = 0 THEN NULL
            WHEN COALESCE(SUM(o.quantity), 0) = 0 THEN 0
            ELSE ROUND((COALESCE(SUM(o.quantity), 0) / p.stock_quantity)::numeric, 2)
        END AS turnover_ratio
    FROM 
        products p
    LEFT JOIN 
        orders o ON p.product_id = o.product_id 
                AND o.status != 'Cancelled' 
                AND o.is_returned = FALSE
                AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        p.product_id, p.name, p.category, p.stock_quantity
)
SELECT 
    product_id,
    name,
    category,
    stock_quantity,
    units_sold,
    turnover_ratio,
    CASE 
        WHEN stock_quantity = 0 THEN NULL
        WHEN units_sold = 0 THEN NULL
        ELSE ROUND((stock_quantity / (units_sold / 365))::numeric, 1)
    END AS days_of_supply_left,
    ROUND((units_sold / 365)::numeric, 1) AS avg_daily_sales
FROM 
    product_sales
WHERE 
    turnover_ratio > 12  -- More than 12 turns per year (once a month)
    AND stock_quantity > 0
ORDER BY 
    turnover_ratio DESC
LIMIT 20;
```

### Chart 2: Stockout Risk Assessment

**Purpose**: Identifies products at risk of going out of stock, potentially leading to lost sales and reduced customer satisfaction.

**SQL Query 1: Products with Critical Stock Levels**
```sql
WITH monthly_sales AS (
    SELECT 
        p.product_id,
        p.name,
        p.category,
        EXTRACT(MONTH FROM o.order_date) AS month,
        SUM(o.quantity) AS monthly_units_sold
    FROM 
        products p
    JOIN 
        orders o ON p.product_id = o.product_id
    WHERE 
        o.status != 'Cancelled' 
        AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        p.product_id, p.name, p.category, month
),
product_metrics AS (
    SELECT 
        product_id,
        name,
        category,
        ROUND(AVG(monthly_units_sold)::numeric, 1) AS avg_monthly_sales,
        ROUND(MAX(monthly_units_sold)::numeric, 1) AS peak_monthly_sales
    FROM 
        monthly_sales
    GROUP BY 
        product_id, name, category
)
SELECT 
    pm.product_id,
    pm.name,
    pm.category,
    p.stock_quantity AS current_stock,
    pm.avg_monthly_sales,
    pm.peak_monthly_sales,
    CASE 
        WHEN p.stock_quantity = 0 THEN 'Out of Stock'
        WHEN p.stock_quantity < pm.avg_monthly_sales THEN 'Critical (Less than 1 month)'
        WHEN p.stock_quantity < pm.avg_monthly_sales * 2 THEN 'Low (Less than 2 months)'
        WHEN p.stock_quantity < pm.avg_monthly_sales * 3 THEN 'Moderate (Less than 3 months)'
        ELSE 'Adequate'
    END AS stock_status,
    CASE 
        WHEN p.stock_quantity = 0 THEN 0
        ELSE ROUND((p.stock_quantity / NULLIF(pm.avg_monthly_sales, 0))::numeric, 1)
    END AS months_of_inventory
FROM 
    product_metrics pm
JOIN 
    products p ON pm.product_id = p.product_id
WHERE 
    pm.avg_monthly_sales > 0
ORDER BY 
    months_of_inventory ASC, pm.avg_monthly_sales DESC
LIMIT 20;
```

**SQL Query 2: Historical Stockout Analysis**
```sql
-- This query requires a stock history table or events that we don't have in our current schema
-- The following is a theoretical query assuming we had a product_stock_history table

WITH stock_events AS (
    SELECT 
        product_id,
        event_date,
        new_stock_quantity,
        CASE WHEN new_stock_quantity = 0 THEN 1 ELSE 0 END AS stockout_event
    FROM 
        product_stock_history
    WHERE 
        event_date >= CURRENT_DATE - INTERVAL '12 months'
),
stockout_summary AS (
    SELECT 
        product_id,
        SUM(stockout_event) AS number_of_stockouts,
        MAX(CASE WHEN stockout_event = 1 THEN event_date ELSE NULL END) AS latest_stockout
    FROM 
        stock_events
    GROUP BY 
        product_id
)
SELECT 
    p.product_id,
    p.name,
    p.category,
    p.stock_quantity AS current_stock,
    COALESCE(ss.number_of_stockouts, 0) AS stockouts_last_12months,
    ss.latest_stockout,
    CASE WHEN ss.latest_stockout IS NOT NULL THEN 
        EXTRACT(DAY FROM (CURRENT_DATE - ss.latest_stockout))
    ELSE NULL END AS days_since_last_stockout
FROM 
    products p
LEFT JOIN 
    stockout_summary ss ON p.product_id = ss.product_id
WHERE 
    ss.number_of_stockouts > 0 OR p.stock_quantity < 5
ORDER BY 
    ss.number_of_stockouts DESC, p.stock_quantity ASC;
```

**SQL Query 3: Reorder Level Recommendations**
```sql
WITH sales_stats AS (
    SELECT 
        p.product_id,
        p.name,
        p.category,
        p.stock_quantity,
        p.price,
        ROUND(AVG(daily_sales.quantity)::numeric, 2) AS avg_daily_sales,
        ROUND(STDDEV_SAMP(daily_sales.quantity)::numeric, 2) AS stddev_daily_sales,
        ROUND(MAX(daily_sales.quantity)::numeric, 2) AS max_daily_sales
    FROM 
        products p
    CROSS JOIN LATERAL (
        SELECT 
            o.order_date::date AS sale_date,
            COALESCE(SUM(o.quantity), 0) AS quantity
        FROM 
            orders o
        WHERE 
            o.product_id = p.product_id
            AND o.status != 'Cancelled' 
            AND o.is_returned = FALSE
            AND o.order_date >= CURRENT_DATE - INTERVAL '6 months'
        GROUP BY 
            sale_date
    ) AS daily_sales
    GROUP BY 
        p.product_id, p.name, p.category, p.stock_quantity, p.price
    HAVING 
        AVG(daily_sales.quantity) > 0
)
SELECT 
    product_id,
    name,
    category,
    stock_quantity AS current_stock,
    avg_daily_sales,
    ROUND((avg_daily_sales * 30)::numeric, 0) AS avg_monthly_sales,
    stddev_daily_sales,
    max_daily_sales,
    -- Assume 14 days lead time for replenishment
    ROUND((avg_daily_sales * 14 + 1.96 * stddev_daily_sales * SQRT(14))::numeric, 0) AS suggested_reorder_point,
    -- Optimal order quantity calculation (simplified EOQ formula)
    ROUND((SQRT(2 * avg_daily_sales * 365 * 10 / (price * 0.25)))::numeric, 0) AS suggested_order_quantity
FROM 
    sales_stats
WHERE 
    avg_daily_sales > 0
ORDER BY 
    (stock_quantity / (avg_daily_sales * 30)) ASC
LIMIT 20;
```

### Chart 3: Excess Inventory Analysis

**Purpose**: Identifies overstocked items that tie up working capital and may incur storage costs or risk obsolescence.

**SQL Query 1: Overstocked Products by Value**
```sql
WITH sales_velocity AS (
    SELECT 
        p.product_id,
        COALESCE(SUM(o.quantity), 0) / 12 AS avg_monthly_sales
    FROM 
        products p
    LEFT JOIN 
        orders o ON p.product_id = o.product_id
              AND o.status != 'Cancelled' 
              AND o.is_returned = FALSE
              AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        p.product_id
)
SELECT 
    p.product_id,
    p.name,
    p.category,
    p.stock_quantity,
    p.price,
    ROUND(p.price * p.stock_quantity, 2) AS total_inventory_value,
    ROUND(sv.avg_monthly_sales::numeric, 1) AS avg_monthly_sales,
    -- Assuming 3 months is optimal stock level
    GREATEST(p.stock_quantity - (sv.avg_monthly_sales * 3), 0) AS excess_units,
    ROUND(GREATEST(p.stock_quantity - (sv.avg_monthly_sales * 3), 0) * p.price, 2) AS excess_inventory_value,
    CASE 
        WHEN sv.avg_monthly_sales = 0 THEN 'Stagnant'
        WHEN p.stock_quantity > sv.avg_monthly_sales * 6 THEN 'Heavily Overstocked'
        WHEN p.stock_quantity > sv.avg_monthly_sales * 3 THEN 'Overstocked'
        ELSE 'Optimal'
    END AS stock_status,
    CASE 
        WHEN sv.avg_monthly_sales = 0 THEN NULL
        ELSE ROUND((p.stock_quantity / sv.avg_monthly_sales)::numeric, 1)
    END AS months_of_supply
FROM 
    products p
JOIN 
    sales_velocity sv ON p.product_id = sv.product_id
WHERE 
    (p.stock_quantity > sv.avg_monthly_sales * 3 OR (sv.avg_monthly_sales = 0 AND p.stock_quantity > 0))
    AND p.stock_quantity > 0
ORDER BY 
    excess_inventory_value DESC
LIMIT 20;
```

**SQL Query 2: Stagnant Inventory (No Sales)**
```sql
SELECT 
    p.product_id,
    p.name,
    p.category,
    p.stock_quantity,
    p.price,
    ROUND(p.price * p.stock_quantity, 2) AS inventory_value,
    p.created_at AS product_added_date,
    EXTRACT(DAY FROM (CURRENT_DATE - p.created_at)) AS days_in_inventory
FROM 
    products p
LEFT JOIN 
    orders o ON p.product_id = o.product_id
            AND o.status != 'Cancelled' 
            AND o.is_returned = FALSE
            AND o.order_date >= CURRENT_DATE - INTERVAL '6 months'
WHERE 
    o.order_id IS NULL
    AND p.stock_quantity > 0
    AND p.created_at < CURRENT_DATE - INTERVAL '30 days'
ORDER BY 
    inventory_value DESC, days_in_inventory DESC
LIMIT 20;
```

**SQL Query 3: Inventory Aging Analysis**
```sql
WITH last_sale AS (
    SELECT 
        p.product_id,
        MAX(o.order_date) AS last_sale_date
    FROM 
        products p
    LEFT JOIN 
        orders o ON p.product_id = o.product_id
              AND o.status != 'Cancelled' 
              AND o.is_returned = FALSE
    GROUP BY 
        p.product_id
)
SELECT 
    p.product_id,
    p.name,
    p.category,
    p.stock_quantity,
    p.price,
    ROUND(p.price * p.stock_quantity, 2) AS inventory_value,
    ls.last_sale_date,
    CASE
        WHEN ls.last_sale_date IS NULL THEN 'Never Sold'
        ELSE EXTRACT(DAY FROM (CURRENT_DATE - ls.last_sale_date))::text || ' days'
    END AS days_since_last_sale,
    CASE
        WHEN ls.last_sale_date IS NULL AND p.created_at < CURRENT_DATE - INTERVAL '180 days' THEN 'Dead Stock'
        WHEN ls.last_sale_date IS NULL THEN 'New Product (No Sales)'
        WHEN ls.last_sale_date < CURRENT_DATE - INTERVAL '180 days' THEN 'Dormant (> 6 months)'
        WHEN ls.last_sale_date < CURRENT_DATE - INTERVAL '90 days' THEN 'Slow (3-6 months)'
        WHEN ls.last_sale_date < CURRENT_DATE - INTERVAL '30 days' THEN 'Sluggish (1-3 months)'
        ELSE 'Active (< 1 month)'
    END AS inventory_age_status
FROM 
    products p
LEFT JOIN 
    last_sale ls ON p.product_id = ls.product_id
WHERE 
    p.stock_quantity > 0
    AND (ls.last_sale_date IS NULL OR ls.last_sale_date < CURRENT_DATE - INTERVAL '30 days')
ORDER BY 
    ls.last_sale_date ASC NULLS FIRST, inventory_value DESC
LIMIT 20;
```

## YouTube Script: Mastering Inventory Health Assessment

Welcome back everyone! Today we're talking about something that can make or break a retail business: Inventory Health Assessment. Managing your inventory effectively is a delicate balance – too much ties up your capital and creates storage costs, too little leads to stockouts and lost sales. Let's dive into how data can help you find that sweet spot.

Our first chart focuses on Inventory Turnover Analysis. This is all about understanding how quickly your products are selling relative to the amount you have in stock. The first query calculates the inventory turnover ratio by category, which is one of the most important metrics in retail. It divides the annual units sold by the current stock level to tell you how many times your inventory "turns over" each year.

What makes this query special is that it also converts this ratio into "days of inventory" – essentially how long your current stock would last at your current sales rate. This makes the numbers more intuitive for planning purposes. Ideally, you want to see high turnover ratios, but what's "high" varies by industry. Electronics might turn over 6-8 times a year, while furniture might be 3-4 times.

Our second query identifies your slowest-moving products – those with turnover ratios under 2, meaning they take more than 6 months to sell through. This query is particularly valuable because it also shows you the inventory value tied up in these slow movers. Often, a small percentage of products can lock up a large percentage of your inventory investment, and this query helps you spot those culprits.

The third query in this section does the opposite – it identifies products with very high turnover that might be at risk of stockouts. It calculates how many days of supply you have left based on average daily sales. These are products you might want to reorder soon or consider stocking in larger quantities.

Moving to our second chart, the Stockout Risk Assessment helps you proactively prevent running out of popular items. The first query here is particularly sophisticated – it identifies products with critical stock levels based on their average and peak monthly sales. What I love about this query is that it doesn't just look at absolute quantities, but contextualizes them relative to each product's sales velocity.

It categorizes products into different risk levels: Critical (less than 1 month of stock), Low (less than 2 months), Moderate (less than 3 months), or Adequate. This creates a prioritized list of what you should reorder first.

The second query in this section would ideally track historical stockout events, which would require a stock history table we don't have in our current schema. But in a real implementation, this would help you identify products with recurring stockout issues that might need special attention in your inventory planning.

The third query provides reorder level recommendations using statistical methods. It calculates suggested reorder points that account for both average daily sales and variability in those sales. It even includes a simplified Economic Order Quantity (EOQ) calculation to suggest optimal order sizes. This is where inventory management transforms from art to science.

Our final chart examines Excess Inventory. The first query identifies overstocked products by comparing current stock levels to monthly sales. It assumes that three months of inventory is optimal (though this varies by business) and calculates how much excess inventory value you're carrying beyond that point. This is crucial because excess inventory directly impacts cash flow and storage costs.

The second query finds completely stagnant inventory – products that haven't sold at all in the last six months but still occupy shelf space and tie up capital. It's particularly concerned with older products, showing how long they've been sitting in inventory without movement.

The third query provides an aging analysis of your entire inventory, categorizing products based on recency of sales. Categories range from "Active" (sold within the last month) to "Dead Stock" (never sold and in inventory for over 6 months). This helps you decide which products might need promotional attention, discounting, or even liquidation.

What makes these queries so powerful for business intelligence is that they transform inventory data from a static snapshot into a dynamic assessment of financial health and operational risk. They don't just tell you what you have – they tell you what that means for your business.

For example, the excess inventory query isn't just identifying overstocked products; it's quantifying the amount of working capital that could be freed up through better inventory management. Similarly, the stockout risk assessment isn't just listing low-stock items; it's helping you prioritize reordering based on sales patterns and lead times.

The goal of inventory analysis isn't just to have the right products, but to optimize your entire inventory investment. These queries help you identify where to reduce stock, where to increase it, and how to time your reordering for maximum efficiency.

In our next video, we'll explore Price-Point Performance, where we'll see how price affects sales volume, customer behavior, and ultimately, your bottom line. See you then!
