# SQL Answers to 100 Business Analytics Questions

## Sales Performance Analysis

**1. What is the total sales amount across all orders?**
```sql
SELECT 
    SUM(sales) as total_sales
FROM 
    superstore;
```

**2. What is the average sales amount per order?**
```sql
SELECT 
    AVG(total_order_sales) as avg_order_sales
FROM (
    SELECT 
        order_id, 
        SUM(sales) as total_order_sales
    FROM 
        superstore
    GROUP BY 
        order_id
) as order_totals;
```

**3. What are the total sales by product category?**
```sql
SELECT 
    category, 
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    category
ORDER BY 
    total_sales DESC;
```

**4. What are the total sales by product sub-category?**
```sql
SELECT 
    sub_category, 
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    sub_category
ORDER BY 
    total_sales DESC;
```

**5. Which products have the highest total sales?**
```sql
SELECT 
    product_name, 
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    product_name
ORDER BY 
    total_sales DESC
LIMIT 10;
```

**6. What are the monthly sales trends over the entire period?**
```sql
SELECT 
    EXTRACT(YEAR FROM order_date) as year,
    EXTRACT(MONTH FROM order_date) as month,
    SUM(sales) as monthly_sales
FROM 
    superstore
GROUP BY 
    EXTRACT(YEAR FROM order_date),
    EXTRACT(MONTH FROM order_date)
ORDER BY 
    year, month;
```

**7. What are the quarterly sales trends over the entire period?**
```sql
SELECT 
    EXTRACT(YEAR FROM order_date) as year,
    EXTRACT(QUARTER FROM order_date) as quarter,
    SUM(sales) as quarterly_sales
FROM 
    superstore
GROUP BY 
    EXTRACT(YEAR FROM order_date),
    EXTRACT(QUARTER FROM order_date)
ORDER BY 
    year, quarter;
```

**8. What are the yearly sales trends?**
```sql
SELECT 
    EXTRACT(YEAR FROM order_date) as year,
    SUM(sales) as yearly_sales
FROM 
    superstore
GROUP BY 
    EXTRACT(YEAR FROM order_date)
ORDER BY 
    year;
```

**9. Which days of the week have the highest sales?**
```sql
SELECT 
    EXTRACT(DOW FROM order_date) as day_of_week,
    CASE 
        WHEN EXTRACT(DOW FROM order_date) = 0 THEN 'Sunday'
        WHEN EXTRACT(DOW FROM order_date) = 1 THEN 'Monday'
        WHEN EXTRACT(DOW FROM order_date) = 2 THEN 'Tuesday'
        WHEN EXTRACT(DOW FROM order_date) = 3 THEN 'Wednesday'
        WHEN EXTRACT(DOW FROM order_date) = 4 THEN 'Thursday'
        WHEN EXTRACT(DOW FROM order_date) = 5 THEN 'Friday'
        WHEN EXTRACT(DOW FROM order_date) = 6 THEN 'Saturday'
    END as day_name,
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    EXTRACT(DOW FROM order_date)
ORDER BY 
    total_sales DESC;
```

**10. Which months have the highest average sales?**
```sql
SELECT 
    EXTRACT(MONTH FROM order_date) as month,
    CASE 
        WHEN EXTRACT(MONTH FROM order_date) = 1 THEN 'January'
        WHEN EXTRACT(MONTH FROM order_date) = 2 THEN 'February'
        WHEN EXTRACT(MONTH FROM order_date) = 3 THEN 'March'
        WHEN EXTRACT(MONTH FROM order_date) = 4 THEN 'April'
        WHEN EXTRACT(MONTH FROM order_date) = 5 THEN 'May'
        WHEN EXTRACT(MONTH FROM order_date) = 6 THEN 'June'
        WHEN EXTRACT(MONTH FROM order_date) = 7 THEN 'July'
        WHEN EXTRACT(MONTH FROM order_date) = 8 THEN 'August'
        WHEN EXTRACT(MONTH FROM order_date) = 9 THEN 'September'
        WHEN EXTRACT(MONTH FROM order_date) = 10 THEN 'October'
        WHEN EXTRACT(MONTH FROM order_date) = 11 THEN 'November'
        WHEN EXTRACT(MONTH FROM order_date) = 12 THEN 'December'
    END as month_name,
    AVG(sales) as avg_monthly_sales
FROM 
    superstore
GROUP BY 
    EXTRACT(MONTH FROM order_date)
ORDER BY 
    avg_monthly_sales DESC;
```

## Regional Performance Analysis

**11. What are the total sales by region?**
```sql
SELECT 
    region, 
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    region
ORDER BY 
    total_sales DESC;
```

**12. What are the total sales by state?**
```sql
SELECT 
    state, 
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    state
ORDER BY 
    total_sales DESC;
```

**13. Which city has the highest total sales?**
```sql
SELECT 
    city, 
    state,
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    city, state
ORDER BY 
    total_sales DESC
LIMIT 10;
```

**14. What is the average order value by region?**
```sql
SELECT 
    region,
    AVG(order_total) as avg_order_value
FROM (
    SELECT 
        region,
        order_id,
        SUM(sales) as order_total
    FROM 
        superstore
    GROUP BY 
        region, order_id
) as order_totals
GROUP BY 
    region
ORDER BY 
    avg_order_value DESC;
```

**15. What is the distribution of customers across different regions?**
```sql
SELECT 
    region,
    COUNT(DISTINCT customer_id) as customer_count,
    ROUND(100.0 * COUNT(DISTINCT customer_id) / 
          (SELECT COUNT(DISTINCT customer_id) FROM superstore), 2) as percentage
FROM 
    superstore
GROUP BY 
    region
ORDER BY 
    customer_count DESC;
```

**16. Which states are in the top 10 for total sales?**
```sql
SELECT 
    state, 
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    state
ORDER BY 
    total_sales DESC
LIMIT 10;
```

**17. Which states are in the bottom 10 for total sales?**
```sql
SELECT 
    state, 
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    state
ORDER BY 
    total_sales ASC
LIMIT 10;
```

**18. How do sales in the West region compare to sales in the East region?**
```sql
SELECT 
    region,
    SUM(sales) as total_sales,
    ROUND(100.0 * SUM(sales) / 
          (SELECT SUM(sales) FROM superstore WHERE region IN ('West', 'East')), 2) as percentage
FROM 
    superstore
WHERE 
    region IN ('West', 'East')
GROUP BY 
    region;
```

**19. What is the average discount percentage offered in each region?**
```sql
SELECT 
    region,
    ROUND(AVG(discount) * 100, 2) as avg_discount_percentage
FROM 
    superstore
GROUP BY 
    region
ORDER BY 
    avg_discount_percentage DESC;
```

**20. Which state has the highest average profit per order?**
```sql
SELECT 
    state,
    AVG(order_profit) as avg_profit_per_order
FROM (
    SELECT 
        state,
        order_id,
        SUM(profit) as order_profit
    FROM 
        superstore
    GROUP BY 
        state, order_id
) as order_profits
GROUP BY 
    state
ORDER BY 
    avg_profit_per_order DESC
LIMIT 10;
```

## Product Analysis

**21. Which product category has the highest profit margin?**
```sql
SELECT 
    category,
    SUM(profit) as total_profit,
    SUM(sales) as total_sales,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) as profit_margin
FROM 
    superstore
GROUP BY 
    category
ORDER BY 
    profit_margin DESC;
```

**22. Which product sub-category has the highest profit margin?**
```sql
SELECT 
    sub_category,
    SUM(profit) as total_profit,
    SUM(sales) as total_sales,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) as profit_margin
FROM 
    superstore
GROUP BY 
    sub_category
ORDER BY 
    profit_margin DESC;
```

**23. Which products have negative profit margins?**
```sql
SELECT 
    product_name,
    SUM(profit) as total_profit,
    SUM(sales) as total_sales,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) as profit_margin
FROM 
    superstore
GROUP BY 
    product_name
HAVING 
    SUM(profit) < 0
ORDER BY 
    profit_margin ASC
LIMIT 20;
```

**24. What is the average quantity sold per product category?**
```sql
SELECT 
    category,
    AVG(quantity) as avg_quantity_per_order
FROM 
    superstore
GROUP BY 
    category
ORDER BY 
    avg_quantity_per_order DESC;
```

**25. Which products are frequently purchased together in the same order?**
```sql
SELECT 
    a.product_name as product_1,
    b.product_name as product_2,
    COUNT(*) as frequency
FROM 
    superstore a
JOIN 
    superstore b 
    ON a.order_id = b.order_id 
    AND a.product_name < b.product_name
GROUP BY 
    a.product_name, b.product_name
ORDER BY 
    frequency DESC
LIMIT 20;
```

**26. What is the average discount applied to each product category?**
```sql
SELECT 
    category,
    ROUND(AVG(discount) * 100, 2) as avg_discount_percentage
FROM 
    superstore
GROUP BY 
    category
ORDER BY 
    avg_discount_percentage DESC;
```

**27. Which products have the highest discount percentages?**
```sql
SELECT 
    product_name,
    ROUND(AVG(discount) * 100, 2) as avg_discount_percentage,
    COUNT(*) as number_of_orders
FROM 
    superstore
GROUP BY 
    product_name
HAVING 
    COUNT(*) > 10 -- To ensure we're looking at frequently sold products
ORDER BY 
    avg_discount_percentage DESC
LIMIT 20;
```

**28. What are the top 10 products by total quantity sold?**
```sql
SELECT 
    product_name,
    SUM(quantity) as total_quantity_sold
FROM 
    superstore
GROUP BY 
    product_name
ORDER BY 
    total_quantity_sold DESC
LIMIT 10;
```

**29. Which products have higher than average return rates?**
```sql
SELECT 
    product_name,
    COUNT(*) as total_orders,
    SUM(CASE WHEN is_return = true THEN 1 ELSE 0 END) as returned_orders,
    ROUND(100.0 * SUM(CASE WHEN is_return = true THEN 1 ELSE 0 END) / COUNT(*), 2) as return_rate
FROM 
    superstore
GROUP BY 
    product_name
HAVING 
    COUNT(*) > 10 -- To ensure we're looking at frequently sold products
    AND ROUND(100.0 * SUM(CASE WHEN is_return = true THEN 1 ELSE 0 END) / COUNT(*), 2) > 
        (SELECT ROUND(100.0 * SUM(CASE WHEN is_return = true THEN 1 ELSE 0 END) / COUNT(*), 2) 
         FROM superstore)
ORDER BY 
    return_rate DESC
LIMIT 20;
```

**30. What's the correlation between discount percentage and quantity sold?**
```sql
-- Using Pearson correlation coefficient 
SELECT 
    CORR(discount, quantity) as discount_quantity_correlation
FROM 
    superstore;
```

## Customer Analysis

**31. Which customer segment generates the most sales?**
```sql
SELECT 
    segment, 
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    segment
ORDER BY 
    total_sales DESC;
```

**32. Which customer segment generates the most profit?**
```sql
SELECT 
    segment, 
    SUM(profit) as total_profit
FROM 
    superstore
GROUP BY 
    segment
ORDER BY 
    total_profit DESC;
```

**33. What is the average order value by customer segment?**
```sql
SELECT 
    segment,
    AVG(order_total) as avg_order_value
FROM (
    SELECT 
        segment,
        order_id,
        SUM(sales) as order_total
    FROM 
        superstore
    GROUP BY 
        segment, order_id
) as order_totals
GROUP BY 
    segment
ORDER BY 
    avg_order_value DESC;
```

**34. Who are the top 10 customers by total sales?**
```sql
SELECT 
    customer_name,
    customer_id,
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    customer_name, customer_id
ORDER BY 
    total_sales DESC
LIMIT 10;
```

**35. Who are the top 10 customers by number of orders?**
```sql
SELECT 
    customer_name,
    customer_id,
    COUNT(DISTINCT order_id) as number_of_orders
FROM 
    superstore
GROUP BY 
    customer_name, customer_id
ORDER BY 
    number_of_orders DESC
LIMIT 10;
```

**36. What's the distribution of order frequency among customers?**
```sql
WITH order_counts AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT order_id) as order_count
    FROM 
        superstore
    GROUP BY 
        customer_id
)
SELECT 
    order_count,
    COUNT(*) as number_of_customers,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM superstore), 2) as percentage
FROM 
    order_counts
GROUP BY 
    order_count
ORDER BY 
    order_count;
```

**37. Which customers have purchased products from all categories?**
```sql
WITH customer_categories AS (
    SELECT 
        customer_id,
        customer_name,
        COUNT(DISTINCT category) as category_count
    FROM 
        superstore
    GROUP BY 
        customer_id, customer_name
)
SELECT 
    customer_id,
    customer_name,
    category_count
FROM 
    customer_categories
WHERE 
    category_count = (SELECT COUNT(DISTINCT category) FROM superstore)
ORDER BY 
    customer_name;
```

**38. What is the average time between orders for repeat customers?**
```sql
WITH order_dates AS (
    SELECT 
        customer_id,
        order_id,
        order_date,
        LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) as next_order_date
    FROM (
        SELECT DISTINCT 
            customer_id, 
            order_id, 
            order_date
        FROM 
            superstore
    ) as distinct_orders
),
days_between_orders AS (
    SELECT 
        customer_id,
        order_id,
        EXTRACT(DAY FROM (next_order_date - order_date)) as days_between_orders
    FROM 
        order_dates
    WHERE 
        next_order_date IS NOT NULL
)
SELECT 
    AVG(days_between_orders) as avg_days_between_orders
FROM 
    days_between_orders;
```

**39. Which customer segment has the highest return rate?**
```sql
SELECT 
    segment,
    COUNT(*) as total_orders,
    SUM(CASE WHEN is_return = true THEN 1 ELSE 0 END) as returned_orders,
    ROUND(100.0 * SUM(CASE WHEN is_return = true THEN 1 ELSE 0 END) / COUNT(*), 2) as return_rate
FROM 
    superstore
GROUP BY 
    segment
ORDER BY 
    return_rate DESC;
```

**40. What types of products do different customer segments prefer?**
```sql
WITH segment_category_sales AS (
    SELECT 
        segment,
        category,
        SUM(sales) as total_sales
    FROM 
        superstore
    GROUP BY 
        segment, category
),
segment_totals AS (
    SELECT 
        segment,
        SUM(sales) as segment_sales
    FROM 
        superstore
    GROUP BY 
        segment
)
SELECT 
    sc.segment,
    sc.category,
    sc.total_sales,
    ROUND(100.0 * sc.total_sales / st.segment_sales, 2) as category_percentage
FROM 
    segment_category_sales sc
JOIN 
    segment_totals st ON sc.segment = st.segment
ORDER BY 
    sc.segment, category_percentage DESC;
```

## Profit Analysis

**41. What is the total profit across all orders?**
```sql
SELECT 
    SUM(profit) as total_profit
FROM 
    superstore;
```

**42. What is the average profit margin across all products?**
```sql
SELECT 
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) as overall_profit_margin
FROM 
    superstore;
```

**43. Which product category has the highest total profit?**
```sql
SELECT 
    category,
    SUM(profit) as total_profit
FROM 
    superstore
GROUP BY 
    category
ORDER BY 
    total_profit DESC;
```

**44. Which product sub-category has the highest total profit?**
```sql
SELECT 
    sub_category,
    SUM(profit) as total_profit
FROM 
    superstore
GROUP BY 
    sub_category
ORDER BY 
    total_profit DESC;
```

**45. Which states are most profitable?**
```sql
SELECT 
    state,
    SUM(profit) as total_profit
FROM 
    superstore
GROUP BY 
    state
ORDER BY 
    total_profit DESC
LIMIT 10;
```

**46. Which cities are most profitable?**
```sql
SELECT 
    city,
    state,
    SUM(profit) as total_profit
FROM 
    superstore
GROUP BY 
    city, state
ORDER BY 
    total_profit DESC
LIMIT 10;
```

**47. What is the relationship between discount and profit?**
```sql
-- Using discrete discount bands
SELECT 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.1 THEN '0-10%'
        WHEN discount <= 0.2 THEN '11-20%'
        WHEN discount <= 0.3 THEN '21-30%'
        WHEN discount <= 0.4 THEN '31-40%'
        WHEN discount <= 0.5 THEN '41-50%'
        ELSE '51%+'
    END as discount_band,
    COUNT(*) as number_of_items,
    SUM(sales) as total_sales,
    SUM(profit) as total_profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) as profit_margin
FROM 
    superstore
GROUP BY 
    discount_band
ORDER BY 
    CASE 
        WHEN discount_band = 'No Discount' THEN 0
        WHEN discount_band = '0-10%' THEN 1
        WHEN discount_band = '11-20%' THEN 2
        WHEN discount_band = '21-30%' THEN 3
        WHEN discount_band = '31-40%' THEN 4
        WHEN discount_band = '41-50%' THEN 5
        ELSE 6
    END;
```

**48. Which customer segment yields the highest profit margin?**
```sql
SELECT 
    segment,
    SUM(profit) as total_profit,
    SUM(sales) as total_sales,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) as profit_margin
FROM 
    superstore
GROUP BY 
    segment
ORDER BY 
    profit_margin DESC;
```

**49. How does profit vary by month?**
```sql
SELECT 
    EXTRACT(MONTH FROM order_date) as month,
    CASE 
        WHEN EXTRACT(MONTH FROM order_date) = 1 THEN 'January'
        WHEN EXTRACT(MONTH FROM order_date) = 2 THEN 'February'
        WHEN EXTRACT(MONTH FROM order_date) = 3 THEN 'March'
        WHEN EXTRACT(MONTH FROM order_date) = 4 THEN 'April'
        WHEN EXTRACT(MONTH FROM order_date) = 5 THEN 'May'
        WHEN EXTRACT(MONTH FROM order_date) = 6 THEN 'June'
        WHEN EXTRACT(MONTH FROM order_date) = 7 THEN 'July'
        WHEN EXTRACT(MONTH FROM order_date) = 8 THEN 'August'
        WHEN EXTRACT(MONTH FROM order_date) = 9 THEN 'September'
        WHEN EXTRACT(MONTH FROM order_date) = 10 THEN 'October'
        WHEN EXTRACT(MONTH FROM order_date) = 11 THEN 'November'
        WHEN EXTRACT(MONTH FROM order_date) = 12 THEN 'December'
    END as month_name,
    SUM(profit) as total_profit
FROM 
    superstore
GROUP BY 
    EXTRACT(MONTH FROM order_date)
ORDER BY 
    month;
```

**50. What percentage of products have negative profit margins?**
```sql
WITH product_profits AS (
    SELECT 
        product_id,
        product_name,
        SUM(profit) as total_profit,
        SUM(sales) as total_sales,
        CASE WHEN SUM(profit) < 0 THEN 1 ELSE 0 END as is_negative_profit
    FROM 
        superstore
    GROUP BY 
        product_id, product_name
)
SELECT 
    COUNT(*) as total_products,
    SUM(is_negative_profit) as negative_profit_products,
    ROUND(100.0 * SUM(is_negative_profit) / COUNT(*), 2) as percentage_negative
FROM 
    product_profits;
```

## Shipping Analysis

**51. What is the distribution of orders across different shipping modes?**
```sql
SELECT 
    ship_mode,
    COUNT(DISTINCT order_id) as number_of_orders,
    ROUND(100.0 * COUNT(DISTINCT order_id) / 
          (SELECT COUNT(DISTINCT order_id) FROM superstore), 2) as percentage
FROM 
    superstore
GROUP BY 
    ship_mode
ORDER BY 
    number_of_orders DESC;
```

**52. Which shipping mode is most commonly used?**
```sql
SELECT 
    ship_mode,
    COUNT(DISTINCT order_id) as number_of_orders
FROM 
    superstore
GROUP BY 
    ship_mode
ORDER BY 
    number_of_orders DESC
LIMIT 1;
```

**53. What is the average time between order date and ship date?**
```sql
SELECT 
    AVG(EXTRACT(DAY FROM (ship_date - order_date))) as avg_days_to_ship
FROM 
    superstore
WHERE 
    ship_date IS NOT NULL 
    AND order_date IS NOT NULL;
```

**54. Does shipping mode affect the time between order and shipment?**
```sql
SELECT 
    ship_mode,
    AVG(EXTRACT(DAY FROM (ship_date - order_date))) as avg_days_to_ship
FROM 
    superstore
WHERE 
    ship_date IS NOT NULL 
    AND order_date IS NOT NULL
GROUP BY 
    ship_mode
ORDER BY 
    avg_days_to_ship;
```

**55. Which shipping mode is most profitable?**
```sql
SELECT 
    ship_mode,
    SUM(profit) as total_profit,
    ROUND(SUM(profit) / COUNT(DISTINCT order_id), 2) as profit_per_order
FROM 
    superstore
GROUP BY 
    ship_mode
ORDER BY 
    profit_per_order DESC;
```

**56. Is there a relationship between shipping mode and order size?**
```sql
SELECT 
    ship_mode,
    AVG(order_total) as avg_order_value,
    AVG(item_count) as avg_items_per_order
FROM (
    SELECT 
        order_id,
        ship_mode,
        SUM(sales) as order_total,
        COUNT(*) as item_count
    FROM 
        superstore
    GROUP BY 
        order_id, ship_mode
) as order_metrics
GROUP BY 
    ship_mode
ORDER BY 
    avg_order_value DESC;
```

**57. Which regions have the longest shipping times?**
```sql
SELECT 
    region,
    AVG(EXTRACT(DAY FROM (ship_date - order_date))) as avg_days_to_ship
FROM 
    superstore
WHERE 
    ship_date IS NOT NULL 
    AND order_date IS NOT NULL
GROUP BY 
    region
ORDER BY 
    avg_days_to_ship DESC;
```

**58. Do customers in certain segments prefer specific shipping modes?**
```sql
WITH segment_ship_modes AS (
    SELECT 
        segment,
        ship_mode,
        COUNT(DISTINCT order_id) as order_count
    FROM 
        superstore
    GROUP BY 
        segment, ship_mode
),
segment_totals AS (
    SELECT 
        segment,
        SUM(order_count) as total_orders
    FROM 
        segment_ship_modes
    GROUP BY 
        segment
)
SELECT 
    ssm.segment,
    ssm.ship_mode,
    ssm.order_count,
    ROUND(100.0 * ssm.order_count / st.total_orders, 2) as percentage
FROM 
    segment_ship_modes ssm
JOIN 
    segment_totals st ON ssm.segment = st.segment
ORDER BY 
    ssm.segment, percentage DESC;
```

**59. How does shipping time affect customer return rates?**
```sql
WITH shipping_time_groups AS (
    SELECT 
        order_id,
        CASE 
            WHEN EXTRACT(DAY FROM (ship_date - order_date)) <= 1 THEN 'Same day/Next day'
            WHEN EXTRACT(DAY FROM (ship_date - order_date)) <= 3 THEN '2-3 days'
            WHEN EXTRACT(DAY FROM (ship_date - order_date)) <= 5 THEN '4-5 days'
            ELSE '6+ days'
        END as shipping_time
    FROM 
        superstore
    WHERE 
        ship_date IS NOT NULL 
        AND order_date IS NOT NULL
    GROUP BY 
        order_id, EXTRACT(DAY FROM (ship_date - order_date))
)
SELECT 
    stg.shipping_time,
    COUNT(DISTINCT s.order_id) as number_of_orders,
    SUM(CASE WHEN s.is_return = true THEN 1 ELSE 0 END) as returned_orders,
    ROUND(100.0 * SUM(CASE WHEN s.is_return = true THEN 1 ELSE 0 END) / COUNT(DISTINCT s.order_id), 2) as return_rate
FROM 
    superstore s
JOIN 
    shipping_time_groups stg ON s.order_id = stg.order_id
GROUP BY 
    stg.shipping_time
ORDER BY 
    CASE 
        WHEN stg.shipping_time = 'Same day/Next day' THEN 1
        WHEN stg.shipping_time = '2-3 days' THEN 2
        WHEN stg.shipping_time = '4-5 days' THEN 3
        ELSE 4
    END;
```

**60. What is the average shipping time by state?**
```sql
SELECT 
    state,
    AVG(EXTRACT(DAY FROM (ship_date - order_date))) as avg_days_to_ship
FROM 
    superstore
WHERE 
    ship_date IS NOT NULL 
    AND order_date IS NOT NULL
GROUP BY 
    state
ORDER BY 
    avg_days_to_ship DESC;
```

## Discount Analysis

**61. What is the average discount percentage across all orders?**
```sql
SELECT 
    ROUND(AVG(discount) * 100, 2) as avg_discount_percentage
FROM 
    superstore;
```

**62. Which product categories receive the highest discount percentages?**
```sql
SELECT 
    category,
    ROUND(AVG(discount) * 100, 2) as avg_discount_percentage
FROM 
    superstore
GROUP BY 
    category
ORDER BY 
    avg_discount_percentage DESC;
```

**63. Is there a correlation between discount percentage and order quantity?**
```sql
-- Using Pearson correlation coefficient 
SELECT 
    CORR(discount, quantity) as discount_quantity_correlation
FROM 
    superstore;
```

**64. Which customer segments receive the highest discount percentages?**
```sql
SELECT 
    segment,
    ROUND(AVG(discount) * 100, 2) as avg_discount_percentage
FROM 
    superstore
GROUP BY 
    segment
ORDER BY 
    avg_discount_percentage DESC;
```

**65. What is the effect of discounts on profit margins?**
```sql
SELECT 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.1 THEN '0-10%'
        WHEN discount <= 0.2 THEN '11-20%'
        WHEN discount <= 0.3 THEN '21-30%'
        WHEN discount <= 0.4 THEN '31-40%'
        WHEN discount <= 0.5 THEN '41-50%'
        ELSE '51%+'
    END as discount_band,
    COUNT(*) as number_of_items,
    SUM(sales) as total_sales,
    SUM(profit) as total_profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) as profit_margin
FROM 
    superstore
GROUP BY 
    discount_band
ORDER BY 
    CASE 
        WHEN discount_band = 'No Discount' THEN 0
        WHEN discount_band = '0-10%' THEN 1
        WHEN discount_band = '11-20%' THEN 2
        WHEN discount_band = '21-30%' THEN 3
        WHEN discount_band = '31-40%' THEN 4
        WHEN discount_band = '41-50%' THEN 5
        ELSE 6
    END;
```

**66. Which month has the highest average discount?**
```sql
SELECT 
    EXTRACT(MONTH FROM order_date) as month,
    CASE 
        WHEN EXTRACT(MONTH FROM order_date) = 1 THEN 'January'
        WHEN EXTRACT(MONTH FROM order_date) = 2 THEN 'February'
        WHEN EXTRACT(MONTH FROM order_date) = 3 THEN 'March'
        WHEN EXTRACT(MONTH FROM order_date) = 4 THEN 'April'
        WHEN EXTRACT(MONTH FROM order_date) = 5 THEN 'May'
        WHEN EXTRACT(MONTH FROM order_date) = 6 THEN 'June'
        WHEN EXTRACT(MONTH FROM order_date) = 7 THEN 'July'
        WHEN EXTRACT(MONTH FROM order_date) = 8 THEN 'August'
        WHEN EXTRACT(MONTH FROM order_date) = 9 THEN 'September'
        WHEN EXTRACT(MONTH FROM order_date) = 10 THEN 'October'
        WHEN EXTRACT(MONTH FROM order_date) = 11 THEN 'November'
        WHEN EXTRACT(MONTH FROM order_date) = 12 THEN 'December'
    END as month_name,
    ROUND(AVG(discount) * 100, 2) as avg_discount_percentage
FROM 
    superstore
GROUP BY 
    EXTRACT(MONTH FROM order_date)
ORDER BY 
    avg_discount_percentage DESC;
```

**67. Are discounts higher during specific seasons or holidays?**
```sql
-- Define seasons based on month
SELECT 
    CASE 
        WHEN EXTRACT(MONTH FROM order_date) IN (12, 1, 2) THEN 'Winter'
        WHEN EXTRACT(MONTH FROM order_date) IN (3, 4, 5) THEN 'Spring'
        WHEN EXTRACT(MONTH FROM order_date) IN (6, 7, 8) THEN 'Summer'
        WHEN EXTRACT(MONTH FROM order_date) IN (9, 10, 11) THEN 'Fall'
    END as season,
    ROUND(AVG(discount) * 100, 2) as avg_discount_percentage
FROM 
    superstore
GROUP BY 
    season
ORDER BY 
    avg_discount_percentage DESC;
```

**68. How does discount percentage vary by region?**
```sql
SELECT 
    region,
    ROUND(AVG(discount) * 100, 2) as avg_discount_percentage
FROM 
    superstore
GROUP BY 
    region
ORDER BY 
    avg_discount_percentage DESC;
```

**69. Is there a relationship between product price and discount percentage?**
```sql
WITH product_price_bands AS (
    SELECT 
        CASE 
            WHEN sales/NULLIF(quantity, 0) < 50 THEN 'Low-priced (<$50)'
            WHEN sales/NULLIF(quantity, 0) < 150 THEN 'Medium-priced ($50-$149)'
            WHEN sales/NULLIF(quantity, 0) < 500 THEN 'High-priced ($150-$499)'
            ELSE 'Premium (>=$500)'
        END as price_band,
        discount
    FROM 
        superstore
    WHERE 
        quantity > 0
)
SELECT 
    price_band,
    ROUND(AVG(discount) * 100, 2) as avg_discount_percentage
FROM 
    product_price_bands
GROUP BY 
    price_band
ORDER BY 
    CASE 
        WHEN price_band = 'Low-priced (<$50)' THEN 1
        WHEN price_band = 'Medium-priced ($50-$149)' THEN 2
        WHEN price_band = 'High-priced ($150-$499)' THEN 3
        ELSE 4
    END;
```

**70. Which products are most frequently discounted?**
```sql
SELECT 
    product_name,
    COUNT(*) as total_sales,
    SUM(CASE WHEN discount > 0 THEN 1 ELSE 0 END) as discounted_sales,
    ROUND(100.0 * SUM(CASE WHEN discount > 0 THEN 1 ELSE 0 END) / COUNT(*), 2) as discount_frequency
FROM 
    superstore
GROUP BY 
    product_name
HAVING 
    COUNT(*) >= 10 -- To ensure we're looking at frequently sold products
ORDER BY 
    discount_frequency DESC
LIMIT 20;
```

## Return and Order Analysis

**71. What percentage of orders are returned?**
```sql
SELECT 
    COUNT(DISTINCT order_id) as total_orders,
    COUNT(DISTINCT CASE WHEN is_return = true THEN order_id END) as returned_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN is_return = true THEN order_id END) / 
          COUNT(DISTINCT order_id), 2) as return_percentage
FROM 
    superstore;
```

**72. Which product categories have the highest return rates?**
```sql
SELECT 
    category,
    COUNT(*) as total_items,
    SUM(CASE WHEN is_return = true THEN 1 ELSE 0 END) as returned_items,
    ROUND(100.0 * SUM(CASE WHEN is_return = true THEN 1 ELSE 0 END) / COUNT(*), 2) as return_rate
FROM 
    superstore
GROUP BY 
    category
ORDER BY 
    return_rate DESC;
```

**73. Which customer segments have the highest return rates?**
```sql
SELECT 
    segment,
    COUNT(*) as total_items,
    SUM(CASE WHEN is_return = true THEN 1 ELSE 0 END) as returned_items,
    ROUND(100.0 * SUM(CASE WHEN is_return = true THEN 1 ELSE 0 END) / COUNT(*), 2) as return_rate
FROM 
    superstore
GROUP BY 
    segment
ORDER BY 
    return_rate DESC;
```

**74. Is there a correlation between discount and return rate?**
```sql
SELECT 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.1 THEN '0-10%'
        WHEN discount <= 0.2 THEN '11-20%'
        WHEN discount <= 0.3 THEN '21-30%'
        WHEN discount <= 0.4 THEN '31-40%'
        WHEN discount <= 0.5 THEN '41-50%'
        ELSE '51%+'
    END as discount_band,
    COUNT(*) as total_items,
    SUM(CASE WHEN is_return = true THEN 1 ELSE 0 END) as returned_items,
    ROUND(100.0 * SUM(CASE WHEN is_return = true THEN 1 ELSE 0 END) / COUNT(*), 2) as return_rate
FROM 
    superstore
GROUP BY 
    discount_band
ORDER BY 
    CASE 
        WHEN discount_band = 'No Discount' THEN 0
        WHEN discount_band = '0-10%' THEN 1
        WHEN discount_band = '11-20%' THEN 2
        WHEN discount_band = '21-30%' THEN 3
        WHEN discount_band = '31-40%' THEN 4
        WHEN discount_band = '41-50%' THEN 5
        ELSE 6
    END;
```

**75. Which regions have the highest return rates?**
```sql
SELECT 
    region,
    COUNT(*) as total_items,
    SUM(CASE WHEN is_return = true THEN 1 ELSE 0 END) as returned_items,
    ROUND(100.0 * SUM(CASE WHEN is_return = true THEN 1 ELSE 0 END) / COUNT(*), 2) as return_rate
FROM 
    superstore
GROUP BY 
    region
ORDER BY 
    return_rate DESC;
```

**76. What's the average order size in terms of quantity?**
```sql
SELECT 
    AVG(total_quantity) as avg_order_quantity
FROM (
    SELECT 
        order_id,
        SUM(quantity) as total_quantity
    FROM 
        superstore
    GROUP BY 
        order_id
) as order_quantities;
```

**77. What's the average number of different products per order?**
```sql
SELECT 
    AVG(product_count) as avg_products_per_order
FROM (
    SELECT 
        order_id,
        COUNT(DISTINCT product_id) as product_count
    FROM 
        superstore
    GROUP BY 
        order_id
) as order_product_counts;
```

**78. What's the distribution of order values?**
```sql
WITH order_values AS (
    SELECT 
        order_id,
        SUM(sales) as total_value
    FROM 
        superstore
    GROUP BY 
        order_id
)
SELECT 
    CASE 
        WHEN total_value < 50 THEN 'Under $50'
        WHEN total_value < 100 THEN '$50-$99'
        WHEN total_value < 250 THEN '$100-$249'
        WHEN total_value < 500 THEN '$250-$499'
        WHEN total_value < 1000 THEN '$500-$999'
        WHEN total_value < 2500 THEN '$1000-$2499'
        ELSE '$2500+'
    END as order_value_range,
    COUNT(*) as number_of_orders,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM order_values), 2) as percentage
FROM 
    order_values
GROUP BY 
    order_value_range
ORDER BY 
    CASE 
        WHEN order_value_range = 'Under $50' THEN 1
        WHEN order_value_range = '$50-$99' THEN 2
        WHEN order_value_range = '$100-$249' THEN 3
        WHEN order_value_range = '$250-$499' THEN 4
        WHEN order_value_range = '$500-$999' THEN 5
        WHEN order_value_range = '$1000-$2499' THEN 6
        ELSE 7
    END;
```

**79. What's the percentage of high-value orders (>$1000)?**
```sql
WITH order_values AS (
    SELECT 
        order_id,
        SUM(sales) as total_value
    FROM 
        superstore
    GROUP BY 
        order_id
)
SELECT 
    COUNT(*) as total_orders,
    SUM(CASE WHEN total_value > 1000 THEN 1 ELSE 0 END) as high_value_orders,
    ROUND(100.0 * SUM(CASE WHEN total_value > 1000 THEN 1 ELSE 0 END) / COUNT(*), 2) as high_value_percentage
FROM 
    order_values;
```

**80. What's the percentage of low-value orders (<$50)?**
```sql
WITH order_values AS (
    SELECT 
        order_id,
        SUM(sales) as total_value
    FROM 
        superstore
    GROUP BY 
        order_id
)
SELECT 
    COUNT(*) as total_orders,
    SUM(CASE WHEN total_value < 50 THEN 1 ELSE 0 END) as low_value_orders,
    ROUND(100.0 * SUM(CASE WHEN total_value < 50 THEN 1 ELSE 0 END) / COUNT(*), 2) as low_value_percentage
FROM 
    order_values;
```

## Temporal Analysis

**81. How do sales vary by day of the week?**
```sql
SELECT 
    EXTRACT(DOW FROM order_date) as day_of_week,
    CASE 
        WHEN EXTRACT(DOW FROM order_date) = 0 THEN 'Sunday'
        WHEN EXTRACT(DOW FROM order_date) = 1 THEN 'Monday'
        WHEN EXTRACT(DOW FROM order_date) = 2 THEN 'Tuesday'
        WHEN EXTRACT(DOW FROM order_date) = 3 THEN 'Wednesday'
        WHEN EXTRACT(DOW FROM order_date) = 4 THEN 'Thursday'
        WHEN EXTRACT(DOW FROM order_date) = 5 THEN 'Friday'
        WHEN EXTRACT(DOW FROM order_date) = 6 THEN 'Saturday'
    END as day_name,
    SUM(sales) as total_sales,
    COUNT(DISTINCT order_id) as order_count,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) as avg_order_value
FROM 
    superstore
GROUP BY 
    EXTRACT(DOW FROM order_date)
ORDER BY 
    day_of_week;
```

**82. How do sales vary by month?**
```sql
SELECT 
    EXTRACT(MONTH FROM order_date) as month,
    CASE 
        WHEN EXTRACT(MONTH FROM order_date) = 1 THEN 'January'
        WHEN EXTRACT(MONTH FROM order_date) = 2 THEN 'February'
        WHEN EXTRACT(MONTH FROM order_date) = 3 THEN 'March'
        WHEN EXTRACT(MONTH FROM order_date) = 4 THEN 'April'
        WHEN EXTRACT(MONTH FROM order_date) = 5 THEN 'May'
        WHEN EXTRACT(MONTH FROM order_date) = 6 THEN 'June'
        WHEN EXTRACT(MONTH FROM order_date) = 7 THEN 'July'
        WHEN EXTRACT(MONTH FROM order_date) = 8 THEN 'August'
        WHEN EXTRACT(MONTH FROM order_date) = 9 THEN 'September'
        WHEN EXTRACT(MONTH FROM order_date) = 10 THEN 'October'
        WHEN EXTRACT(MONTH FROM order_date) = 11 THEN 'November'
        WHEN EXTRACT(MONTH FROM order_date) = 12 THEN 'December'
    END as month_name,
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    EXTRACT(MONTH FROM order_date)
ORDER BY 
    month;
```

**83. How do sales vary by quarter?**
```sql
SELECT 
    EXTRACT(YEAR FROM order_date) as year,
    EXTRACT(QUARTER FROM order_date) as quarter,
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    EXTRACT(YEAR FROM order_date),
    EXTRACT(QUARTER FROM order_date)
ORDER BY 
    year, quarter;
```

**84. Are there seasonal patterns in product category sales?**
```sql
SELECT 
    category,
    CASE 
        WHEN EXTRACT(MONTH FROM order_date) IN (12, 1, 2) THEN 'Winter'
        WHEN EXTRACT(MONTH FROM order_date) IN (3, 4, 5) THEN 'Spring'
        WHEN EXTRACT(MONTH FROM order_date) IN (6, 7, 8) THEN 'Summer'
        WHEN EXTRACT(MONTH FROM order_date) IN (9, 10, 11) THEN 'Fall'
    END as season,
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    category, 
    CASE 
        WHEN EXTRACT(MONTH FROM order_date) IN (12, 1, 2) THEN 'Winter'
        WHEN EXTRACT(MONTH FROM order_date) IN (3, 4, 5) THEN 'Spring'
        WHEN EXTRACT(MONTH FROM order_date) IN (6, 7, 8) THEN 'Summer'
        WHEN EXTRACT(MONTH FROM order_date) IN (9, 10, 11) THEN 'Fall'
    END
ORDER BY 
    category, 
    CASE 
        WHEN season = 'Winter' THEN 1
        WHEN season = 'Spring' THEN 2
        WHEN season = 'Summer' THEN 3
        WHEN season = 'Fall' THEN 4
    END;
```

**85. Is there a year-over-year growth in sales?**
```sql
WITH yearly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) as year,
        SUM(sales) as yearly_sales
    FROM 
        superstore
    GROUP BY 
        EXTRACT(YEAR FROM order_date)
)
SELECT 
    current.year,
    current.yearly_sales,
    prev.yearly_sales as prev_year_sales,
    ROUND(100.0 * (current.yearly_sales - prev.yearly_sales) / NULLIF(prev.yearly_sales, 0), 2) as yoy_growth_percentage
FROM 
    yearly_sales current
LEFT JOIN 
    yearly_sales prev ON current.year = prev.year + 1
ORDER BY 
    current.year;
```

**86. When (day, month) was the highest single-day sales recorded?**
```sql
SELECT 
    order_date,
    SUM(sales) as daily_sales
FROM 
    superstore
GROUP BY 
    order_date
ORDER BY 
    daily_sales DESC
LIMIT 1;
```

**87. When (day, month) was the lowest single-day sales recorded?**
```sql
SELECT 
    order_date,
    SUM(sales) as daily_sales
FROM 
    superstore
GROUP BY 
    order_date
ORDER BY 
    daily_sales ASC
LIMIT 1;
```

**88. Is there a pattern in order frequency throughout the month?**
```sql
SELECT 
    EXTRACT(DAY FROM order_date) as day_of_month,
    COUNT(DISTINCT order_id) as number_of_orders,
    SUM(sales) as total_sales
FROM 
    superstore
GROUP BY 
    EXTRACT(DAY FROM order_date)
ORDER BY 
    day_of_month;
```

**89. How has the average order value changed over time?**
```sql
SELECT 
    EXTRACT(YEAR FROM order_date) as year,
    EXTRACT(QUARTER FROM order_date) as quarter,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) as avg_order_value
FROM 
    superstore
GROUP BY 
    EXTRACT(YEAR FROM order_date),
    EXTRACT(QUARTER FROM order_date)
ORDER BY 
    year, quarter;
```

**90. How have shipping times changed over the years?**
```sql
SELECT 
    EXTRACT(YEAR FROM order_date) as year,
    AVG(EXTRACT(DAY FROM (ship_date - order_date))) as avg_days_to_ship
FROM 
    superstore
WHERE 
    ship_date IS NOT NULL 
    AND order_date IS NOT NULL
GROUP BY 
    EXTRACT(YEAR FROM order_date)
ORDER BY 
    year;
```

## Advanced Business Analytics

**91. What is the customer lifetime value (CLV) for different customer segments?**
```sql
WITH customer_total_value AS (
    SELECT 
        customer_id,
        segment,
        SUM(sales) as total_sales,
        COUNT(DISTINCT order_id) as order_count,
        MIN(order_date) as first_purchase_date,
        MAX(order_date) as last_purchase_date,
        EXTRACT(YEAR FROM MAX(order_date)) - EXTRACT(YEAR FROM MIN(order_date)) + 1 as years_active
    FROM 
        superstore
    GROUP BY 
        customer_id, segment
)
SELECT 
    segment,
    ROUND(AVG(total_sales), 2) as avg_customer_lifetime_value,
    ROUND(AVG(total_sales / GREATEST(years_active, 1)), 2) as avg_annual_value,
    ROUND(AVG(order_count), 2) as avg_order_count,
    ROUND(AVG(years_active), 2) as avg_years_active
FROM 
    customer_total_value
GROUP BY 
    segment
ORDER BY 
    avg_customer_lifetime_value DESC;
```

**92. Which products should be considered for bundling based on purchase patterns?**
```sql
SELECT 
    a.product_name as product_1,
    b.product_name as product_2,
    COUNT(*) as purchase_together_count,
    -- Calculate lift (association rule metric)
    COUNT(*) / (
        (SELECT COUNT(*) FROM superstore WHERE product_name = a.product_name) *
        (SELECT COUNT(*) FROM superstore WHERE product_name = b.product_name) /
        (SELECT COUNT(DISTINCT order_id) FROM superstore)::float
    ) as lift
FROM 
    superstore a
JOIN 
    superstore b 
    ON a.order_id = b.order_id 
    AND a.product_id < b.product_id
GROUP BY 
    a.product_name, b.product_name
HAVING 
    COUNT(*) >= 5
ORDER BY 
    lift DESC, purchase_together_count DESC
LIMIT 20;
```

**93. What is the price elasticity of demand for various product categories?**
```sql
WITH price_quantity_data AS (
    SELECT 
        category,
        SUM(sales) / NULLIF(SUM(quantity), 0) as avg_price,
        SUM(quantity) as total_quantity
    FROM 
        superstore
    GROUP BY 
        category, EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)
)
SELECT 
    category,
    CORR(LN(avg_price), LN(total_quantity)) as price_elasticity
FROM 
    price_quantity_data
GROUP BY 
    category
ORDER BY 
    ABS(price_elasticity) DESC;
```

**94. Which customers are at risk of churn based on purchase frequency?**
```sql
WITH customer_purchase_gaps AS (
    SELECT 
        customer_id,
        customer_name,
        MAX(order_date) as last_purchase_date,
        CURRENT_DATE - MAX(order_date) as days_since_last_purchase,
        AVG(EXTRACT(DAY FROM (order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)))) as avg_days_between_purchases
    FROM (
        SELECT DISTINCT 
            customer_id, 
            customer_name, 
            order_id, 
            order_date
        FROM 
            superstore
    ) as distinct_orders
    GROUP BY 
        customer_id, customer_name
    HAVING 
        COUNT(order_id) > 1 -- Only customers with more than one order
)
SELECT 
    customer_id,
    customer_name,
    last_purchase_date,
    days_since_last_purchase,
    avg_days_between_purchases,
    days_since_last_purchase / NULLIF(avg_days_between_purchases, 0) as purchase_delay_ratio
FROM 
    customer_purchase_gaps
WHERE 
    days_since_last_purchase > avg_days_between_purchases * 2 -- More than twice their usual gap
    AND days_since_last_purchase > 90 -- At least 90 days since last purchase
ORDER BY 
    purchase_delay_ratio DESC
LIMIT 50;
```

**95. What is the expected demand forecast for next quarter based on historical trends?**
```sql
WITH quarterly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) as year,
        EXTRACT(QUARTER FROM order_date) as quarter,
        category,
        SUM(sales) as quarterly_sales
    FROM 
        superstore
    GROUP BY 
        EXTRACT(YEAR FROM order_date),
        EXTRACT(QUARTER FROM order_date),
        category
),
growth_rates AS (
    SELECT 
        category,
        AVG(
            (current.quarterly_sales - prev.quarterly_sales) / NULLIF(prev.quarterly_sales, 0)
        ) as avg_growth_rate
    FROM 
        quarterly_sales current
    JOIN 
        quarterly_sales prev 
        ON current.category = prev.category
        AND (current.year = prev.year AND current.quarter = prev.quarter + 1)
        OR (current.year = prev.year + 1 AND current.quarter = 1 AND prev.quarter = 4)
    GROUP BY 
        category
),
latest_quarters AS (
    SELECT 
        category,
        quarterly_sales
    FROM (
        SELECT 
            category,
            quarterly_sales,
            ROW_NUMBER() OVER (PARTITION BY category ORDER BY year DESC, quarter DESC) as rn
        FROM 
            quarterly_sales
    ) ranked_quarters
    WHERE 
        rn = 1
)
SELECT 
    lq.category,
    lq.quarterly_sales as latest_quarter_sales,
    gr.avg_growth_rate as avg_quarterly_growth_rate,
    ROUND(lq.quarterly_sales * (1 + gr.avg_growth_rate), 2) as next_quarter_forecast
FROM 
    latest_quarters lq
JOIN 
    growth_rates gr ON lq.category = gr.category
ORDER BY 
    next_quarter_forecast DESC;
```

**96. Which products are frequently returned together?**
```sql
SELECT 
    a.product_name as product_1,
    b.product_name as product_2,
    COUNT(*) as returned_together_count
FROM 
    superstore a
JOIN 
    superstore b 
    ON a.order_id = b.order_id 
    AND a.product_id < b.product_id
    AND a.is_return = true
    AND b.is_return = true
GROUP BY 
    a.product_name, b.product_name
HAVING 
    COUNT(*) >= 3
ORDER BY 
    returned_together_count DESC
LIMIT 20;
```

**97. What market basket analysis insights can be derived from the dataset?**
```sql
WITH product_combinations AS (
    SELECT 
        a.sub_category as product_category_1,
        b.sub_category as product_category_2,
        COUNT(DISTINCT a.order_id) as purchased_together_count,
        (SELECT COUNT(DISTINCT order_id) FROM superstore WHERE sub_category = a.sub_category) as category_1_order_count,
        (SELECT COUNT(DISTINCT order_id) FROM superstore WHERE sub_category = b.sub_category) as category_2_order_count,
        (SELECT COUNT(DISTINCT order_id) FROM superstore) as total_order_count
    FROM 
        superstore a
    JOIN 
        superstore b 
        ON a.order_id = b.order_id 
        AND a.sub_category < b.sub_category
    GROUP BY 
        a.sub_category, b.sub_category
)
SELECT 
    product_category_1,
    product_category_2,
    purchased_together_count,
    ROUND(100.0 * purchased_together_count / category_1_order_count, 2) as support,
    ROUND(100.0 * purchased_together_count / category_1_order_count, 2) as confidence,
    ROUND(
        purchased_together_count * total_order_count * 1.0 / (category_1_order_count * category_2_order_count), 
        2
    ) as lift
FROM 
    product_combinations
WHERE 
    purchased_together_count >= 10 -- Minimum threshold for significance
ORDER BY 
    lift DESC
LIMIT 20;
```

**98. Can we identify seasonal purchasing patterns for specific product categories?**
```sql
WITH monthly_category_sales AS (
    SELECT 
        category,
        EXTRACT(MONTH FROM order_date) as month,
        CASE 
            WHEN EXTRACT(MONTH FROM order_date) = 1 THEN 'January'
            WHEN EXTRACT(MONTH FROM order_date) = 2 THEN 'February'
            WHEN EXTRACT(MONTH FROM order_date) = 3 THEN 'March'
            WHEN EXTRACT(MONTH FROM order_date) = 4 THEN 'April'
            WHEN EXTRACT(MONTH FROM order_date) = 5 THEN 'May'
            WHEN EXTRACT(MONTH FROM order_date) = 6 THEN 'June'
            WHEN EXTRACT(MONTH FROM order_date) = 7 THEN 'July'
            WHEN EXTRACT(MONTH FROM order_date) = 8 THEN 'August'
            WHEN EXTRACT(MONTH FROM order_date) = 9 THEN 'September'
            WHEN EXTRACT(MONTH FROM order_date) = 10 THEN 'October'
            WHEN EXTRACT(MONTH FROM order_date) = 11 THEN 'November'
            WHEN EXTRACT(MONTH FROM order_date) = 12 THEN 'December'
        END as month_name,
        SUM(sales) as total_sales
    FROM 
        superstore
    GROUP BY 
        category, EXTRACT(MONTH FROM order_date)
),
category_totals AS (
    SELECT 
        category,
        SUM(total_sales) as yearly_sales
    FROM 
        monthly_category_sales
    GROUP BY 
        category
)
SELECT 
    mcs.category,
    mcs.month,
    mcs.month_name,
    mcs.total_sales,
    ROUND(100.0 * mcs.total_sales / ct.yearly_sales, 2) as percentage_of_yearly_sales,
    -- Standard score (z-score) to identify seasonality
    (mcs.total_sales - AVG(mcs.total_sales) OVER (PARTITION BY mcs.category)) / 
    NULLIF(STDDEV(mcs.total_sales) OVER (PARTITION BY mcs.category), 0) as seasonality_zscore
FROM 
    monthly_category_sales mcs
JOIN 
    category_totals ct ON mcs.category = ct.category
ORDER BY 
    mcs.category, mcs.month;
```

**99. Which geographic areas represent opportunities for new store locations based on high sales but limited physical presence?**
```sql
WITH city_metrics AS (
    SELECT 
        city,
        state,
        region,
        COUNT(DISTINCT customer_id) as customer_count,
        COUNT(DISTINCT order_id) as order_count,
        SUM(sales) as total_sales,
        SUM(profit) as total_profit,
        AVG(sales) as avg_order_value
    FROM 
        superstore
    GROUP BY 
        city, state, region
)
SELECT 
    city,
    state,
    region,
    customer_count,
    order_count,
    total_sales,
    total_profit,
    avg_order_value,
    ROUND(total_sales / customer_count, 2) as sales_per_customer,
    ROUND(total_profit / total_sales * 100, 2) as profit_margin
FROM 
    city_metrics
WHERE 
    customer_count >= 5 -- Minimum customer threshold
    AND total_profit > 0 -- Profitable areas only
ORDER BY 
    sales_per_customer DESC, total_profit DESC
LIMIT 20;
```

**100. What is the ROI of discounting strategies across different product categories?**
```sql
WITH discount_performance AS (
    SELECT 
        category,
        CASE 
            WHEN discount = 0 THEN 'No Discount'
            WHEN discount <= 0.1 THEN '0-10%'
            WHEN discount <= 0.2 THEN '11-20%'
            WHEN discount <= 0.3 THEN '21-30%'
            WHEN discount <= 0.4 THEN '31-40%'
            WHEN discount <= 0.5 THEN '41-50%'
            ELSE '51%+'
        END as discount_band,
        SUM(sales) as total_sales,
        SUM(sales / (1 - discount)) as potential_sales_without_discount,
        SUM(profit) as total_profit,
        COUNT(*) as number_of_items
    FROM 
        superstore
    GROUP BY 
        category, 
        CASE 
            WHEN discount = 0 THEN 'No Discount'
            WHEN discount <= 0.1 THEN '0-10%'
            WHEN discount <= 0.2 THEN '11-20%'
            WHEN discount <= 0.3 THEN '21-30%'
            WHEN discount <= 0.4 THEN '31-40%'
            WHEN discount <= 0.5 THEN '41-50%'
            ELSE '51%+'
        END
)
SELECT 
    category,
    discount_band,
    total_sales,
    total_profit,
    number_of_items,
    ROUND(potential_sales_without_discount - total_sales, 2) as discount_amount,
    ROUND(total_profit / NULLIF(potential_sales_without_discount - total_sales, 0), 2) as roi_on_discount,
    ROUND(100.0 * total_profit / NULLIF(total_sales, 0), 2) as profit_margin
FROM 
    discount_performance
WHERE 
    discount_band <> 'No Discount' -- Only look at discounted items
ORDER BY 
    category, 
    CASE 
        WHEN discount_band = '0-10%' THEN 1
        WHEN discount_band = '11-20%' THEN 2
        WHEN discount_band = '21-30%' THEN 3
        WHEN discount_band = '31-40%' THEN 4
        WHEN discount_band = '41-50%' THEN 5
        ELSE 6
    END;
```