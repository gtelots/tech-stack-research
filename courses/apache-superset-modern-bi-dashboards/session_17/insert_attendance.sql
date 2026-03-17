-- Insert Attendance data for the last 3 years
-- Generate sample attendance data for all employees

-- This function will generate attendance records for all employees for the specified time period
DO $$
DECLARE
    emp_record RECORD;
    current_date DATE := CURRENT_DATE;
    start_date DATE := current_date - INTERVAL '3 years';
    record_date DATE;
    rand FLOAT;
    weekend BOOLEAN;
    status_val VARCHAR(20);
    check_in_time TIME;
    check_out_time TIME;
    work_hours NUMERIC(5,2);
    overtime_hours NUMERIC(5,2);
    notes_text TEXT;
    holiday_dates DATE[];
    is_holiday BOOLEAN;
BEGIN
    -- Define some holidays for the past 3 years (simplified)
    holiday_dates := ARRAY[
        -- 2021 holidays
        '2021-01-01', '2021-01-18', '2021-02-15', '2021-05-31', '2021-07-05', 
        '2021-09-06', '2021-10-11', '2021-11-11', '2021-11-25', '2021-12-24', '2021-12-25', '2021-12-31',
        -- 2022 holidays
        '2022-01-01', '2022-01-17', '2022-02-21', '2022-05-30', '2022-07-04', 
        '2022-09-05', '2022-10-10', '2022-11-11', '2022-11-24', '2022-12-26', '2022-12-31',
        -- 2023 holidays
        '2023-01-01', '2023-01-16', '2023-02-20', '2023-05-29', '2023-06-19', '2023-07-04', 
        '2023-09-04', '2023-10-09', '2023-11-10', '2023-11-23', '2023-12-25', '2023-12-31',
        -- 2024 holidays
        '2024-01-01', '2024-01-15', '2024-02-19', '2024-05-27', '2024-06-19', '2024-07-04', 
        '2024-09-02', '2024-10-14', '2024-11-11', '2024-11-28', '2024-12-25', '2024-12-31'
    ]::DATE[];
    
    -- Loop through each employee
    FOR emp_record IN SELECT employee_id, hire_date FROM employees LOOP
        -- Only generate attendance from hire date if it's later than our start date
        record_date := GREATEST(start_date, emp_record.hire_date);
        
        -- Loop through each day from hire date to current date
        WHILE record_date <= current_date LOOP
            -- Check if it's a weekend (Saturday=6, Sunday=0)
            weekend := EXTRACT(DOW FROM record_date) IN (0, 6);
            
            -- Check if it's a holiday
            is_holiday := record_date = ANY(holiday_dates);
            
            -- Skip weekends for most employees (with small random chance of weekend work)
            IF (NOT weekend) OR (weekend AND RANDOM() < 0.1) THEN
                -- Generate random value for attendance status
                rand := RANDOM();
                
                -- Generate attendance status based on probabilities
                IF is_holiday THEN
                    -- Most people take holidays off
                    IF RANDOM() < 0.95 THEN
                        status_val := 'Holiday';
                    ELSE
                        status_val := 'Present';
                    END IF;
                ELSIF weekend THEN
                    status_val := 'Present'; -- Working on weekend
                ELSIF rand < 0.85 THEN
                    status_val := 'Present';
                ELSIF rand < 0.90 THEN
                    status_val := 'Work From Home';
                ELSIF rand < 0.95 THEN
                    status_val := 'Sick Leave';
                ELSIF rand < 0.98 THEN
                    status_val := 'Vacation';
                ELSE
                    status_val := 'Absent';
                END IF;
                
                -- Generate check-in and check-out times based on status
                IF status_val IN ('Present', 'Work From Home') THEN
                    -- Normal work day
                    check_in_time := '08:00:00'::TIME + (RANDOM() * INTERVAL '1 hour');
                    
                    -- Determine if working overtime
                    IF RANDOM() < 0.2 THEN -- 20% chance of overtime
                        check_out_time := '17:00:00'::TIME + (RANDOM() * INTERVAL '3 hours');
                        work_hours := ROUND((EXTRACT(EPOCH FROM check_out_time - check_in_time)/3600)::numeric, 2);
                        overtime_hours := GREATEST(0, work_hours - 8);
                        work_hours := work_hours - overtime_hours;
                    ELSE
                        check_out_time := '17:00:00'::TIME + (RANDOM() * INTERVAL '1 hour' - INTERVAL '30 minutes');
                        work_hours := ROUND((EXTRACT(EPOCH FROM check_out_time - check_in_time)/3600)::numeric, 2);
                        overtime_hours := 0;
                    END IF;
                    
                    -- Sometimes people leave early
                    IF RANDOM() < 0.05 THEN
                        check_out_time := check_in_time + (RANDOM() * INTERVAL '4 hours');
                        work_hours := ROUND((EXTRACT(EPOCH FROM check_out_time - check_in_time)/3600)::numeric, 2);
                        overtime_hours := 0;
                        notes_text := 'Left early';
                    ELSE
                        notes_text := NULL;
                    END IF;
                    
                ELSIF status_val = 'Half Day' THEN
                    -- Half day
                    IF RANDOM() < 0.5 THEN
                        -- Morning half day
                        check_in_time := '08:00:00'::TIME + (RANDOM() * INTERVAL '30 minutes');
                        check_out_time := '12:00:00'::TIME + (RANDOM() * INTERVAL '1 hour');
                    ELSE
                        -- Afternoon half day
                        check_in_time := '12:00:00'::TIME + (RANDOM() * INTERVAL '1 hour');
                        check_out_time := '17:00:00'::TIME + (RANDOM() * INTERVAL '30 minutes');
                    END IF;
                    
                    work_hours := ROUND((EXTRACT(EPOCH FROM check_out_time - check_in_time)/3600)::numeric, 2);
                    overtime_hours := 0;
                    notes_text := 'Half day';
                    
                ELSIF status_val IN ('Sick Leave', 'Vacation', 'Absent', 'Holiday') THEN
                    -- Not working
                    check_in_time := NULL;
                    check_out_time := NULL;
                    work_hours := 0;
                    overtime_hours := 0;
                    
                    IF status_val = 'Sick Leave' THEN
                        notes_text := 'Sick leave';
                    ELSIF status_val = 'Vacation' THEN
                        notes_text := 'Vacation';
                    ELSIF status_val = 'Absent' THEN
                        notes_text := 'Unplanned absence';
                    ELSIF status_val = 'Holiday' THEN
                        notes_text := 'Company holiday';
                    ELSE
                        notes_text := NULL;
                    END IF;
                ELSE
                    -- Default case
                    check_in_time := NULL;
                    check_out_time := NULL;
                    work_hours := 0;
                    overtime_hours := 0;
                    notes_text := NULL;
                END IF;
                
                -- Insert the attendance record
                INSERT INTO attendance (
                    employee_id, 
                    attendance_date, 
                    check_in, 
                    check_out, 
                    status, 
                    work_hours, 
                    overtime_hours, 
                    notes
                ) VALUES (
                    emp_record.employee_id,
                    record_date,
                    check_in_time,
                    check_out_time,
                    status_val,
                    work_hours,
                    overtime_hours,
                    notes_text
                );
            END IF;
            
            -- Move to next day
            record_date := record_date + INTERVAL '1 day';
        END LOOP;
    END LOOP;
END;
$$;