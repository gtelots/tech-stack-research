# PostgreSQL Database for Business Intelligence Analysis

This project contains SQL scripts to create and populate a PostgreSQL database with synthetic data for business intelligence analysis. The database contains information about products, customers, and orders with enhanced attributes for detailed BI analysis.

## Contents

- `create_tables.sql`: SQL script to create the database tables with appropriate constraints
- `insert_products.sql`: SQL script to insert 1,000 product records
- `insert_customers.sql`: SQL script to insert 20,000 customer records
- `insert_orders.sql`: SQL script to insert 1,000,000 order records
- `data_generator.py`: Python script used to generate the SQL files

## Database Schema

### Products Table
- `product_id`: Serial Primary Key
- `name`: Product name
- `description`: Product description
- `category`: Product category
- `price`: Selling price
- `cost`: Cost price
- `stock_quantity`: Available stock
- `created_at`: Creation timestamp
- `updated_at`: Last update timestamp

### Customers Table
- `customer_id`: Serial Primary Key
- `first_name`: Customer's first name
- `last_name`: Customer's last name
- `email`: Customer's email (unique)
- `phone`: Customer's phone number
- `address_line1`: Primary address
- `address_line2`: Secondary address
- `city`: City
- `state`: State/Province
- `postal_code`: Postal/ZIP code
- `country`: Country code
- `created_at`: Creation timestamp
- `updated_at`: Last update timestamp

### Orders Table
- `order_id`: Serial Primary Key
- `customer_id`: Foreign Key to customers table
- `product_id`: Foreign Key to products table
- `quantity`: Number of products ordered
- `unit_price`: Price per unit
- `total_amount`: Total order amount
- `discount_percentage`: Percentage discount applied
- `discount_amount`: Amount discounted
- `tax_amount`: Tax applied to the order
- `order_date`: Date and time of the order
- `status`: Order status (Completed, Processing, Shipped, Cancelled, Returned)
- `payment_method`: Method of payment
- `shipping_method`: Shipping method used
- `shipping_cost`: Cost of shipping
- `is_gift`: Whether the order is a gift
- `is_returned`: Whether the order was returned
- `return_date`: Date when order was returned (if applicable)
- `return_reason`: Reason for return (if applicable)
- `delivery_date`: Date when order was delivered
- `sales_channel`: Channel through which the sale was made
- `created_at`: Creation timestamp
- `updated_at`: Last update timestamp

## Business Intelligence Use Cases

The enhanced schema supports various analytical scenarios:

1. **Sales Analysis**: Track revenue, discounts, and taxes over time
2. **Customer Behavior**: Analyze purchasing patterns, returns, and payment preferences
3. **Shipping Analysis**: Evaluate shipping costs and delivery times
4. **Channel Performance**: Compare effectiveness of different sales channels
5. **Return Rate Analysis**: Identify products with high return rates and common return reasons
6. **Discount Effectiveness**: Measure the impact of various discount levels on sales

## How to Use

1. Run the create_tables.sql script to set up the database schema:
   ```
   psql -h $PGHOST -U $PGUSER -d $PGDATABASE -f create_tables.sql
   ```

2. Run the insert scripts to populate the tables:
   ```
   psql -h $PGHOST -U $PGUSER -d $PGDATABASE -f insert_products.sql
   psql -h $PGHOST -U $PGUSER -d $PGDATABASE -f insert_customers.sql
   psql -h $PGHOST -U $PGUSER -d $PGDATABASE -f insert_orders.sql
   ```

3. Alternatively, run the Python script to regenerate all SQL files:
   ```
   python data_generator.py
   ```
