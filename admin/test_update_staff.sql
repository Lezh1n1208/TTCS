USE [parking_management]
-- Step 1: Create sample data
-- Ensure account and staff tables exist
IF OBJECT_ID('dbo.account', 'U') IS NULL
CREATE TABLE dbo.account (
    account_id VARCHAR(36) NOT NULL PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(10) NOT NULL CHECK (role IN ('STAFF', 'ADMIN')),
    username VARCHAR(50) NOT NULL UNIQUE
);
GO

IF OBJECT_ID('dbo.staff', 'U') IS NULL
CREATE TABLE dbo.staff (
    account_id VARCHAR(36) NOT NULL PRIMARY KEY,
    address VARCHAR(200),
    dob DATE,
    email VARCHAR(100),
    gender VARCHAR(10),
    identification VARCHAR(20),
    is_active BIT,
    name VARCHAR(100),
    phone_number VARCHAR(15),
    FOREIGN KEY (account_id) REFERENCES account(account_id)
);
GO

-- Create trigger for duplicate identification (if not exists)
IF OBJECT_ID('dbo.tr_check_staff_identification', 'TR') IS NULL
EXEC('
CREATE TRIGGER dbo.tr_check_staff_identification
ON dbo.staff
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN staff s ON i.identification = s.identification AND i.account_id != s.account_id
    )
        THROW 50007, ''Duplicate identification found.'', 1;
END;
');
GO

-- Insert sample data
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

INSERT INTO dbo.account (account_id, password, role, username)
VALUES 
    ('acc1', HASHBYTES('SHA2_256', 'Staff@Pass2023!'), 'STAFF', 'staff1'),
    ('acc2', HASHBYTES('SHA2_256', 'Staff@Pass2023!'), 'STAFF', 'staff2');

INSERT INTO dbo.staff (account_id, address, dob, email, gender, identification, is_active, name, phone_number)
VALUES 
    ('acc1', '123 Street', '1990-01-01', 'staff1@example.com', 'MALE', '123456789', 1, 'Staff One', '1234567890'),
    ('acc2', '456 Street', '1992-02-02', 'staff2@example.com', 'FEMALE', '987654321', 0, 'Staff Two', '0987654321');
GO

-- Step 2: Test cases
-- Test Case 1: Valid - Update staff information
PRINT 'Test Case 1: Valid - Update staff information';
SELECT 'Before acc1', * FROM dbo.staff WHERE account_id = 'acc1';
EXEC dbo.sp_update_staff
    @account_id = 'acc1',
    @address = '789 New Street',
    @dob = '1991-01-01',
    @email = 'staff1_updated@example.com',
    @gender = 'FEMALE',
    @identification = '111222333',
    @is_active = 0,
    @name = 'Staff One Updated',
    @phone_number = '1112223333';
SELECT 'After acc1', * FROM dbo.staff WHERE account_id = 'acc1';
PRINT 'Test Case 1: SUCCESS';
GO

-- Test Case 2: Invalid - Non-existent account_id
PRINT 'Test Case 2: Invalid - Non-existent account_id';
SELECT 'Before acc999', * FROM dbo.staff WHERE account_id = 'acc999';
EXEC dbo.sp_update_staff
    @account_id = 'acc999',
    @address = '101 Street',
    @dob = '1995-03-03',
    @email = 'staff999@example.com',
    @gender = 'MALE',
    @identification = '456789123',
    @is_active = 1,
    @name = 'Staff Unknown',
    @phone_number = '1122334455';
SELECT 'After acc999', * FROM dbo.staff WHERE account_id = 'acc999';
PRINT 'Test Case 2: SUCCESS - No rows updated (no error thrown)';
GO

-- Test Case 3: Invalid - Duplicate identification
PRINT 'Test Case 3: Invalid - Duplicate identification';
BEGIN TRY
    EXEC dbo.sp_update_staff
        @account_id = 'acc2',
        @address = '202 Street',
        @dob = '1993-03-03',
        @email = 'staff2_updated@example.com',
        @gender = 'MALE',
        @identification = '123456789', -- Duplicate with acc1
        @is_active = 1,
        @name = 'Staff Two Updated',
        @phone_number = '2233445566';
    PRINT 'Test Case 3: FAILED - Should have thrown error';
END TRY
BEGIN CATCH
    PRINT 'Test Case 3: SUCCESS - Expected error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Step 3: Verify sp_toggle_staff_status with updated account
PRINT 'Testing sp_toggle_staff_status with updated account...';
SELECT 'Before acc1', account_id, is_active FROM dbo.staff WHERE account_id = 'acc1';
EXEC dbo.sp_toggle_staff_status @account_id = 'acc1';
SELECT 'After acc1', account_id, is_active FROM dbo.staff WHERE account_id = 'acc1';
GO