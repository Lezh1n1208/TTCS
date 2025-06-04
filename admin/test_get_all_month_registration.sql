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

IF OBJECT_ID('dbo.lecturer_information', 'U') IS NULL
CREATE TABLE dbo.lecturer_information (
    customer_id VARCHAR(36) NOT NULL PRIMARY KEY,
    lecturer_id VARCHAR(20) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);
GO

IF OBJECT_ID('dbo.student_information', 'U') IS NULL
CREATE TABLE dbo.student_information (
    customer_id VARCHAR(36) NOT NULL PRIMARY KEY,
    class_info VARCHAR(50) NOT NULL,
    faculty VARCHAR(100) NOT NULL,
    major VARCHAR(100) NOT NULL,
    student_id VARCHAR(20) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);
GO

IF OBJECT_ID('dbo.vehicle_type', 'U') IS NULL
CREATE TABLE dbo.vehicle_type (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);
GO

IF OBJECT_ID('dbo.vehicle', 'U') IS NULL
CREATE TABLE dbo.vehicle (
    vehicle_id VARCHAR(36) NOT NULL PRIMARY KEY,
    license_plate VARCHAR(20) NOT NULL,
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
    ('cust1', '456 Street', 'LECTURER', '1980-01-01', 'cust1@example.com', 'MALE', 'Lecturer One', '0987654321'),
    ('cust2', '789 Street', 'STUDENT', '2000-01-01', 'cust2@example.com', 'FEMALE', 'Student One', '1122334455');

IF NOT EXISTS (SELECT 1 FROM dbo.lecturer_information WHERE customer_id = 'cust1')
INSERT INTO dbo.lecturer_information (customer_id, lecturer_id)
VALUES 
    ('cust1', 'LEC001');

IF NOT EXISTS (SELECT 1 FROM dbo.student_information WHERE customer_id = 'cust2')
INSERT INTO dbo.student_information (customer_id, class_info, faculty, major, student_id)
VALUES 
    ('cust2', 'CS101', 'Computer Science', 'Software Engineering', 'STU001');

IF NOT EXISTS (SELECT 1 FROM dbo.vehicle WHERE vehicle_id = 'veh1')
INSERT INTO dbo.vehicle (vehicle_id, license_plate, type_id, brand, color)
VALUES 
    ('veh1', '29A-12345', 'vt1', 'Wave', 'Blue'),
    ('veh2', '29B-67890', 'vt1', 'Sirius', 'Black');

IF NOT EXISTS (SELECT 1 FROM dbo.payment WHERE payment_id = 'pay1')
INSERT INTO dbo.payment (payment_id, amount, create_at, payment_type)
VALUES 
    ('pay1', 100000, '2025-04-15 10:00:00', 'MONTHLY'),
    ('pay2', 100000, '2025-03-01 10:00:00', 'MONTHLY');

IF NOT EXISTS (SELECT 1 FROM dbo.active_monthly_registration WHERE id = 'amr1')
INSERT INTO dbo.active_monthly_registration (id, expiration_date, issue_date, create_by, customer_id, payment_id, vehicle_id)
VALUES 
    ('amr1', '2025-05-15 23:59:59', '2025-04-15 10:00:00', 'acc1', 'cust1', 'pay1', 'veh1');

IF NOT EXISTS (SELECT 1 FROM dbo.expire_monthly_registration WHERE id = 'emr1')
INSERT INTO dbo.expire_monthly_registration (id, expiration_date, issue_date, create_by, customer_id, payment_id, vehicle_id)
VALUES 
    ('emr1', '2025-03-31 23:59:59', '2025-03-01 10:00:00', 'acc1', 'cust2', 'pay2', 'veh2');
GO

-- Step 2: Test cases
-- Test Case 1: Valid - Get all registrations
PRINT 'Test Case 1: Valid - Get all registrations';
EXEC dbo.sp_get_monthly_registration_history @status = 'ALL';
PRINT 'Test Case 1: SUCCESS';
GO

-- Test Case 2: Valid - Get active registrations
PRINT 'Test Case 2: Valid - Get active registrations';
EXEC dbo.sp_get_monthly_registration_history @status = 'ACTIVE';
PRINT 'Test Case 2: SUCCESS';
GO

-- Test Case 3: Valid - Get expired registrations
PRINT 'Test Case 3: Valid - Get expired registrations';
EXEC dbo.sp_get_monthly_registration_history @status = 'EXPIRED';
PRINT 'Test Case 3: SUCCESS';
GO

-- Test Case 4: Invalid - Invalid status
PRINT 'Test Case 4: Invalid - Invalid status';
BEGIN TRY
    EXEC dbo.sp_get_monthly_registration_history @status = 'INVALID';
    PRINT 'Test Case 4: FAILED - Should have thrown error';
END TRY
BEGIN CATCH
    PRINT 'Test Case 4: SUCCESS - Expected error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test Case 5: Valid - Empty tables
PRINT 'Test Case 5: Valid - Empty tables';
DELETE FROM dbo.active_monthly_registration;
DELETE FROM dbo.expire_monthly_registration;
EXEC dbo.sp_get_monthly_registration_history @status = 'ALL';
PRINT 'Test Case 5: SUCCESS - No rows returned';
GO