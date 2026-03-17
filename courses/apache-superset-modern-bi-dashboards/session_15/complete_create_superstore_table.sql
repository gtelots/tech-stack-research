-- Superstore Table Creation SQL
-- Generated on 2025-05-01 07:08:31

DROP TABLE IF EXISTS superstore;

CREATE TABLE superstore (
    row_id VARCHAR(255),
    order_id VARCHAR(255),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(255),
    customer_id VARCHAR(255),
    customer_name VARCHAR(255),
    segment VARCHAR(255),
    country VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    postal_code VARCHAR(255),
    region VARCHAR(255),
    product_id VARCHAR(255),
    category VARCHAR(255),
    sub_category VARCHAR(255),
    product_name VARCHAR(255),
    sales NUMERIC(10, 2),
    quantity INTEGER,
    discount NUMERIC(10, 2),
    profit NUMERIC(10, 2),
    is_return BOOLEAN
);

-- Adding indexes for performance optimization
CREATE INDEX idx_superstore_order_id ON superstore(order_id);
CREATE INDEX idx_superstore_customer_id ON superstore(customer_id);
CREATE INDEX idx_superstore_product_id ON superstore(product_id);
CREATE INDEX idx_superstore_order_date ON superstore(order_date);
