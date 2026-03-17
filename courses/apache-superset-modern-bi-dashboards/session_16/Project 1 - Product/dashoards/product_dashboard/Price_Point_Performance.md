# Price-Point Performance

## Business Context
Understanding how products perform across different price ranges is crucial for optimizing pricing strategy and maximizing profitability. This analysis helps identify optimal price points, price elasticity, and opportunities for strategic pricing adjustments.

## Dashboard Charts

### Chart 1: Sales Volume by Price Range

**Purpose**: Visualizes how sales volume distributes across different price bands, helping identify the most popular price points for your products.

**SQL Query 1: Sales Volume Distribution by Price Range**
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
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    SUM(o.quantity) AS units_sold,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue,
    ROUND(AVG(o.unit_price)::numeric, 2) AS average_unit_price,
    ROUND(SUM(o.total_amount) / SUM(o.quantity), 2) AS average_order_value
FROM 
    orders o
JOIN 
    price_ranges pr ON o.product_id = pr.product_id
JOIN
    price_range_order pro ON pr.price_range = pro.price_range
WHERE 
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    pro.price_range, pro.sort_order
ORDER BY 
    pro.sort_order;
```

**SQL Query 2: Monthly Sales Trend by Price Range**
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
    DATE_TRUNC('month', o.order_date) AS month,
    pro.price_range,
    SUM(o.quantity) AS units_sold,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS number_of_orders
FROM 
    orders o
JOIN 
    price_ranges pr ON o.product_id = pr.product_id
JOIN
    price_range_order pro ON pr.price_range = pro.price_range
WHERE 
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    month, pro.price_range, pro.sort_order
ORDER BY 
    month, pro.sort_order;
```

**SQL Query 3: Price Range Performance by Category**
```sql
WITH price_ranges AS (
    SELECT
        product_id,
        category,
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
    pr.category,
    pro.price_range,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    SUM(o.quantity) AS units_sold,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue,
    ROUND(SUM(o.total_amount) / SUM(o.quantity), 2) AS average_unit_revenue
FROM 
    orders o
JOIN 
    price_ranges pr ON o.product_id = pr.product_id
JOIN
    price_range_order pro ON pr.price_range = pro.price_range
WHERE 
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    pr.category, pro.price_range, pro.sort_order
ORDER BY 
    pr.category, pro.sort_order;
```

### Chart 2: Price Point Profitability Analysis

**Purpose**: Analyzes how profit margins vary across different price points, helping identify the most profitable pricing strategies.

**SQL Query 1: Profit Margin by Price Range**
```sql
WITH price_ranges AS (
    SELECT
        product_id,
        price,
        cost,
        100 * (price - cost) / price AS margin_percentage,
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
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    SUM(o.quantity) AS units_sold,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue,
    ROUND(SUM(o.quantity * (pr.price - pr.cost))::numeric, 2) AS total_profit,
    ROUND(100 * SUM(o.quantity * (pr.price - pr.cost)) / SUM(o.total_amount), 2) AS overall_margin_percentage,
    ROUND(AVG(pr.margin_percentage)::numeric, 2) AS average_product_margin
FROM 
    orders o
JOIN 
    price_ranges pr ON o.product_id = pr.product_id
JOIN
    price_range_order pro ON pr.price_range = pro.price_range
WHERE 
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    pro.price_range, pro.sort_order
ORDER BY 
    pro.sort_order;
```

**SQL Query 2: Profit per Order by Price Range**
```sql
WITH price_ranges AS (
    SELECT
        product_id,
        price,
        cost,
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
),
order_profits AS (
    SELECT
        o.order_id,
        pro.price_range,
        pro.sort_order,
        SUM(o.quantity * (pr.price - pr.cost)) AS order_profit,
        SUM(o.total_amount) AS order_revenue
    FROM
        orders o
    JOIN 
        price_ranges pr ON o.product_id = pr.product_id
    JOIN
        price_range_order pro ON pr.price_range = pro.price_range
    WHERE 
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY
        o.order_id, pro.price_range, pro.sort_order
)
SELECT
    price_range,
    COUNT(order_id) AS number_of_orders,
    ROUND(AVG(order_profit)::numeric, 2) AS average_profit_per_order,
    ROUND(AVG(order_revenue)::numeric, 2) AS average_revenue_per_order,
    ROUND(SUM(order_profit)::numeric, 2) AS total_profit,
    ROUND(SUM(order_revenue)::numeric, 2) AS total_revenue
FROM
    order_profits
GROUP BY
    price_range, sort_order
ORDER BY
    sort_order;
```

**SQL Query 3: Effect of Discounts on Different Price Points**
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
),
discount_categories AS (
    SELECT
        order_id,
        product_id,
        CASE
            WHEN discount_percentage = 0 THEN 'No Discount'
            WHEN discount_percentage > 0 AND discount_percentage <= 10 THEN '1-10%'
            WHEN discount_percentage > 10 AND discount_percentage <= 20 THEN '11-20%'
            WHEN discount_percentage > 20 AND discount_percentage <= 30 THEN '21-30%'
            ELSE '30%+'
        END AS discount_category
    FROM orders
    WHERE status != 'Cancelled' AND is_returned = FALSE
    AND order_date >= CURRENT_DATE - INTERVAL '12 months'
)
SELECT
    pro.price_range,
    dc.discount_category,
    COUNT(o.order_id) AS number_of_orders,
    SUM(o.quantity) AS units_sold,
    ROUND(AVG(o.discount_percentage)::numeric, 2) AS average_discount,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue,
    ROUND(SUM(o.discount_amount)::numeric, 2) AS total_discount_amount
FROM
    orders o
JOIN
    discount_categories dc ON o.order_id = dc.order_id AND o.product_id = dc.product_id
JOIN
    price_ranges pr ON o.product_id = pr.product_id
JOIN
    price_range_order pro ON pr.price_range = pro.price_range
GROUP BY
    pro.price_range, dc.discount_category, pro.sort_order
ORDER BY
    pro.sort_order,
    CASE dc.discount_category
        WHEN 'No Discount' THEN 1
        WHEN '1-10%' THEN 2
        WHEN '11-20%' THEN 3
        WHEN '21-30%' THEN 4
        ELSE 5
    END;
```

### Chart 3: Price Elasticity Analysis

**Purpose**: Evaluates how sensitive sales volume is to price changes, helping determine optimal pricing strategies for different products.

**SQL Query 1: Price Change Impact Analysis**
```sql
-- This query assumes we have historical price change data
-- The following is a theoretical query assuming we had a product_price_history table

WITH price_changes AS (
    SELECT
        product_id,
        old_price,
        new_price,
        change_date,
        ((new_price - old_price) / old_price) * 100 AS price_change_percent
    FROM
        product_price_history
    WHERE
        change_date >= CURRENT_DATE - INTERVAL '24 months'
        AND old_price > 0
),
pre_change_sales AS (
    SELECT
        pc.product_id,
        pc.change_date,
        AVG(daily_sales.quantity) AS avg_daily_sales_before
    FROM
        price_changes pc
    CROSS JOIN LATERAL (
        SELECT
            o.order_date::date AS sale_date,
            SUM(o.quantity) AS quantity
        FROM
            orders o
        WHERE
            o.product_id = pc.product_id
            AND o.status != 'Cancelled' AND o.is_returned = FALSE
            AND o.order_date BETWEEN pc.change_date - INTERVAL '30 days' AND pc.change_date - INTERVAL '1 day'
        GROUP BY
            sale_date
    ) AS daily_sales
    GROUP BY
        pc.product_id, pc.change_date
),
post_change_sales AS (
    SELECT
        pc.product_id,
        pc.change_date,
        AVG(daily_sales.quantity) AS avg_daily_sales_after
    FROM
        price_changes pc
    CROSS JOIN LATERAL (
        SELECT
            o.order_date::date AS sale_date,
            SUM(o.quantity) AS quantity
        FROM
            orders o
        WHERE
            o.product_id = pc.product_id
            AND o.status != 'Cancelled' AND o.is_returned = FALSE
            AND o.order_date BETWEEN pc.change_date + INTERVAL '1 day' AND pc.change_date + INTERVAL '30 days'
        GROUP BY
            sale_date
    ) AS daily_sales
    GROUP BY
        pc.product_id, pc.change_date
)
SELECT
    p.product_id,
    p.name,
    p.category,
    pc.old_price,
    pc.new_price,
    pc.price_change_percent,
    pcs.avg_daily_sales_before,
    pcs2.avg_daily_sales_after,
    ((pcs2.avg_daily_sales_after - pcs.avg_daily_sales_before) / pcs.avg_daily_sales_before) * 100 AS sales_change_percent,
    -- Price elasticity calculation
    CASE
        WHEN pc.price_change_percent = 0 THEN NULL
        ELSE (((pcs2.avg_daily_sales_after - pcs.avg_daily_sales_before) / pcs.avg_daily_sales_before) * 100) / pc.price_change_percent
    END AS price_elasticity
FROM
    price_changes pc
JOIN
    products p ON pc.product_id = p.product_id
JOIN
    pre_change_sales pcs ON pc.product_id = pcs.product_id AND pc.change_date = pcs.change_date
JOIN
    post_change_sales pcs2 ON pc.product_id = pcs2.product_id AND pc.change_date = pcs2.change_date
WHERE
    pcs.avg_daily_sales_before > 0
ORDER BY
    ABS(CASE
        WHEN pc.price_change_percent = 0 THEN NULL
        ELSE (((pcs2.avg_daily_sales_after - pcs.avg_daily_sales_before) / pcs.avg_daily_sales_before) * 100) / pc.price_change_percent
    END) DESC;
```

**SQL Query 2: Price vs. Quantity Correlation by Category**
```sql
WITH product_sales AS (
    SELECT
        p.product_id,
        p.name,
        p.category,
        p.price,
        SUM(o.quantity) AS units_sold
    FROM
        products p
    JOIN
        orders o ON p.product_id = o.product_id
    WHERE
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY
        p.product_id, p.name, p.category, p.price
)
SELECT
    category,
    ROUND(CORR(price, units_sold)::numeric, 3) AS price_quantity_correlation,
    ROUND(AVG(price)::numeric, 2) AS average_price,
    ROUND(AVG(units_sold)::numeric, 0) AS average_units_sold,
    COUNT(*) AS number_of_products,
    ROUND(MIN(price)::numeric, 2) AS min_price,
    ROUND(MAX(price)::numeric, 2) AS max_price,
    ROUND(MIN(units_sold)::numeric, 0) AS min_units_sold,
    ROUND(MAX(units_sold)::numeric, 0) AS max_units_sold
FROM
    product_sales
GROUP BY
    category
ORDER BY
    price_quantity_correlation;
```

**SQL Query 3: Price Point Performance Comparison Within Categories**
```sql
WITH category_price_quintiles AS (
    SELECT
        category,
        product_id,
        price,
        NTILE(5) OVER (PARTITION BY category ORDER BY price) AS price_quintile
    FROM
        products
),
quintile_labels AS (
    SELECT
        category,
        price_quintile,
        MIN(price) AS min_price,
        MAX(price) AS max_price,
        category || ' (Q' || price_quintile || ': $' || ROUND(MIN(price)::numeric, 2) || '-$' || ROUND(MAX(price)::numeric, 2) || ')' AS price_tier_label
    FROM
        category_price_quintiles
    GROUP BY
        category, price_quintile
)
SELECT
    ql.price_tier_label,
    ql.category,
    ql.price_quintile,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    SUM(o.quantity) AS units_sold,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue,
    ROUND(SUM(o.quantity * (p.price - p.cost))::numeric, 2) AS total_profit,
    ROUND(100 * SUM(o.quantity * (p.price - p.cost)) / SUM(o.total_amount), 2) AS profit_margin_percentage
FROM
    orders o
JOIN
    products p ON o.product_id = p.product_id
JOIN
    category_price_quintiles cpq ON p.product_id = cpq.product_id
JOIN
    quintile_labels ql ON cpq.category = ql.category AND cpq.price_quintile = ql.price_quintile
WHERE
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY
    ql.price_tier_label, ql.category, ql.price_quintile
ORDER BY
    ql.category, ql.price_quintile;
```

## YouTube Script: Optimizing Price-Point Performance

Hey everyone! Welcome back to our product analytics series. Today we're diving into one of the most fascinating aspects of retail strategy: Price-Point Performance. Pricing is both an art and a science, and the data we're about to explore can help you master both dimensions.

Let's start with our first chart: Sales Volume by Price Range. This gives us a fundamental understanding of how your products are selling across different price brackets. Our first query breaks down sales into price ranges like "Under $25," "$25-$49.99," and so on, showing the number of orders, units sold, revenue, and average order value for each bracket.

What makes this query particularly useful is how it reveals customer price sensitivity. For example, you might discover that while your "Under $25" category drives the highest volume of units, your "$100-$199.99" bracket actually generates more total revenue. This insight immediately informs where you might want to expand your product catalog.

The second query takes this analysis further by tracking how these price ranges perform over time. This monthly breakdown is incredibly valuable for spotting seasonal trends specific to price points. You might find that higher-priced items spike during holiday seasons while budget items maintain more consistent sales throughout the year.

Our third query in this section examines price range performance by product category. This intersection analysis is powerful because price sensitivity varies dramatically across categories. A $50 price point might be considered "premium" in one category but "budget" in another. This query helps you understand the unique price dynamics within each product category you sell.

Moving to our second chart, Price Point Profitability Analysis takes us beyond just sales volume to understand the critical relationship between price and profit. The first query here calculates profit margin by price range, showing both the overall margin percentage and the average product margin within each bracket.

This distinction is important because the overall margin factors in sales volume, while the average product margin tells you about individual product pricing strategy. Sometimes these tell different stories – for instance, your highest-margin products might not be your biggest profit generators if they don't sell in sufficient volume.

The second query calculates profit per order by price range. This perspective is valuable because it accounts for the fact that different price ranges might have different average quantities per order. For example, customers might buy multiple units of lower-priced items but just one unit of a higher-priced item.

The third query in this section examines how discounts affect different price points. This is fascinating because customer response to discounts often varies by price range. Budget items might see massive volume increases with small discounts, while premium products might need deeper discounts to meaningfully impact buying behavior. This query helps identify the optimal discount strategy for each price segment.

Our third chart focuses on Price Elasticity Analysis, which is about understanding exactly how sensitive sales are to price changes. The first query here would ideally analyze the impact of historical price changes, calculating actual price elasticity values. This requires historical price data that we don't have in our current schema, but in a real implementation, this would be invaluable for predicting how future price changes might affect sales.

The second query calculates the correlation between price and quantity sold for each product category. A strong negative correlation suggests high price sensitivity (raising prices significantly reduces sales), while a weak correlation suggests other factors might be more important than price in driving purchase decisions. This helps prioritize which categories might benefit most from price optimization.

The third query provides a detailed comparison of how different price points perform within each category. It divides products into quintiles (fifths) based on price within their category, and then compares their performance on orders, units, revenue, and profit. This granular analysis helps identify the "sweet spots" for pricing within each category.

What makes these queries particularly valuable for business intelligence is how they connect pricing decisions directly to business outcomes. They don't just tell you what's selling at what price – they help you understand the complex relationships between price points, sales volume, revenue, and profitability.

For example, the Price vs. Quantity Correlation query doesn't just show correlation coefficients; it contextualizes them with average prices and sales volumes, giving you the full picture of each category's pricing dynamics. Similarly, the discount impact analysis helps you understand not just how much discount to offer, but which price points respond best to promotions.

The goal of price-point analysis isn't just to set prices – it's to optimize your entire pricing strategy for maximum business impact. These queries help you identify where to adjust prices up or down, where to focus promotional efforts, and how to structure your product catalog across different price tiers.

Remember that pricing is never one-size-fits-all. The optimal strategy varies by category, customer segment, season, and competitive environment. The queries we've explored today help you navigate this complexity with data-driven insights.

In our next video, we'll dive into Product Return Analysis, where we'll uncover patterns in returns that can help improve product quality and customer satisfaction. See you then!
