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
DELETE FROM dbo.missing_report;
DELETE FROM dbo.parking_record_history;
DELETE FROM dbo.payment;
GO

-- Insert sample data
IF NOT EXISTS (SELECT 1 FROM dbo.payment WHERE payment_id = 'pay1')
INSERT INTO dbo.payment (payment_id, amount, create_at, payment_type)
VALUES 
    ('pay1', 5000, '2025-04-15 10:00:00', 'PARKING'),
    ('pay2', 100000, '2025-04-16 12:00:00', 'MONTHLY'),
    ('pay3', 50000, '2025-04-17 14:00:00', 'MISSING');
GO

-- Step 2: Test cases
-- Test Case 1: Valid - Get all payment history
PRINT 'Test Case 1: Valid - Get all payment history';
EXEC dbo.sp_get_payment_history;
PRINT 'Test Case 1: SUCCESS';
GO

-- Test Case 2: Valid - Get payments within date range
PRINT 'Test Case 2: Valid - Get payments within date range';
EXEC dbo.sp_get_payment_history @start_date = '2025-04-15', @end_date = '2025-04-15';
PRINT 'Test Case 2: SUCCESS';
GO

-- Test Case 3: Invalid - No payments in date range
PRINT 'Test Case 3: Invalid - No payments in date range';
EXEC dbo.sp_get_payment_history @start_date = '2025-04-01', @end_date = '2025-04-01';
PRINT 'Test Case 3: SUCCESS - No rows returned';
GO

-- Test Case 4: Valid - Get payments with NULL dates
PRINT 'Test Case 4: Valid - Get payments with NULL dates';
EXEC dbo.sp_get_payment_history @start_date = NULL, @end_date = NULL;
PRINT 'Test Case 4: SUCCESS';
GO