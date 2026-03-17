# Product Table Structure

## Overview
The products table serves as the central repository for all items available for sale in the business. It contains comprehensive details about each product including pricing, inventory, and status information.

## Table Schema

| Column Name     | Data Type      | Constraints                | Description                                           |
|----------------|----------------|---------------------------|-------------------------------------------------------|
| product_id     | INTEGER        | PRIMARY KEY               | Unique identifier for each product                     |
| name           | VARCHAR(100)   | NOT NULL                  | Product name/title                                     |
| description    | TEXT           |                           | Detailed product description                           |
| category       | VARCHAR(50)    |                           | Product category for classification                    |
| price          | DECIMAL(10,2)  | NOT NULL                  | Current selling price                                  |
| cost           | DECIMAL(10,2)  | NOT NULL                  | Purchase or manufacturing cost                         |
| stock_quantity | INTEGER        | NOT NULL                  | Current inventory level                                |
| is_active      | BOOLEAN        | NOT NULL DEFAULT TRUE     | Whether the product is currently active for sale       |
| created_at     | TIMESTAMP      | DEFAULT CURRENT_TIMESTAMP | When the product was added to the system               |
| updated_at     | TIMESTAMP      | DEFAULT CURRENT_TIMESTAMP | When the product was last updated                      |

## Indexes
- **Primary Key Index**: On `product_id` column (automatically created with PRIMARY KEY constraint)
- **Category Index**: `idx_products_category` on `category` column for faster category-based lookups

## Relationships
- **One-to-Many with Orders**: One product can appear in many orders

## Sample Data
The sample dataset includes 1,000 synthetic products across various categories with realistic pricing, inventory levels, and approximately 90% active and 10% inactive products.

## Usage Notes
- The `is_active` field controls product visibility and availability for new orders
- Inactive products remain in the database for historical order analysis
- Price changes are tracked via the `updated_at` timestamp
- Profit margins can be calculated by comparing `price` and `cost` fields
- Inventory valuation uses the `cost` and `stock_quantity` fields