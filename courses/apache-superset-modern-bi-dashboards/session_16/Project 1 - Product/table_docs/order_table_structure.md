# Order Table Structure

## Overview
The orders table is the core transactional table that records all purchase activities. It contains detailed information about each transaction, including product details, customer information, financial data, and fulfillment status.

## Table Schema

| Column Name          | Data Type      | Constraints                | Description                                        |
|---------------------|----------------|---------------------------|----------------------------------------------------|
| order_id            | INTEGER        | PRIMARY KEY               | Unique identifier for each order                    |
| customer_id         | INTEGER        | FOREIGN KEY               | Reference to customers table                        |
| product_id          | INTEGER        | FOREIGN KEY               | Reference to products table                         |
| quantity            | INTEGER        | NOT NULL                  | Number of product units ordered                     |
| unit_price          | DECIMAL(10,2)  | NOT NULL                  | Price per unit at time of purchase                  |
| total_amount        | DECIMAL(10,2)  | NOT NULL                  | Total order amount (before discounts)               |
| discount_percentage | DECIMAL(5,2)   | DEFAULT 0.00              | Percentage discount applied                         |
| discount_amount     | DECIMAL(10,2)  | DEFAULT 0.00              | Monetary discount value                             |
| tax_amount          | DECIMAL(10,2)  | DEFAULT 0.00              | Tax charged on the order                            |
| order_date          | TIMESTAMP      | NOT NULL                  | When the order was placed                           |
| status              | VARCHAR(20)    | NOT NULL                  | Current order status (e.g., Processing, Shipped)    |
| payment_method      | VARCHAR(50)    |                           | Method of payment used                              |
| shipping_method     | VARCHAR(50)    |                           | Method of delivery                                  |
| shipping_cost       | DECIMAL(8,2)   | DEFAULT 0.00              | Cost of shipping                                    |
| is_gift             | BOOLEAN        | DEFAULT FALSE             | Whether the order is a gift                         |
| is_returned         | BOOLEAN        | DEFAULT FALSE             | Whether the order has been returned                 |
| return_date         | TIMESTAMP      |                           | When the return was processed                       |
| return_reason       | VARCHAR(200)   |                           | Reason for return                                   |
| delivery_date       | TIMESTAMP      |                           | When the order was delivered                        |
| sales_channel       | VARCHAR(50)    |                           | Channel through which the order was placed          |
| created_at          | TIMESTAMP      | DEFAULT CURRENT_TIMESTAMP | When the order record was created                   |
| updated_at          | TIMESTAMP      | DEFAULT CURRENT_TIMESTAMP | When the order record was last updated              |

## Indexes
- **Primary Key Index**: On `order_id` column (automatically created with PRIMARY KEY constraint)
- **Customer Index**: `idx_orders_customer_id` on `customer_id` column for faster customer-based lookups
- **Product Index**: `idx_orders_product_id` on `product_id` column for faster product-based lookups
- **Date Index**: `idx_orders_order_date` on `order_date` column for time-series analysis

## Relationships
- **Many-to-One with Customers**: Many orders can be placed by one customer
- **Many-to-One with Products**: Many orders can include one product (in this schema design)

## Sample Data
The sample dataset includes 1,000,000 synthetic order transactions spanning a two-year period, with realistic patterns of purchasing behavior, seasonal variations, and return rates.

## Usage Notes
- The `unit_price` field captures the price at the time of purchase, which may differ from the current product price
- Order status progression can be tracked through the `status` field and `updated_at` timestamp
- Return analytics can be performed using the `is_returned`, `return_date`, and `return_reason` fields
- Sales channel analysis allows for comparison of different ordering platforms
- The `total_amount` field should equal `quantity` × `unit_price`
- Only orders for active products (where products.is_active = TRUE) are generated in the system