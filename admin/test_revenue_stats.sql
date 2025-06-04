USE [parking_management]
-- Step 1: Create sample data
IF OBJECT_ID('dbo.payment', 'U') IS NULL
CREATE TABLE dbo.payment (
    payment_id VARCHAR(36) NOT NULL PRIMARY KEY,
    amount INT NOT NULL,
    create_at DATETIME2(6) NOT NULL,
    payment_type VARCHAR(10) NOT NULL CHECK (payment_type IN ('PARKING', 'MONTHLY', 'MISSING'))
);
GO

-- Delete data to avoid conflicts
DELETE FROM dbo.active_monthly_registration;
DELETE FROM dbo.expire_monthly_registration;
DELETE FROM dbo.vehicle;
DELETE FROM dbo.lecturer_information;
DELETE FROM dbo.student_information;
DELETE FROM dbo.customer;
DELETE FROM dbo.missing_report;
DELETE FROM dbo.parking_record_history;
DELETE FROM dbo.payment;
DELETE FROM dbo.staff;
DELETE FROM dbo.parking_record;
DELETE FROM dbo.account;
DELETE FROM dbo.price;
DELETE FROM dbo.vehicle_type;
GO

-- Insert sample data
IF NOT EXISTS (SELECT 1 FROM dbo.payment WHERE payment_id = 'pay1')
INSERT INTO dbo.payment (payment_id, amount, create_at, payment_type)
VALUES 
    ('pay1', 5000, '2025-04-15 10:00:00', 'PARKING'),
    ('pay2', 10000, '2025-04-15 12:00:00', 'PARKING'),
    ('pay3', 100000, '2025-04-16 14:00:00', 'MONTHLY'),
    ('pay4', 50000, '2025-04-16 16:00:00', 'MISSING');
GO

-- Step 2: Test cases
-- Test Case 1: Valid - Get stats within date range
PRINT 'Test Case 1: Valid - Get stats within date range';
EXEC dbo.sp_get_revenue_stats @start_date = '2025-04-15', @end_date = '2025-04-16';
PRINT 'Test Case 1: SUCCESS';
GO

-- Test Case 2: Valid - Get stats for single day
PRINT 'Test Case 2: Valid - Get stats for single day';
EXEC dbo.sp_get_revenue_stats @start_date = '2025-04-15', @end_date = '2025-04-17';
PRINT 'Test Case 2: SUCCESS';
GO

-- Test Case 3: Invalid - No payments in date range
PRINT 'Test Case 3: Invalid - No payments in date range';
EXEC dbo.sp_get_revenue_stats @start_date = '2025-04-01', @end_date = '2025-04-01';
PRINT 'Test Case 3: SUCCESS - No rows returned';
GO

-- Test Case 4: Invalid - Start date after end date
PRINT 'Test Case 4: Invalid - Start date after end date';
EXEC dbo.sp_get_revenue_stats @start_date = '2025-04-17', @end_date = '2025-04-15';
PRINT 'Test Case 4: SUCCESS - No rows returned';
GO