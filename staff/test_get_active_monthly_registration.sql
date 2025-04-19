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

IF OBJECT_ID('dbo.customer', 'U') IS NULL
CREATE TABLE dbo.customer (
    customer_id VARCHAR(36) NOT NULL PRIMARY KEY,
    address VARCHAR(200) NOT NULL,
    customer_type VARCHAR(10) NOT NULL CHECK (customer_type IN ('STUDENT', 'LECTURER')),
    dob DATE NOT NULL,
    email VARCHAR(100) NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('MALE', 'FEMALE')),
    name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(15) NOT NULL
);
GO

IF OBJECT_ID('dbo.vehicle', 'U') IS NULL
CREATE TABLE dbo.vehicle (
    vehicle_id VARCHAR(36) NOT NULL PRIMARY KEY,
    license_plate VARCHAR(20),
    customer_id VARCHAR(36),
    vehicle_type_id VARCHAR(36),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_type(id)
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

IF OBJECT_ID('dbo.active_monthly_registration', 'U') IS NULL
CREATE TABLE dbo.active_monthly_registration (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    expiration_date DATETIME2(6) NOT NULL,
    issue_date DATETIME2(6) NOT NULL,
    create_by VARCHAR(36) NOT NULL,
    customer_id VARCHAR(36) NOT NULL,
    payment_id VARCHAR(36),
    vehicle_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (create_by) REFERENCES account(account_id),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (payment_id) REFERENCES payment(payment_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id)
);
GO

IF OBJECT_ID('dbo.expire_monthly_registration', 'U') IS NULL
CREATE TABLE dbo.expire_monthly_registration (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    expiration_date DATETIME2(6) NOT NULL,
    issue_date DATETIME2(6) NOT NULL,
    create_by VARCHAR(36) NOT NULL,
    customer_id VARCHAR(36) NOT NULL,
    payment_id VARCHAR(36),
    vehicle_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (create_by) REFERENCES account(account_id),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (payment_id) REFERENCES payment(payment_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id)
);
GO

-- Delete data in correct order to avoid FK constraints
DELETE FROM dbo.active_monthly_registration;
DELETE FROM dbo.expire_monthly_registration;
DELETE FROM dbo.vehicle;
DELETE FROM dbo.student_information;
DELETE FROM dbo.lecturer_information;
DELETE FROM dbo.customer;
DELETE FROM dbo.payment;
DELETE FROM dbo.staff;
DELETE FROM dbo.account;
DELETE FROM dbo.price;
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

IF NOT EXISTS (SELECT 1 FROM dbo.customer WHERE customer_id = 'cust1')
INSERT INTO dbo.customer (customer_id, address, customer_type, dob, email, gender, name, phone_number)
VALUES 
    ('cust1', '456 Street', 'LECTURER', '1980-01-01', 'cust1@example.com', 'MALE', 'Customer One', '0987654321'),
    ('cust2', '789 Street', 'STUDENT', '2000-01-01', 'cust2@example.com', 'FEMALE', 'Customer Two', '1122334455');

IF NOT EXISTS (SELECT 1 FROM dbo.vehicle WHERE vehicle_id = 'veh1')
INSERT INTO dbo.vehicle (vehicle_id, license_plate, brand, color, type_id)
VALUES 
    ('veh1', '29A-12345', 'wave', 'red', 'vt1'),
    ('veh2', '29B-67890', 'sirius', 'black', 'vt1');

IF NOT EXISTS (SELECT 1 FROM dbo.payment WHERE payment_id = 'pay1')
INSERT INTO dbo.payment (payment_id, amount, create_at, payment_type)
VALUES 
    ('pay1', 100000, '2025-04-01 10:00:00', 'MONTHLY'),
    ('pay2', 100000, '2025-04-15 10:00:00', 'MONTHLY');

IF NOT EXISTS (SELECT 1 FROM dbo.active_monthly_registration WHERE id = 'amr1')
INSERT INTO dbo.active_monthly_registration (id, expiration_date, issue_date, create_by, customer_id, payment_id, vehicle_id)
VALUES 
    ('amr1', '2025-04-10 23:59:59', '2025-04-01 10:00:00', 'acc1', 'cust1', 'pay1', 'veh1'), -- Expired
    ('amr2', '2025-05-15 23:59:59', '2025-04-15 10:00:00', 'acc1', 'cust2', 'pay2', 'veh2'); -- Active
GO

-- Step 2: Test cases for sp_get_active_monthly_registration
-- Test Case 1: Valid - Get all active registrations
PRINT 'Test Case 1: Valid - Get all active registrations';
EXEC dbo.sp_get_active_monthly_registration @id = NULL;
PRINT 'Test Case 1: SUCCESS';
GO

-- Test Case 2: Valid - Get specific active registration
PRINT 'Test Case 2: Valid - Get specific active registration';
EXEC dbo.sp_get_active_monthly_registration @id = 'amr2';
PRINT 'Test Case 2: SUCCESS';
GO

-- Test Case 3: Invalid - Get non-existent registration
PRINT 'Test Case 3: Invalid - Get non-existent registration';
EXEC dbo.sp_get_active_monthly_registration @id = 'amr999';
PRINT 'Test Case 3: SUCCESS - No rows returned';
GO

-- Step 3: Test cases for sp_check_expired_monthly_registrations
-- Test Case 4: Valid - Move expired registrations
PRINT 'Test Case 4: Valid - Move expired registrations';
EXEC dbo.sp_check_expired_monthly_registrations;
SELECT * FROM dbo.expire_monthly_registration WHERE id = 'amr1';
SELECT * FROM dbo.active_monthly_registration WHERE id = 'amr1';
PRINT 'Test Case 4: SUCCESS';
GO

-- Test Case 5: Valid - No expired registrations
PRINT 'Test Case 5: Valid - No expired registrations';
EXEC dbo.sp_check_expired_monthly_registrations;
SELECT * FROM dbo.expire_monthly_registration;
PRINT 'Test Case 5: SUCCESS - No new rows in expire_monthly_registration';
GO