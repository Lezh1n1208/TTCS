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

IF OBJECT_ID('dbo.parking_card', 'U') IS NULL
CREATE TABLE dbo.parking_card (
    card_id INT NOT NULL PRIMARY KEY
);

IF OBJECT_ID('dbo.vehicle_type', 'U') IS NULL
CREATE TABLE dbo.vehicle_type (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
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

IF OBJECT_ID('dbo.parking_record_history', 'U') IS NULL
CREATE TABLE dbo.parking_record_history (
    history_id VARCHAR(36) NOT NULL PRIMARY KEY,
    entry_time DATETIME NOT NULL,
    exit_time DATETIME,
    identifier VARCHAR(50),
    license_plate VARCHAR(20) NOT NULL,
    type VARCHAR(20),
    card_id INT,
    payment_id VARCHAR(36),
    staff_in VARCHAR(36) NOT NULL,
    staff_out VARCHAR(36),
    vehicle_type VARCHAR(36) NOT NULL,
    FOREIGN KEY (staff_in) REFERENCES account(account_id),
    FOREIGN KEY (staff_out) REFERENCES account(account_id),
    FOREIGN KEY (vehicle_type) REFERENCES vehicle_type(id),
    FOREIGN KEY (card_id) REFERENCES parking_card(card_id),
    FOREIGN KEY (payment_id) REFERENCES payment(payment_id)
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
    license_plate VARCHAR(20) NOT NULL,
    identifier VARCHAR(50),
    vehicle_type VARCHAR(36) NOT NULL,
    create_by VARCHAR(36) NOT NULL,
    payment_id VARCHAR(36),
    record_id VARCHAR(36),
    FOREIGN KEY (vehicle_type) REFERENCES vehicle_type(id),
    FOREIGN KEY (create_by) REFERENCES account(account_id),
    FOREIGN KEY (payment_id) REFERENCES payment(payment_id)
);
GO

-- Delete data in correct order to avoid FK constraints
DELETE FROM dbo.missing_report;
DELETE FROM dbo.parking_record_history;
DELETE FROM dbo.payment;
DELETE FROM dbo.staff;
DELETE FROM dbo.account;
DELETE FROM dbo.vehicle;
DELETE FROM dbo.vehicle_type;
GO

-- Insert sample data
IF NOT EXISTS (SELECT 1 FROM dbo.account WHERE account_id = 'acc1')
INSERT INTO dbo.account (account_id, password, role, username)
VALUES 
    ('acc1', HASHBYTES('SHA2_256', 'Staff@Pass2023!'), 'STAFF', 'staff1');

IF NOT EXISTS (SELECT 1 FROM dbo.staff WHERE account_id = 'acc1')
INSERT INTO dbo.staff (account_id, address, dob, email, gender, identification, is_active, name, phone_number)
VALUES 
    ('acc1', '123 Street', '1990-01-01', 'staff1@example.com', 'MALE', '123456789', 1, 'Staff One', '1234567890');

IF NOT EXISTS (SELECT 1 FROM dbo.vehicle_type WHERE id = 'vt1')
INSERT INTO dbo.vehicle_type (id, name)
VALUES 
    ('vt1', 'Motorbike');

IF NOT EXISTS (SELECT 1 FROM dbo.parking_card WHERE card_id = 1)
INSERT INTO dbo.parking_card(card_id) VALUES (1), (2);

IF NOT EXISTS (SELECT 1 FROM dbo.payment WHERE payment_id = 'pay1')
INSERT INTO dbo.payment (payment_id, amount, create_at, payment_type)
VALUES 
    ('pay1', 50000, '2025-04-15 10:00:00', 'MISSING'),
	('pay2', 5000, '2025-04-15 10:00:00', 'PARKING');

IF NOT EXISTS (SELECT 1 FROM dbo.parking_record_history WHERE history_id = 'rec1')
INSERT INTO dbo.parking_record_history (history_id, entry_time, exit_time, identifier, license_plate, type, card_id, payment_id, staff_in, staff_out, vehicle_type)
VALUES 
    ('rec1', '2025-04-15 08:00:00', '2025-04-15 12:00:00', 'ID123', '29A-12345', 'DAILY', 1, 'pay2', 'acc1', 'acc1', 'vt1'),
    ('rec2', '2025-04-16 09:00:00', '2025-04-16 14:00:00', 'ID456', '29B-67890', 'DAILY', 2, 'pay1', 'acc1', 'acc1', 'vt1');

IF NOT EXISTS (SELECT 1 FROM dbo.missing_report WHERE report_id = 'mr1')
INSERT INTO dbo.missing_report (report_id, create_at, name, gender, identification, phone_number, address, brand, color, license_plate, identifier, vehicle_type, create_by, payment_id, record_id)
VALUES 
    ('mr1', '2025-04-15 10:00:00', 'John Doe', 'MALE', '987654321', '0987654321', '456 Street', 'Honda', 'Red', '29A-12345', 'ID123', 'vt1', 'acc1', 'pay1', 'rec1'),
    ('mr2', '2025-04-16 12:00:00', 'Jane Smith', 'FEMALE', '123456789', '1122334455', '789 Street', 'Yamaha', 'Blue', '29B-67890', 'ID456', 'vt1', 'acc1', 'pay2', 'rec2');
GO

-- Step 2: Test cases
-- Test Case 1: Valid - Get all missing reports
PRINT 'Test Case 1: Valid - Get all missing reports';
EXEC dbo.sp_get_missing_report_history;
PRINT 'Test Case 1: SUCCESS';
GO

-- Test Case 2: Valid - Get reports within date range
PRINT 'Test Case 2: Valid - Get reports within date range';
EXEC dbo.sp_get_missing_report_history @start_date = '2025-04-15', @end_date = '2025-04-16';
PRINT 'Test Case 2: SUCCESS';
GO

-- Test Case 3: Invalid - No reports in date range
PRINT 'Test Case 3: Invalid - No reports in date range';
EXEC dbo.sp_get_missing_report_history @start_date = '2025-04-01', @end_date = '2025-04-01';
PRINT 'Test Case 3: SUCCESS - No rows returned';
GO

-- Test Case 4: Valid - Get reports with NULL dates
PRINT 'Test Case 4: Valid - Get reports with NULL dates';
EXEC dbo.sp_get_missing_report_history @start_date = NULL, @end_date = NULL;
PRINT 'Test Case 4: SUCCESS';
GO