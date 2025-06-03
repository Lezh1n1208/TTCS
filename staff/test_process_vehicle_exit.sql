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

IF OBJECT_ID('dbo.price', 'U') IS NULL
CREATE TABLE dbo.price (
    type_id VARCHAR(36) NOT NULL PRIMARY KEY,
    day_price INT NOT NULL,
    monthly_price INT NOT NULL,
    night_price INT NOT NULL,
    FOREIGN KEY (type_id) REFERENCES vehicle_type(id)
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
    type VARCHAR(10) NOT NULL,
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
    entry_time DATETIME NOT NULL,
    exit_time DATETIME,
    identifier VARCHAR(50),
    license_plate VARCHAR(20),
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

-- Delete data in correct order to avoid FK constraints
DELETE FROM dbo.parking_record_history;
DELETE FROM dbo.parking_record;
DELETE FROM dbo.active_monthly_registration;
DELETE FROM dbo.expire_monthly_registration;
DELETE FROM dbo.payment;
DELETE FROM dbo.price;
DELETE FROM dbo.parking_card;
DELETE FROM dbo.staff;
DELETE FROM dbo.account;
DELETE FROM dbo.vehicle;
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
VALUES 
    (1), (2);

IF NOT EXISTS (SELECT 1 FROM dbo.price WHERE type_id = 'vt1')
INSERT INTO dbo.price (type_id, day_price, monthly_price, night_price)
VALUES 
    ('vt1', 5000, 100000, 7000),
    ('vt2', 2000, 50000, 3000);

IF NOT EXISTS (SELECT 1 FROM dbo.parking_record WHERE record_id = 'rec1')
INSERT INTO dbo.parking_record (record_id, entry_time, license_plate, identifier, type, card_id, staff_in, vehicle_type)
VALUES 
    ('rec1', '2025-04-15 10:00:00', '29A-12345', NULL, 'DAILY', 1, 'acc1', 'vt1'),
    ('rec2', '2025-04-15 20:00:00', NULL, 'BIKE001', 'DAILY', 2, 'acc1', 'vt2');
GO

-- Step 2: Test cases
-- Test Case 1: Valid - Process exit for Motorbike (DAILY, day price)
PRINT 'Test Case 1: Valid - Process exit for Motorbike (DAILY, day price)';
EXEC dbo.sp_process_vehicle_exit 
    @license_plate = '29A-12345', 
    @identifier = NULL, 
    @card_id = 1, 
    @staff_out = 'acc2', 
    @history_id = 'hist1', 
    @payment_id = 'pay1';
SELECT * FROM dbo.parking_record_history WHERE history_id = 'hist1';
SELECT * FROM dbo.payment WHERE payment_id = 'pay1';
PRINT 'Test Case 1: SUCCESS';
GO

-- Test Case 2: Valid - Process exit for Bicycle (DAILY, night price)
PRINT 'Test Case 2: Valid - Process exit for Bicycle (DAILY, night price)';
EXEC dbo.sp_process_vehicle_exit 
    @license_plate = NULL, 
    @identifier = 'BIKE001', 
    @card_id = 2, 
    @staff_out = 'acc2', 
    @history_id = 'hist2', 
    @payment_id = 'pay2';
SELECT * FROM dbo.parking_record_history WHERE history_id = 'hist2';
SELECT * FROM dbo.payment WHERE payment_id = 'pay2';
PRINT 'Test Case 2: SUCCESS';
GO

-- Test Case 3: Invalid - No matching parking record
PRINT 'Test Case 3: Invalid - No matching parking record';
BEGIN TRY
    EXEC dbo.sp_process_vehicle_exit 
        @license_plate = '29B-67890', 
        @identifier = NULL, 
        @card_id = 1, 
        @staff_out = 'acc2', 
        @history_id = 'hist3', 
        @payment_id = 'pay3';
    PRINT 'Test Case 3: FAILED - Should have thrown error';
END TRY
BEGIN CATCH
    PRINT 'Test Case 3: SUCCESS - Expected error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test Case 4: Invalid - Invalid staff_out
PRINT 'Test Case 4: Invalid - Invalid staff_out';
BEGIN TRY
    EXEC dbo.sp_process_vehicle_exit 
        @license_plate = '29A-12345', 
        @identifier = NULL, 
        @card_id = 1, 
        @staff_out = 'acc999', 
        @history_id = 'hist4', 
        @payment_id = 'pay4';
    PRINT 'Test Case 4: FAILED - Should have thrown error';
END TRY
BEGIN CATCH
    PRINT 'Test Case 4: SUCCESS - Expected error: ' + ERROR_MESSAGE();
END CATCH;
GO
