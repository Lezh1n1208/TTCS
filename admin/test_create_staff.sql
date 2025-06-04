use [parking_management]
-- Step 1: Create sample data (if needed)
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

-- Delete data in correct order to avoid FK constraints
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

-- Step 2: Test cases
-- Test Case 1: Valid (Create new staff account)
PRINT 'Test Case 1: Valid - Create new staff account';
BEGIN TRY
    EXEC dbo.sp_create_staff_account
        @account_id = 'acc1',
        @username = 'staff1',
        @password = 'Staff@Pass2023!',
        @role = 'STAFF',
        @address = '456 Street',
        @dob = '1992-02-02',
        @email = 'staff2@example.com',
        @gender = 'FEMALE',
        @identification = '987654321',
        @is_active = 1,
        @name = 'Staff Two',
        @phone_number = '0987654321';
    PRINT 'Test Case 1: SUCCESS';
END TRY
BEGIN CATCH
    PRINT 'Test Case 1: FAILED - Error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test Case 2: Invalid - Duplicate username
PRINT 'Test Case 2: Invalid - Duplicate username';
BEGIN TRY
    EXEC dbo.sp_create_staff_account
        @account_id = 'acc2',
        @username = 'staff1', -- Duplicate with acc1
        @password = 'Staff@Pass2023!',
        @role = 'STAFF',
        @address = '789 Street',
        @dob = '1995-03-03',
        @email = 'staff3@example.com',
        @gender = 'MALE',
        @identification = '456789123',
        @is_active = 1,
        @name = 'Staff Three',
        @phone_number = '1122334455';
    PRINT 'Test Case 2: FAILED - Should have thrown error';
END TRY
BEGIN CATCH
    PRINT 'Test Case 2: SUCCESS - Expected error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test Case 3: Invalid - Duplicate identification (assuming trigger exists)
PRINT 'Test Case 3: Invalid - Duplicate identification';
BEGIN TRY
    EXEC dbo.sp_create_staff_account
        @account_id = 'acc3',
        @username = 'staff4',
        @password = 'Staff@Pass2023!',
        @role = 'STAFF',
        @address = '101 Street',
        @dob = '1996-04-04',
        @email = 'staff4@example.com',
        @gender = 'FEMALE',
        @identification = '987654321', -- Duplicate with acc1
        @is_active = 1,
        @name = 'Staff Four',
        @phone_number = '2233445566';
    PRINT 'Test Case 3: FAILED - Should have thrown error';
END TRY
BEGIN CATCH
    PRINT 'Test Case 3: SUCCESS - Expected error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test Case 4: Invalid - Invalid role
PRINT 'Test Case 4: Invalid - Invalid role';
BEGIN TRY
    EXEC dbo.sp_create_staff_account
        @account_id = 'acc4',
        @username = 'staff5',
        @password = 'Staff@Pass2023!',
        @role = 'INVALID', -- Not STAFF or ADMIN
        @address = '202 Street',
        @dob = '1997-05-05',
        @email = 'staff5@example.com',
        @gender = 'MALE',
        @identification = '789123456',
        @is_active = 1,
        @name = 'Staff Five',
        @phone_number = '3344556677';
    PRINT 'Test Case 4: FAILED - Should have thrown error';
END TRY
BEGIN CATCH
    PRINT 'Test Case 4: SUCCESS - Expected error: ' + ERROR_MESSAGE();
END CATCH;
GO

SELECT * FROM dbo.account a JOIN dbo.staff s on a.account_id = s.account_id;