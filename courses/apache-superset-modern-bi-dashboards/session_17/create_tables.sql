-- HR Analytics Database Schema
-- Create tables for Departments, Employees, Salaries, and Attendance

-- Drop tables if they exist to avoid conflicts
DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS salaries;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

-- Create Departments table
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    department_head VARCHAR(100),
    location VARCHAR(100),
    budget NUMERIC(15, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Employees table
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    department_id INTEGER REFERENCES departments(department_id),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    birth_date DATE,
    gender VARCHAR(10),
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(20),
    job_title VARCHAR(100) NOT NULL,
    employment_status VARCHAR(20) DEFAULT 'Active',  -- Active, On Leave, Terminated
    manager_id INTEGER,  -- Self-reference to employee_id
    education_level VARCHAR(50),
    years_of_experience INTEGER,
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);

-- Create Salaries table
CREATE TABLE salaries (
    salary_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    effective_date DATE NOT NULL,
    end_date DATE,
    amount NUMERIC(12, 2) NOT NULL,
    bonus NUMERIC(12, 2) DEFAULT 0,
    allowance NUMERIC(12, 2) DEFAULT 0,
    tax_percentage NUMERIC(5, 2),
    retirement_contribution NUMERIC(12, 2) DEFAULT 0,
    health_insurance NUMERIC(12, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Attendance table
CREATE TABLE attendance (
    attendance_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    attendance_date DATE NOT NULL,
    check_in TIME,
    check_out TIME,
    status VARCHAR(20) NOT NULL, -- Present, Absent, Half Day, Work From Home, Sick Leave, Vacation
    work_hours NUMERIC(5, 2),
    overtime_hours NUMERIC(5, 2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX idx_employees_department ON employees(department_id);
CREATE INDEX idx_salaries_employee ON salaries(employee_id);
CREATE INDEX idx_attendance_employee ON attendance(employee_id);
CREATE INDEX idx_attendance_date ON attendance(attendance_date);
CREATE INDEX idx_salaries_effective_date ON salaries(effective_date);