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

IF OBJECT_ID('dbo.vehicle_type', 'U') IS NULL
CREATE TABLE dbo.vehicle_type (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);
GO

IF OBJECT_ID('dbo.parking_card', 'U') IS NULL
CREATE TABLE dbo.parking_card (
    card_id INT NOT NULL PRIMARY KEY,
    card_number VARCHAR(50) NOT NULL,
    is_active BIT NOT NULL
);
GO

IF OBJECT_ID('dbo.payment', 'U') IS NULL
CREATE TABLE dbo.payment (
    payment_id VARCHAR(36) NOT NULL PRIMARY KEY,
    amount INT NOT NULL,
    create_at DATETIME2(6) NOT NULL,
    payment_type VARCHAR(10) NOT NULL CHECK (payment_type IN ('PARKING', 'MONTHLY', 'MISSING'))
);
GO

IF OBJECT_ID('dbo.parking_record', 'U') IS NULL
CREATE TABLE dbo.parking_record (
    record_id VARCHAR(36) NOT NULL PRIMARY KEY,
    entry_time DATETIME NOT NULL,
    license_plate VARCHAR(20),
    identifier VARCHAR(50),
    type VARCHAR(10) NOT NULL CHECK (type IN ('MONTHLY', 'DAILY')),
    card_id INT NOT NULL,
    staff_in VARCHAR(36) NOT NULL,
    vehicle_type VARCHAR(36) NOT NULL,
    FOREIGN KEY (card_id) REFERENCES parking_card(card_id),
    FOREIGN KEY (staff_in) REFERENCES account(account_id),
    FOREIGN KEY (vehicle_type) REFERENCES vehicle_type(id)
);
GO

IF OBJECT_ID('dbo.parking_record_history', 'U') IS NULL
CREATE TABLE dbo.parking_record_history (
    history_id VARCHAR(36) NOT NULL PRIMARY KEY,
    entry_time DATETIME2(6) NOT NULL,
    exit_time DATETIME2(6) NULL,
    identifier VARCHAR(50) NULL,
    license_plate VARCHAR(20) NULL,
    type VARCHAR(10) NOT NULL CHECK (type IN ('MONTHLY', 'DAILY')),
    card_id INT NOT NULL,
    payment_id VARCHAR(36) NULL,
    staff_in VARCHAR(36) NOT NULL,
    staff_out VARCHAR(36) NULL,
    vehicle_type VARCHAR(36) NOT NULL,
    FOREIGN KEY (card_id) REFERENCES parking_card(card_id),
    FOREIGN KEY (payment_id) REFERENCES payment(payment_id),
    FOREIGN KEY (staff_in) REFERENCES account(account_id),
    FOREIGN KEY (staff_out) REFERENCES account(account_id),
    FOREIGN KEY (vehicle_type) REFERENCES vehicle_type(id)
);
GO

IF OBJECT_ID('dbo.missing_report', 'U') IS NULL
CREATE TABLE dbo.missing_report (
    report_id VARCHAR(36) NOT NULL PRIMARY KEY,
    create_at DATETIME2(6) NOT NULL,
    name VARCHAR(100) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    identification VARCHAR(20) NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    address VARCHAR(200) NOT NULL,
    brand VARCHAR(50),
    color VARCHAR(50),
    license_plate VARCHAR(20),
    identifier VARCHAR(50),
    vehicle_type VARCHAR(36) NOT NULL,
    create_by VARCHAR(36) NOT NULL,
    payment_id VARCHAR(36),
    record_id VARCHAR(36),
    FOREIGN KEY (vehicle_type) REFERENCES vehicle_type(id),
    FOREIGN KEY (create_by) REFERENCES account(account_id),
    FOREIGN KEY (payment_id) REFERENCES payment(payment_id),
    FOREIGN KEY (record_id) REFERENCES parking_record_history(history_id)
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

-- Insert sample data
IF NOT EXISTS (SELECT 1 FROM dbo.account WHERE account_id = 'acc1')
INSERT INTO dbo.account (account_id, password, role, username)
VALUES 
    ('acc1', HASHBYTES('SHA2_256', 'Staff@Pass2023!'), 'STAFF', 'staff1'),
    ('acc2', HASHBYTES('SHA2_256', 'Staff@Pass2023!'), 'STAFF', 'staff2');

IF NOT EXISTS (SELECT 1 FROM dbo.staff WHERE account_id = 'acc1')
INSERT INTO dbo.staff (account_id, address, dob, email, gender, identification, is_active, name, phone_number)
VALUES 
    ('acc1', '123 Street', '1990-01-01', 'staff1@example.com', 'MALE', '123456789', 1, 'Staff One', '1234567890'),
    ('acc2', '456 Street', '1992-02-02', 'staff2@example.com', 'FEMALE', '987654321', 1, 'Staff Two', '0987654321');

IF NOT EXISTS (SELECT 1 FROM dbo.vehicle_type WHERE id = 'vt1')
INSERT INTO dbo.vehicle_type (id, name)
VALUES 
    ('vt1', 'Motorbike'),
    ('vt2', 'Bicycle');

IF NOT EXISTS (SELECT 1 FROM dbo.parking_card WHERE card_id = 1)
INSERT INTO dbo.parking_card (card_id)
VALUES (1);

IF NOT EXISTS (SELECT 1 FROM dbo.parking_record WHERE record_id = 'rec1')
INSERT INTO dbo.parking_record (record_id, entry_time, license_plate, identifier, type, card_id, staff_in, vehicle_type)
VALUES 
    ('rec1', '2025-04-15 10:00:00', '29A-12345', NULL, 'DAILY', 1, 'acc1', 'vt1');
GO

-- Step 2: Test cases
-- Test Case 1: Valid - Create missing report with parking record
PRINT 'Test Case 1: Valid - Create missing report with parking record';
EXEC dbo.sp_create_missing_report 
    @report_id = 'mr1',
    @address = '456 Street',
    @brand = 'Honda',
    @color = 'Red',
    @create_at = '2025-04-15 12:00:00',
    @gender = 'MALE',
    @identification = '123456789',
    @identifier = NULL,
    @license_plate = '29A-12345',
    @name = 'John Doe',
    @phone_number = '0987654321',
    @create_by = 'acc2',
    @payment_id = 'pay1',
    @record_id = 'rec1',
    @vehicle_type = 'vt1',
    @missing_fee = 50000;
SELECT * FROM dbo.missing_report WHERE report_id = 'mr1';
SELECT * FROM dbo.payment WHERE payment_id = 'pay1';
SELECT * FROM dbo.parking_record_history WHERE license_plate = '29A-12345';
SELECT * FROM dbo.parking_record WHERE record_id = 'rec1';
PRINT 'Test Case 1: SUCCESS';
GO

-- Test Case 2: Invalid - Invalid create_by
PRINT 'Test Case 2: Invalid - Invalid create_by';
BEGIN TRY
    EXEC dbo.sp_create_missing_report 
        @report_id = 'mr3',
        @address = '123 Street',
        @brand = 'Honda',
        @color = 'Black',
        @create_at = '2025-04-17 12:00:00',
        @gender = 'MALE',
        @identification = '123456780',
        @identifier = NULL,
        @license_plate = '29B-67890',
        @name = 'Bob Wilson',
        @phone_number = '0987654322',
        @create_by = 'acc999',
        @payment_id = 'pay3',
        @record_id = NULL,
        @vehicle_type = 'vt1',
        @missing_fee = 50000;
    PRINT 'Test Case 2: FAILED - Should have thrown error';
END TRY
BEGIN CATCH
    PRINT 'Test Case 2: SUCCESS - Expected error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test Case 3: Invalid - Invalid vehicle_type
PRINT 'Test Case 3: Invalid - Invalid vehicle_type';
BEGIN TRY
    EXEC dbo.sp_create_missing_report 
        @report_id = 'mr4',
        @address = '456 Street',
        @brand = 'Yamaha',
        @color = 'Green',
        @create_at = '2025-04-18 12:00:00',
        @gender = 'FEMALE',
        @identification = '987654322',
        @identifier = NULL,
        @license_plate = '29C-11111',
        @name = 'Alice Brown',
        @phone_number = '0987654323',
        @create_by = 'acc2',
        @payment_id = 'pay4',
        @record_id = NULL,
        @vehicle_type = 'vt999',
        @missing_fee = 50000;
    PRINT 'Test Case 3: FAILED - Should have thrown error';
END TRY
BEGIN CATCH
    PRINT 'Test Case 3: SUCCESS - Expected error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test Case 4: Invalid - Invalid record_id
PRINT 'Test Case 4: Invalid - Invalid record_id';
BEGIN TRY
    EXEC dbo.sp_create_missing_report 
        @report_id = 'mr5',
        @address = '789 Street',
        @brand = 'Honda',
        @color = 'White',
        @create_at = '2025-04-19 12:00:00',
        @gender = 'MALE',
        @identification = '123456781',
        @identifier = NULL,
        @license_plate = '29D-22222',
        @name = 'Tom Clark',
        @phone_number = '0987654324',
        @create_by = 'acc2',
        @payment_id = 'pay5',
        @record_id = 'rec999',
        @vehicle_type = 'vt1',
        @missing_fee = 50000;
    PRINT 'Test Case 4: FAILED - Should have thrown error';
END TRY
BEGIN CATCH
    PRINT 'Test Case 4: SUCCESS - Expected error: ' + ERROR_MESSAGE();
END CATCH;
GO
