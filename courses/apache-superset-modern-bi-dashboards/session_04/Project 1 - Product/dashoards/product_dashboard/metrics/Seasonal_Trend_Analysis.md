# Seasonal & Trend Analysis

## Business Context
Understanding how product performance changes over time is essential for anticipating customer demand, planning inventory, and optimizing marketing strategies. This analysis identifies seasonal patterns, emerging trends, and changing customer preferences to support proactive business planning.

## Dashboard Charts

### Chart 1: Monthly Sales Trends

**Purpose**: Visualizes sales patterns over time to identify seasonal peaks, growth trends, and potential areas of concern.

**SQL Query 1: Monthly Sales by Category**
```sql
SELECT 
    DATE_TRUNC('month', o.order_date) AS month,
    p.category,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    SUM(o.quantity) AS units_sold,
    ROUND(SUM(o.total_amount)::numeric, 2) AS total_revenue
FROM 
    orders o
JOIN 
    products p ON o.product_id = p.product_id
WHERE 
    o.status != 'Cancelled' AND o.is_returned = FALSE
    AND o.order_date >= CURRENT_DATE - INTERVAL '24 months'
GROUP BY 
    month, p.category
ORDER BY 
    month, p.category;
```

**SQL Query 2: Year-over-Year Growth by Month**
```sql
WITH monthly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM o.order_date) AS year,
        EXTRACT(MONTH FROM o.order_date) AS month,
        SUM(o.total_amount) AS total_revenue
    FROM 
        orders o
    WHERE 
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '24 months'
    GROUP BY 
        year, month
),
current_year_sales AS (
    SELECT 
        month,
        total_revenue AS current_year_revenue
    FROM 
        monthly_sales
    WHERE 
        year = EXTRACT(YEAR FROM CURRENT_DATE)
),
previous_year_sales AS (
    SELECT 
        month,
        total_revenue AS previous_year_revenue
    FROM 
        monthly_sales
    WHERE 
        year = EXTRACT(YEAR FROM CURRENT_DATE) - 1
)
SELECT 
    TO_CHAR(TO_DATE(cys.month::text, 'MM'), 'Month') AS month_name,
    cys.month,
    ROUND(cys.current_year_revenue::numeric, 2) AS current_year_revenue,
    ROUND(pys.previous_year_revenue::numeric, 2) AS previous_year_revenue,
    ROUND(((cys.current_year_revenue - pys.previous_year_revenue) / pys.previous_year_revenue * 100)::numeric, 2) AS yoy_growth_percent
FROM 
    current_year_sales cys
JOIN 
    previous_year_sales pys ON cys.month = pys.month
ORDER BY 
    cys.month;
```

**SQL Query 3: Moving Average Trend Analysis**
```sql
WITH daily_sales AS (
    SELECT 
        o.order_date::date AS sale_date,
        SUM(o.total_amount) AS daily_revenue
    FROM 
        orders o
    WHERE 
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        sale_date
),
moving_averages AS (
    SELECT 
        sale_date,
        daily_revenue,
        AVG(daily_revenue) OVER (
            ORDER BY sale_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS seven_day_moving_avg,
        AVG(daily_revenue) OVER (
            ORDER BY sale_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS thirty_day_moving_avg
    FROM 
        daily_sales
)
SELECT 
    sale_date,
    ROUND(daily_revenue::numeric, 2) AS daily_revenue,
    ROUND(seven_day_moving_avg::numeric, 2) AS seven_day_moving_avg,
    ROUND(thirty_day_moving_avg::numeric, 2) AS thirty_day_moving_avg
FROM 
    moving_averages
WHERE 
    -- Ensure we have enough data for both moving averages
    sale_date >= (SELECT MIN(sale_date) FROM daily_sales) + INTERVAL '30 days'
ORDER BY 
    sale_date;
```

### Chart 2: Seasonal Product Performance

**Purpose**: Identifies which products perform best in different seasons, enabling targeted inventory planning and marketing.

**SQL Query 1: Quarterly Product Performance**
```sql
WITH quarterly_sales AS (
    SELECT 
        p.product_id,
        p.name,
        p.category,
        EXTRACT(YEAR FROM o.order_date) AS year,
        EXTRACT(QUARTER FROM o.order_date) AS quarter,
        SUM(o.quantity) AS units_sold,
        SUM(o.total_amount) AS total_revenue
    FROM 
        orders o
    JOIN 
        products p ON o.product_id = p.product_id
    WHERE 
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '24 months'
    GROUP BY 
        p.product_id, p.name, p.category, year, quarter
),
product_totals AS (
    SELECT 
        product_id,
        SUM(units_sold) AS total_units_sold,
        SUM(total_revenue) AS total_revenue
    FROM 
        quarterly_sales
    GROUP BY 
        product_id
),
quarterly_proportions AS (
    SELECT 
        qs.product_id,
        qs.name,
        qs.category,
        qs.year,
        qs.quarter,
        qs.units_sold,
        qs.total_revenue,
        pt.total_units_sold,
        pt.total_revenue AS product_total_revenue,
        ROUND(100.0 * qs.units_sold / NULLIF(pt.total_units_sold, 0), 2) AS percent_of_annual_units,
        ROUND(100.0 * qs.total_revenue / NULLIF(pt.total_revenue, 0), 2) AS percent_of_annual_revenue
    FROM 
        quarterly_sales qs
    JOIN 
        product_totals pt ON qs.product_id = pt.product_id
)
SELECT 
    product_id,
    name,
    category,
    -- Combine year and quarter for readability
    year || '-Q' || quarter AS year_quarter,
    units_sold,
    ROUND(total_revenue::numeric, 2) AS quarterly_revenue,
    percent_of_annual_units,
    percent_of_annual_revenue,
    -- Identify seasonal peaks
    CASE 
        WHEN percent_of_annual_units > 40 THEN 'Strong Seasonal Peak'
        WHEN percent_of_annual_units > 30 THEN 'Moderate Seasonal Peak'
        WHEN percent_of_annual_units BETWEEN 20 AND 30 THEN 'Balanced'
        ELSE 'Low Season'
    END AS seasonality_classification
FROM 
    quarterly_proportions
WHERE 
    total_units_sold >= 50  -- Minimum threshold for significant products
ORDER BY 
    name, year, quarter;
```

**SQL Query 2: Monthly Category Seasonality Index**
```sql
WITH monthly_category_sales AS (
    SELECT 
        p.category,
        EXTRACT(MONTH FROM o.order_date) AS month,
        SUM(o.quantity) AS units_sold
    FROM 
        orders o
    JOIN 
        products p ON o.product_id = p.product_id
    WHERE 
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '24 months'
    GROUP BY 
        p.category, month
),
category_totals AS (
    SELECT 
        category,
        SUM(units_sold) / 12.0 AS avg_monthly_units  -- Average across 12 months
    FROM 
        monthly_category_sales
    GROUP BY 
        category
)
SELECT 
    mcs.category,
    mcs.month,
    TO_CHAR(TO_DATE(mcs.month::text, 'MM'), 'Month') AS month_name,
    mcs.units_sold,
    ROUND(ct.avg_monthly_units::numeric, 2) AS avg_monthly_units,
    ROUND((mcs.units_sold / NULLIF(ct.avg_monthly_units, 0))::numeric, 2) AS seasonality_index,
    CASE
        WHEN mcs.units_sold > ct.avg_monthly_units * 1.5 THEN 'High Season'
        WHEN mcs.units_sold < ct.avg_monthly_units * 0.5 THEN 'Low Season'
        ELSE 'Regular Season'
    END AS season_classification
FROM 
    monthly_category_sales mcs
JOIN 
    category_totals ct ON mcs.category = ct.category
ORDER BY 
    mcs.category, mcs.month;
```

**SQL Query 3: Top Selling Products by Season**
```sql
WITH seasonal_sales AS (
    SELECT 
        p.product_id,
        p.name,
        p.category,
        CASE
            WHEN EXTRACT(MONTH FROM o.order_date) IN (12, 1, 2) THEN 'Winter'
            WHEN EXTRACT(MONTH FROM o.order_date) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM o.order_date) IN (6, 7, 8) THEN 'Summer'
            ELSE 'Fall'
        END AS season,
        SUM(o.quantity) AS units_sold,
        SUM(o.total_amount) AS total_revenue
    FROM 
        orders o
    JOIN 
        products p ON o.product_id = p.product_id
    WHERE 
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        p.product_id, p.name, p.category, season
),
ranked_products AS (
    SELECT 
        product_id,
        name,
        category,
        season,
        units_sold,
        total_revenue,
        RANK() OVER (PARTITION BY season ORDER BY units_sold DESC) AS rank_in_season
    FROM 
        seasonal_sales
)
SELECT 
    season,
    product_id,
    name,
    category,
    units_sold,
    ROUND(total_revenue::numeric, 2) AS seasonal_revenue,
    -- Calculate what percentage of a product's annual sales occur in this season
    ROUND(100.0 * units_sold / (
        SELECT SUM(units_sold) FROM seasonal_sales ss 
        WHERE ss.product_id = rp.product_id
    ), 2) AS percent_of_annual_sales
FROM 
    ranked_products rp
WHERE 
    rank_in_season <= 10  -- Top 10 products per season
ORDER BY 
    CASE 
        WHEN season = 'Winter' THEN 1
        WHEN season = 'Spring' THEN 2
        WHEN season = 'Summer' THEN 3
        ELSE 4
    END,
    rank_in_season;
```

### Chart 3: Emerging Trends and Product Momentum

**Purpose**: Identifies products with rapidly changing sales trajectories, highlighting emerging winners and potential phase-outs.

**SQL Query 1: Products with Highest Growth Rate**
```sql
WITH monthly_product_sales AS (
    SELECT 
        p.product_id,
        p.name,
        p.category,
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(o.quantity) AS units_sold,
        SUM(o.total_amount) AS total_revenue
    FROM 
        orders o
    JOIN 
        products p ON o.product_id = p.product_id
    WHERE 
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        p.product_id, p.name, p.category, month
),
product_growth AS (
    SELECT 
        product_id,
        name,
        category,
        -- Most recent month's sales
        SUM(CASE WHEN month = (SELECT MAX(month) FROM monthly_product_sales) 
                THEN units_sold ELSE 0 END) AS latest_month_units,
        SUM(CASE WHEN month = (SELECT MAX(month) FROM monthly_product_sales) 
                THEN total_revenue ELSE 0 END) AS latest_month_revenue,
        -- Compare with previous month
        SUM(CASE WHEN month = (SELECT MAX(month) FROM monthly_product_sales) - INTERVAL '1 month' 
                THEN units_sold ELSE 0 END) AS previous_month_units,
        SUM(CASE WHEN month = (SELECT MAX(month) FROM monthly_product_sales) - INTERVAL '1 month' 
                THEN total_revenue ELSE 0 END) AS previous_month_revenue,
        -- First month in the period for longer-term growth
        SUM(CASE WHEN month = (SELECT MIN(month) FROM monthly_product_sales) 
                THEN units_sold ELSE 0 END) AS first_month_units,
        SUM(CASE WHEN month = (SELECT MIN(month) FROM monthly_product_sales) 
                THEN total_revenue ELSE 0 END) AS first_month_revenue,
        -- Total over the entire period
        SUM(units_sold) AS total_units_sold,
        SUM(total_revenue) AS total_revenue
    FROM 
        monthly_product_sales
    GROUP BY 
        product_id, name, category
    HAVING 
        -- Minimum sales threshold to filter out noise
        SUM(units_sold) >= 50
)
SELECT 
    product_id,
    name,
    category,
    ROUND(latest_month_units::numeric, 0) AS latest_month_units,
    ROUND(latest_month_revenue::numeric, 2) AS latest_month_revenue,
    ROUND(previous_month_units::numeric, 0) AS previous_month_units,
    ROUND(previous_month_revenue::numeric, 2) AS previous_month_revenue,
    -- Month-over-Month growth
    CASE 
        WHEN previous_month_units = 0 THEN NULL  -- Avoid division by zero
        ELSE ROUND(100.0 * (latest_month_units - previous_month_units) / previous_month_units, 2)
    END AS mom_units_growth_percent,
    -- Period growth (first month to latest month)
    CASE 
        WHEN first_month_units = 0 THEN NULL  -- Avoid division by zero
        ELSE ROUND(100.0 * (latest_month_units - first_month_units) / first_month_units, 2)
    END AS period_units_growth_percent,
    ROUND(total_units_sold::numeric, 0) AS total_units_sold,
    ROUND(total_revenue::numeric, 2) AS total_revenue
FROM 
    product_growth
WHERE 
    latest_month_units > 0 AND previous_month_units > 0  -- Ensure both months have data
ORDER BY 
    mom_units_growth_percent DESC NULLS LAST
LIMIT 20;
```

**SQL Query 2: Products with Declining Sales**
```sql
WITH monthly_product_sales AS (
    SELECT 
        p.product_id,
        p.name,
        p.category,
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(o.quantity) AS units_sold,
        SUM(o.total_amount) AS total_revenue
    FROM 
        orders o
    JOIN 
        products p ON o.product_id = p.product_id
    WHERE 
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        p.product_id, p.name, p.category, month
),
product_decline AS (
    SELECT 
        product_id,
        name,
        category,
        -- Most recent month's sales
        SUM(CASE WHEN month = (SELECT MAX(month) FROM monthly_product_sales) 
                THEN units_sold ELSE 0 END) AS latest_month_units,
        SUM(CASE WHEN month = (SELECT MAX(month) FROM monthly_product_sales) 
                THEN total_revenue ELSE 0 END) AS latest_month_revenue,
        -- Compare with previous month
        SUM(CASE WHEN month = (SELECT MAX(month) FROM monthly_product_sales) - INTERVAL '1 month' 
                THEN units_sold ELSE 0 END) AS previous_month_units,
        SUM(CASE WHEN month = (SELECT MAX(month) FROM monthly_product_sales) - INTERVAL '1 month' 
                THEN total_revenue ELSE 0 END) AS previous_month_revenue,
        -- First month in the period for longer-term trend
        SUM(CASE WHEN month = (SELECT MIN(month) FROM monthly_product_sales) 
                THEN units_sold ELSE 0 END) AS first_month_units,
        SUM(CASE WHEN month = (SELECT MIN(month) FROM monthly_product_sales) 
                THEN total_revenue ELSE 0 END) AS first_month_revenue,
        -- Current inventory
        MAX(p.stock_quantity) AS current_stock,
        -- Total over the entire period
        SUM(units_sold) AS total_units_sold,
        SUM(total_revenue) AS total_revenue
    FROM 
        monthly_product_sales mps
    JOIN 
        products p ON mps.product_id = p.product_id
    GROUP BY 
        product_id, name, category
    HAVING 
        -- Minimum historical sales to filter out noise
        SUM(units_sold) >= 50
)
SELECT 
    product_id,
    name,
    category,
    ROUND(latest_month_units::numeric, 0) AS latest_month_units,
    ROUND(latest_month_revenue::numeric, 2) AS latest_month_revenue,
    ROUND(previous_month_units::numeric, 0) AS previous_month_units,
    -- Month-over-Month decline
    CASE 
        WHEN previous_month_units = 0 THEN NULL  -- Avoid division by zero
        ELSE ROUND(100.0 * (latest_month_units - previous_month_units) / previous_month_units, 2)
    END AS mom_units_growth_percent,
    -- Period decline (first month to latest month)
    CASE 
        WHEN first_month_units = 0 THEN NULL  -- Avoid division by zero
        ELSE ROUND(100.0 * (latest_month_units - first_month_units) / first_month_units, 2)
    END AS period_units_growth_percent,
    current_stock,
    -- At current sales rate, how many months of inventory do we have?
    CASE 
        WHEN latest_month_units = 0 THEN NULL  -- Avoid division by zero
        ELSE ROUND((current_stock / latest_month_units)::numeric, 1)
    END AS months_of_inventory_at_current_rate,
    ROUND(total_units_sold::numeric, 0) AS total_units_sold,
    ROUND(total_revenue::numeric, 2) AS total_revenue
FROM 
    product_decline
WHERE 
    latest_month_units > 0  -- Ensure latest month has some sales
    AND (
        (latest_month_units < previous_month_units)  -- Month-over-month decline
        OR 
        (latest_month_units < first_month_units)     -- Overall period decline
    )
ORDER BY 
    CASE 
        WHEN previous_month_units = 0 THEN NULL  -- Avoid division by zero
        ELSE (latest_month_units - previous_month_units) / previous_month_units
    END ASC NULLS LAST
LIMIT 20;
```

**SQL Query 3: Category Trend Analysis**
```sql
WITH monthly_category_sales AS (
    SELECT 
        p.category,
        DATE_TRUNC('month', o.order_date) AS month,
        COUNT(DISTINCT p.product_id) AS active_products,
        SUM(o.quantity) AS units_sold,
        SUM(o.total_amount) AS total_revenue
    FROM 
        orders o
    JOIN 
        products p ON o.product_id = p.product_id
    WHERE 
        o.status != 'Cancelled' AND o.is_returned = FALSE
        AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        p.category, month
),
category_growth AS (
    SELECT 
        category,
        -- For trend calculation, we need multiple points in time
        ARRAY_AGG(month ORDER BY month) AS months,
        ARRAY_AGG(units_sold ORDER BY month) AS monthly_units,
        ARRAY_AGG(total_revenue ORDER BY month) AS monthly_revenue,
        -- First and last month for simple growth calculation
        MIN(month) AS first_month,
        MAX(month) AS last_month,
        SUM(CASE WHEN month = MIN(month) OVER (PARTITION BY category) 
                THEN units_sold ELSE 0 END) AS first_month_units,
        SUM(CASE WHEN month = MAX(month) OVER (PARTITION BY category) 
                THEN units_sold ELSE 0 END) AS last_month_units,
        SUM(CASE WHEN month = MIN(month) OVER (PARTITION BY category) 
                THEN total_revenue ELSE 0 END) AS first_month_revenue,
        SUM(CASE WHEN month = MAX(month) OVER (PARTITION BY category) 
                THEN total_revenue ELSE 0 END) AS last_month_revenue,
        AVG(active_products) AS avg_active_products,
        SUM(units_sold) AS total_units_sold,
        SUM(total_revenue) AS total_revenue
    FROM 
        monthly_category_sales
    GROUP BY 
        category
)
SELECT 
    category,
    ROUND(first_month_units::numeric, 0) AS first_month_units,
    ROUND(last_month_units::numeric, 0) AS last_month_units,
    ROUND(first_month_revenue::numeric, 2) AS first_month_revenue,
    ROUND(last_month_revenue::numeric, 2) AS last_month_revenue,
    -- Calculate growth over the period
    CASE 
        WHEN first_month_units = 0 THEN NULL
        ELSE ROUND(100.0 * (last_month_units - first_month_units) / first_month_units, 2)
    END AS units_growth_percent,
    CASE 
        WHEN first_month_revenue = 0 THEN NULL
        ELSE ROUND(100.0 * (last_month_revenue - first_month_revenue) / first_month_revenue, 2)
    END AS revenue_growth_percent,
    -- Simplified linear regression for trend strength (slope)
    ROUND(
        REGR_SLOPE(
            units_sold, 
            EXTRACT(EPOCH FROM (month - first_month)) / 86400
        ) OVER (PARTITION BY category)::numeric, 
        2
    ) AS units_daily_trend,
    ROUND(
        REGR_SLOPE(
            total_revenue, 
            EXTRACT(EPOCH FROM (month - first_month)) / 86400
        ) OVER (PARTITION BY category)::numeric, 
        2
    ) AS revenue_daily_trend,
    -- Growth classification
    CASE 
        WHEN last_month_units > first_month_units * 1.5 THEN 'Strong Growth'
        WHEN last_month_units > first_month_units * 1.1 THEN 'Moderate Growth'
        WHEN last_month_units BETWEEN first_month_units * 0.9 AND first_month_units * 1.1 THEN 'Stable'
        WHEN last_month_units < first_month_units * 0.5 THEN 'Sharp Decline'
        ELSE 'Moderate Decline'
    END AS growth_classification,
    ROUND(avg_active_products::numeric, 0) AS avg_active_products,
    ROUND(total_units_sold::numeric, 0) AS total_units_sold,
    ROUND(total_revenue::numeric, 2) AS total_revenue
FROM 
    category_growth,
    LATERAL UNNEST(months, monthly_units, monthly_revenue) AS u(month, units_sold, total_revenue)
GROUP BY 
    category, first_month, last_month, first_month_units, last_month_units, 
    first_month_revenue, last_month_revenue, avg_active_products, 
    total_units_sold, total_revenue
ORDER BY 
    units_growth_percent DESC NULLS LAST;
```

## YouTube Script: Mastering Seasonal & Trend Analysis

Welcome back everyone! Today we're diving into one of the most powerful aspects of retail analytics: Seasonal and Trend Analysis. Understanding how your sales patterns change over time is absolutely essential for planning inventory, optimizing marketing, and staying ahead of customer preferences.

Let's start with our first chart: Monthly Sales Trends. Our first query tracks monthly sales by category over a 24-month period. What makes this query particularly useful is that it breaks down performance by both units sold and revenue, which helps distinguish between volume changes and value changes. For example, you might see unit sales remain stable while revenue increases, indicating successful upselling or price increases.

The second query calculates year-over-year growth by month, directly comparing this year's performance to the same month last year. This perspective is crucial because it automatically accounts for normal seasonal variations. A 20% drop from December to January might look alarming until you realize the same drop happened last year due to normal post-holiday patterns. YOY analysis cuts through these seasonal patterns to reveal true business growth or contraction.

The third query in this section implements moving averages for trend analysis. It calculates both 7-day and 30-day moving averages of daily revenue, which helps smooth out day-to-day fluctuations and reveal the underlying trends. The beauty of moving averages is that they adjust automatically as new data comes in, making them perfect for ongoing monitoring in a dashboard environment.

Moving to our second chart, Seasonal Product Performance digs deeper into how specific products perform in different time periods. The first query analyzes quarterly product performance, calculating what percentage of a product's annual sales occur in each quarter. It even includes a "seasonality classification" that identifies products with strong seasonal peaks – those that generate over 40% of their annual sales in a single quarter.

This information is gold for inventory planning. A product with balanced year-round sales needs consistent stocking, while a product with a strong Q4 peak (like holiday items) requires a completely different inventory strategy.

The second query calculates a "seasonality index" for each category by month. This index compares a month's sales to the category's average monthly performance, making it easy to identify high and low seasons across your product catalog. A value of 2.0 means the category sells twice as much as average in that month, while 0.5 means it sells only half as much.

The third query identifies top-selling products by season, grouping months into Winter, Spring, Summer, and Fall. This perspective is particularly valuable for merchandising and marketing planning. It helps you feature the right products at the right time and optimize your promotional calendar around seasonal winners.

Our final chart focuses on Emerging Trends and Product Momentum – identifying products that are rapidly growing or declining. The first query ranks products by their month-over-month growth rate, highlighting emerging winners that might deserve additional investment or promotion. It calculates both short-term (month-over-month) and medium-term (over the full 6-month period) growth rates, giving you multiple perspectives on product momentum.

The second query identifies products with declining sales, which is equally important for inventory management. It not only shows which products are losing momentum but also calculates how many months of inventory you have at the current sales rate. This helps prioritize potential clearance actions or price adjustments for slow-moving stock.

The third query provides a comprehensive category trend analysis, using statistical regression to calculate the strength and direction of trends. It goes beyond simple growth percentages to measure the consistency of growth or decline, and classifies categories from "Strong Growth" to "Sharp Decline" based on their performance trajectory.

What makes these queries so powerful for business intelligence is how they transform time-series data into actionable insights. They don't just tell you what happened when – they help you understand the patterns and rhythms of your business, enabling more proactive planning.

For example, the seasonal product analysis doesn't just identify which products sell well in winter; it quantifies exactly what percentage of annual sales occur in each season, which directly informs inventory purchasing decisions. Similarly, the category trend analysis doesn't just show growth rates; it uses regression analysis to measure trend strength, helping distinguish between consistent trends and random fluctuations.

The goal of seasonal and trend analysis isn't just to describe past performance – it's to enable better forecasting and planning. By understanding how your products perform over time, you can anticipate customer needs, optimize inventory levels, time marketing campaigns effectively, and make more informed decisions about product assortment.

Remember that retail is inherently cyclical, with patterns that repeat annually, quarterly, monthly, and even weekly. Recognizing these patterns lets you separate the signal from the noise in your sales data, distinguishing between normal seasonal variations and meaningful changes in underlying business performance.

That wraps up our tour of the five key components of our Product Dashboard. We've explored Revenue and Profitability Analysis, Inventory Health Assessment, Price-Point Performance, Product Return Analysis, and now Seasonal and Trend Analysis. Together, these analyses provide a comprehensive view of your product landscape, enabling data-driven decisions that drive business success.

Thanks for joining me on this journey through product analytics. I hope you've gained valuable insights that you can apply to your own business. Until next time!
