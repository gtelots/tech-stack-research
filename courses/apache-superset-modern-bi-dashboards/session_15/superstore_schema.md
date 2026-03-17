# Superstore Database Table Schema Documentation

## Table Overview

The `superstore` table contains sales data from a retail superstore, including customer information, product details, order data, and financial metrics.

### Table: `superstore`

| Column Name    | Data Type        | Description                                   | Notes                                |
|----------------|------------------|-----------------------------------------------|--------------------------------------|
| row_id         | VARCHAR(255)     | Unique identifier for each row                | Could be INTEGER but kept as VARCHAR to preserve format |
| order_id       | VARCHAR(255)     | Identifier for each order                     | Multiple rows can have the same order_id |
| order_date     | DATE             | Date when the order was placed                | Format: YYYY-MM-DD                   |
| ship_date      | DATE             | Date when the order was shipped               | Format: YYYY-MM-DD, can be NULL      |
| ship_mode      | VARCHAR(255)     | Shipping method used                          | E.g., "Standard Class", "Second Class" |
| customer_id    | VARCHAR(255)     | Unique identifier for each customer           | Format varies, preserved as VARCHAR   |
| customer_name  | VARCHAR(255)     | Full name of the customer                     | Can be NULL in some records          |
| segment        | VARCHAR(255)     | Market segment the customer belongs to        | E.g., "Consumer", "Corporate", "Home Office" |
| country        | VARCHAR(255)     | Country where the order was placed            | Predominantly "United States" in this dataset |
| city           | VARCHAR(255)     | City where the order was placed               | |
| state          | VARCHAR(255)     | State where the order was placed              | |
| postal_code    | VARCHAR(255)     | Postal code of the delivery address           | Kept as VARCHAR to preserve leading zeros |
| region         | VARCHAR(255)     | Geographic region                             | E.g., "West", "East", "Central", "South" |
| product_id     | VARCHAR(255)     | Unique identifier for each product            | Format typically includes category code |
| category       | VARCHAR(255)     | Main product category                         | E.g., "Furniture", "Office Supplies", "Technology" |
| sub_category   | VARCHAR(255)     | Product sub-category                          | More specific classification within category |
| product_name   | VARCHAR(255)     | Name of the product                           | |
| sales          | NUMERIC(10, 2)   | Total sales amount                            | In currency units (likely USD)       |
| quantity       | INTEGER          | Number of units ordered                       | Whole numbers                        |
| discount       | NUMERIC(10, 2)   | Discount rate applied                         | Decimal between 0 and 1              |
| profit         | NUMERIC(10, 2)   | Profit made from the sale                     | Can be negative (loss)               |
| is_return      | BOOLEAN          | Indicates if the order was returned           | true or false                        |

## Indexes

The following indexes have been created to optimize query performance:

- `idx_superstore_order_id` - Index on order_id for faster order lookups
- `idx_superstore_customer_id` - Index on customer_id for customer-based queries
- `idx_superstore_product_id` - Index on product_id for product-based queries
- `idx_superstore_order_date` - Index on order_date for date range queries

## Data Relationships

- Multiple rows can share the same `order_id`, indicating multiple items in a single order
- Multiple rows can share the same `customer_id`, showing different purchases by the same customer
- The `category` and `sub_category` fields have a hierarchical relationship
- `order_date` and `ship_date` have a temporal relationship (ship_date must be on or after order_date)

## Data Quality Considerations

During the data migration process, several data quality issues were addressed:

1. Missing values in certain fields (e.g., some records had missing ship_date or customer_name)
2. Inconsistent formatting in date fields (standardized to YYYY-MM-DD)
3. Numeric precision for financial fields (standardized to 2 decimal places)
4. Data type conversions (ensuring appropriate types for each column)

## Query Examples

### Basic Queries

```sql
-- Total sales by region
SELECT region, SUM(sales) as total_sales
FROM superstore
GROUP BY region
ORDER BY total_sales DESC;

-- Profit margin by product category
SELECT category, 
       SUM(profit) as total_profit,
       SUM(sales) as total_sales,
       (SUM(profit) / NULLIF(SUM(sales), 0)) * 100 as profit_margin
FROM superstore
GROUP BY category
ORDER BY profit_margin DESC;

-- Orders with highest discounts
SELECT order_id, SUM(sales) as total_order_value, MAX(discount) as max_discount
FROM superstore
GROUP BY order_id
ORDER BY max_discount DESC
LIMIT 10;
