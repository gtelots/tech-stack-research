#!/bin/bash

# Setup HR Analytics PostgreSQL Database
# This script runs the SQL files in the correct order to set up the database

echo "Setting up HR Analytics Database..."

# Create tables
echo "Creating tables..."
psql -f create_tables.sql

# Insert departments
echo "Inserting departments..."
psql -f insert_departments.sql

# Insert employees
echo "Inserting employees..."
psql -f insert_employees.sql

# Insert salaries
echo "Inserting salaries..."
psql -f insert_salaries.sql

# Insert attendance
echo "Inserting attendance data (this may take a few minutes)..."
psql -f insert_attendance.sql

echo "Database setup complete!"
