USE [parking_management]
-- Step 1: Create sample data
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

DELETE FROM dbo.active_monthly_registration;
DELETE FROM dbo.staff;
DELETE FROM dbo.account;
GO

INSERT INTO dbo.account (account_id, password, role, username)
VALUES 
    ('acc1', HASHBYTES('SHA2_256', 'Staff@Pass2023!'), 'STAFF', 'staff1'),
    ('acc2', HASHBYTES('SHA2_256', 'Staff@Pass2023!'), 'STAFF', 'staff2'),
    ('acc3', HASHBYTES('SHA2_256', 'Admin@Pass2023!'), 'ADMIN', 'admin1');

INSERT INTO dbo.staff (account_id, address, dob, email, gender, identification, is_active, name, phone_number)
VALUES 
    ('acc1', '123 Street', '1990-01-01', 'staff1@example.com', 'MALE', '123456789', 1, 'Staff One', '1234567890'),
    ('acc2', '456 Street', '1992-02-02', 'staff2@example.com', 'FEMALE', '987654321', 0, 'Staff Two', '0987654321'),
    ('acc3', '789 Street', '1985-03-03', 'admin@example.com', 'MALE', '111222333', 1, 'Admin', '1112223333');
GO

-- Step 2: Test cases
-- Test Case 1: Get all staff
PRINT 'Test Case 1: Get all staff';
EXEC dbo.sp_get_all_staff;
PRINT 'Test Case 1: SUCCESS';
GO

-- Test Case 2: Empty staff table
PRINT 'Test Case 2: Empty staff table';
DELETE FROM dbo.staff;
EXEC dbo.sp_get_all_staff;
PRINT 'Test Case 2: SUCCESS - No rows returned';
GO
