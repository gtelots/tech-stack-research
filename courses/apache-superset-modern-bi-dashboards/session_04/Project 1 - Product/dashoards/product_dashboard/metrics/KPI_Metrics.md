# Key Product KPI Metrics

## Business Context
Tracking key performance indicators (KPIs) provides a quick snapshot of overall product performance. These simple metrics offer at-a-glance insights into your product catalog, sales trends, and inventory status, helping executives and team members quickly assess the current state of the business.

## Dashboard Charts

### Chart 1: Total Products Overview

**Purpose**: Displays essential product catalog statistics, providing a quick understanding of your total product offerings.

**SQL Query 1: Total Active Products**
```sql
SELECT 
    COUNT(*) AS total_products,
    COUNT(*) FILTER (WHERE stock_quantity > 0) AS products_in_stock,
    COUNT(*) FILTER (WHERE stock_quantity = 0) AS out_of_stock_products,
    ROUND(100.0 * COUNT(*) FILTER (WHERE stock_quantity = 0) / NULLIF(COUNT(*), 0), 1) AS out_of_stock_percentage
FROM 
    products;
```

**SQL Query 2: Products by Category**
```sql
SELECT 
    category,
    COUNT(*) AS product_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM products), 1) AS percentage_of_total
FROM 
    products
GROUP BY 
    category
ORDER BY 
    product_count DESC;
```

**SQL Query 3: Products by Price Range**
```sql
SELECT
    CASE
        WHEN price < 25 THEN 'Under $25'
        WHEN price >= 25 AND price < 50 THEN '$25-$49.99'
        WHEN price >= 50 AND price < 100 THEN '$50-$99.99'
        WHEN price >= 100 AND price < 200 THEN '$100-$199.99'
        ELSE '$200+'
    END AS price_range,
    COUNT(*) AS product_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM products), 1) AS percentage_of_total
FROM 
    products
GROUP BY 
    price_range
ORDER BY 
    CASE 
        WHEN price_range = 'Under $25' THEN 1
        WHEN price_range = '$25-$49.99' THEN 2
        WHEN price_range = '$50-$99.99' THEN 3
        WHEN price_range = '$100-$199.99' THEN 4
        ELSE 5
    END;
```

## YouTube Script: Understanding Product KPI Metrics

Hey everyone! Today we're looking at some of the most important high-level metrics for your product catalog. These simple but powerful numbers give you an instant snapshot of your product portfolio.

Let's start with our Total Products Overview. The first query here is super straightforward but gives you critical information at a glance. It shows your total product count, how many products you currently have in stock, how many are out of stock, and what percentage of your catalog is unavailable for purchase right now.

This is information you'll want to check daily. If your out-of-stock percentage starts creeping up over 10-15%, that's a red flag that needs immediate attention. It means you're potentially losing sales and disappointing customers.

The second query breaks down your product catalog by category. This gives you a clear picture of your product mix and where you might be over or under-represented. For example, if Electronics makes up 40% of your catalog but only generates 20% of your revenue, that might indicate an imbalance worth investigating.

The third query segments your products by price range. This is crucial for understanding your price positioning in the market. Are you primarily a budget retailer with most products under $50? Or do you specialize in premium offerings over $100? This breakdown helps confirm whether your actual product mix aligns with your brand positioning and target market.

What makes these metrics so valuable is their simplicity. While deeper analyses are necessary for specific decisions, these top-level numbers provide an essential daily pulse check on your product catalog health. They're perfect for executive dashboards and morning stand-up meetings where you need quick insights without diving into complex analyses.

Remember that these metrics are most useful when tracked over time. A sudden drop in total active products or spike in out-of-stock percentage can signal inventory problems that need immediate attention. Similarly, shifts in your category or price distribution might indicate changing buying patterns from your purchasing team.

In our next video, we'll look at Monthly Sales Metrics that provide similar high-level insights into your sales performance. Stay tuned!
