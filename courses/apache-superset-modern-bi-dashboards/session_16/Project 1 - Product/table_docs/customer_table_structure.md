# Customer Table Structure

## Overview
The customers table stores comprehensive information about individuals who have made purchases from the business. It includes personal details, contact information, and geographical data to support customer relationship management and marketing analysis.

## Table Schema

| Column Name    | Data Type      | Constraints                | Description                                           |
|---------------|----------------|---------------------------|-------------------------------------------------------|
| customer_id   | INTEGER        | PRIMARY KEY               | Unique identifier for each customer                    |
| first_name    | VARCHAR(50)    | NOT NULL                  | Customer's first name                                  |
| last_name     | VARCHAR(50)    | NOT NULL                  | Customer's last name                                   |
| email         | VARCHAR(100)   | NOT NULL, UNIQUE          | Email address (used for communications)                |
| phone         | VARCHAR(50)    |                           | Contact phone number                                   |
| address_line1 | VARCHAR(100)   |                           | Primary address line                                   |
| address_line2 | VARCHAR(100)   |                           | Secondary address line (apt, suite, etc.)              |
| city          | VARCHAR(50)    |                           | City name                                              |
| state         | VARCHAR(50)    |                           | State or province                                      |
| postal_code   | VARCHAR(20)    |                           | Postal or ZIP code                                     |
| country       | VARCHAR(50)    |                           | Country name                                           |
| created_at    | TIMESTAMP      | DEFAULT CURRENT_TIMESTAMP | When the customer record was created                   |
| updated_at    | TIMESTAMP      | DEFAULT CURRENT_TIMESTAMP | When the customer record was last updated              |

## Indexes
- **Primary Key Index**: On `customer_id` column (automatically created with PRIMARY KEY constraint)
- **Email Index**: `idx_customers_email` on `email` column for fast lookups during authentication and communication

## Relationships
- **One-to-Many with Orders**: One customer can place many orders

## Sample Data
The sample dataset includes 20,000 synthetic customers with diverse demographics and geographic distributions to support realistic business analysis.

## Usage Notes
- Customer names are stored separately to facilitate personalized communications
- The combination of address fields allows for comprehensive geographic analysis
- The email field serves as a business key for customer identification
- Customer lifetime value can be calculated by aggregating data from the orders table
- The updated_at timestamp tracks when customer details were last changed