# HR Analytics Database

This project provides a PostgreSQL database schema and synthetic data for HR analytics. It includes data for departments, employees, salaries, and attendance records spanning the last 3 years.

## Database Structure

The database consists of the following tables:

1. **departments** - Information about company departments
2. **employees** - Comprehensive employee data including personal and professional information
3. **salaries** - Historical and current salary information for all employees
4. **attendance** - Daily attendance records for all employees over the past 3 years

## Data Volume

- 5 departments
- 100+ employees
- Salary records for each employee (including historical salary changes)
- Attendance records for the past 3 years (~75,000 records)

## Files

- `create_tables.sql` - Creates the database schema
- `insert_departments.sql` - Inserts the department data
- `insert_employees.sql` - Inserts the employee data
- `insert_salaries.sql` - Inserts the salary data
- `insert_attendance.sql` - Generates attendance data for the past 3 years
- `setup_database.sh` - Shell script to run all SQL files in the correct order

## Setup Instructions

1. Ensure PostgreSQL is installed and running
2. Navigate to the project directory
3. Run the setup script:
   ```
   ./setup_database.sh
   ```

## Schema Documentation

### Departments Table
| Column          | Type          | Description                       |
|-----------------|---------------|-----------------------------------|
| department_id   | SERIAL PK     | Unique identifier                 |
| department_name | VARCHAR(100)  | Name of the department            |
| department_head | VARCHAR(100)  | Head of the department            |
| location        | VARCHAR(100)  | Physical location                 |
| budget          | NUMERIC(15,2) | Annual budget allocation          |
| created_at      | TIMESTAMP     | Record creation timestamp         |
| updated_at      | TIMESTAMP     | Record update timestamp           |

### Employees Table
| Column                  | Type          | Description                       |
|-------------------------|---------------|-----------------------------------|
| employee_id             | SERIAL PK     | Unique identifier                 |
| department_id           | INTEGER FK    | Department reference              |
| first_name              | VARCHAR(50)   | Employee's first name             |
| last_name               | VARCHAR(50)   | Employee's last name              |
| email                   | VARCHAR(100)  | Employee's email (unique)         |
| phone                   | VARCHAR(20)   | Contact phone number              |
| hire_date               | DATE          | Date of employment                |
| birth_date              | DATE          | Date of birth                     |
| gender                  | VARCHAR(10)   | Gender identity                   |
| address                 | VARCHAR(200)  | Street address                    |
| city                    | VARCHAR(100)  | City of residence                 |
| state                   | VARCHAR(50)   | State/province                    |
| country                 | VARCHAR(50)   | Country                           |
| postal_code             | VARCHAR(20)   | ZIP/postal code                   |
| job_title               | VARCHAR(100)  | Current job title                 |
| employment_status       | VARCHAR(20)   | Active, On Leave, Terminated      |
| manager_id              | INTEGER FK    | References employee_id            |
| education_level         | VARCHAR(50)   | Highest education achieved        |
| years_of_experience     | INTEGER       | Prior work experience             |
| emergency_contact_name  | VARCHAR(100)  | Emergency contact                 |
| emergency_contact_phone | VARCHAR(20)   | Emergency phone                   |
| created_at              | TIMESTAMP     | Record creation timestamp         |
| updated_at              | TIMESTAMP     | Record update timestamp           |

### Salaries Table
| Column                   | Type          | Description                      |
|--------------------------|---------------|----------------------------------|
| salary_id                | SERIAL PK     | Unique identifier                |
| employee_id              | INTEGER FK    | Employee reference               |
| effective_date           | DATE          | When salary takes effect         |
| end_date                 | DATE          | When salary ends (null=current)  |
| amount                   | NUMERIC(12,2) | Base salary amount               |
| bonus                    | NUMERIC(12,2) | Annual bonus amount              |
| allowance                | NUMERIC(12,2) | Additional allowances            |
| tax_percentage           | NUMERIC(5,2)  | Tax withholding percentage       |
| retirement_contribution  | NUMERIC(12,2) | 401k or similar contributions    |
| health_insurance         | NUMERIC(12,2) | Health insurance premium         |
| created_at               | TIMESTAMP     | Record creation timestamp        |
| updated_at               | TIMESTAMP     | Record update timestamp          |

### Attendance Table
| Column           | Type          | Description                       |
|------------------|---------------|-----------------------------------|
| attendance_id    | SERIAL PK     | Unique identifier                 |
| employee_id      | INTEGER FK    | Employee reference                |
| attendance_date  | DATE          | Date of attendance record         |
| check_in         | TIME          | Time employee checked in          |
| check_out        | TIME          | Time employee checked out         |
| status           | VARCHAR(20)   | Present, Absent, etc.             |
| work_hours       | NUMERIC(5,2)  | Regular hours worked              |
| overtime_hours   | NUMERIC(5,2)  | Overtime hours worked             |
| notes            | TEXT          | Additional information            |
| created_at       | TIMESTAMP     | Record creation timestamp         |
| updated_at       | TIMESTAMP     | Record update timestamp           |

## Analytics Use Cases

This dataset is designed to support various HR analytics use cases, including:

1. **Attendance Analysis**
   - Absenteeism rates
   - Work from home patterns
   - Overtime analysis

2. **Compensation Analysis**
   - Salary distributions
   - Pay equity
   - Salary growth trends

3. **Workforce Demographics**
   - Department distribution
   - Gender distribution
   - Geographic distribution

4. **Employee Performance**
   - Attendance correlation with performance
   - Salary progression analysis
   - Tenure analysis
