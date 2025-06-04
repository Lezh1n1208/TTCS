USE [parking_management]
GO

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

IF OBJECT_ID('dbo.vehicle', 'U') IS NULL
CREATE TABLE dbo.vehicle (
    vehicle_id VARCHAR(36) NOT NULL PRIMARY KEY,
    brand VARCHAR(50),
    color VARCHAR(50),
    license_plate VARCHAR(20),
    type_id VARCHAR(36),
    FOREIGN KEY (type_id) REFERENCES vehicle_type(id)
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

IF NOT EXISTS (SELECT 1 FROM dbo.price WHERE type_id = 'vt1')
INSERT INTO dbo.price (type_id, day_price, monthly_price, night_price)
VALUES 
    ('vt1', 5000, 100000, 7000);
GO

-- Step 2: Test cases
-- Test Case 1: Valid - Create registration for LECTURER
PRINT 'Test Case 1: Valid - Create registration for LECTURER';
EXEC dbo.sp_create_active_monthly_registration 
    @id = 'amr1',
    @expiration_date = '2025-05-15 23:59:59',
    @issue_date = '2025-04-15 10:00:00',
    @create_by = 'acc1',
    @payment_id = 'pay1',
    @brand = 'Honda',
    @color = 'Red',
    @license_plate = '29A-12345',
    @type_id = 'vt1',
    @name = 'Lecturer One',
    @gender = 'MALE',
    @dob = '1980-01-01',
    @email = 'lecturer1@example.com',
    @phone_number = '0987654321',
    @address = '456 Street',
    @customer_type = 'LECTURER',
    @lecturer_id = 'LEC001',
    @student_id = NULL,
    @class_info = NULL,
    @faculty = NULL,
	@major = NULL
SELECT * FROM dbo.active_monthly_registration WHERE id = 'amr1';
SELECT * FROM dbo.payment WHERE payment_id = 'pay1';
SELECT * FROM dbo.customer WHERE name = 'Lecturer One';
SELECT * FROM dbo.lecturer_information WHERE lecturer_id = 'LEC001';
SELECT * FROM dbo.vehicle WHERE license_plate = '29A-12345';
PRINT 'Test Case 1: SUCCESS';
GO

-- Test Case 2: Valid - Create registration for STUDENT
PRINT 'Test Case 2: Valid - Create registration for STUDENT';
EXEC dbo.sp_create_active_monthly_registration 
    @id = 'amr2',
    @expiration_date = '2025-05-16 23:59:59',
    @issue_date = '2025-04-16 10:00:00',
    @create_by = 'acc1',
    @payment_id = 'pay2',
    @brand = 'Yamaha',
    @color = 'Blue',
    @license_plate = '29B-67890',
    @type_id = 'vt1',
    @name = 'Student One',
    @gender = 'FEMALE',
    @dob = '2000-01-01',
    @email = 'student1@example.com',
    @phone_number = '1122334455',
    @address = '789 Street',
    @customer_type = 'STUDENT',
    @lecturer_id = NULL,
    @student_id = 'STU001',
    @class_info = 'class01',
    @faculty = 'Information Technology',
	@major = 'Computer Science'
SELECT * FROM dbo.active_monthly_registration WHERE id = 'amr2';
SELECT * FROM dbo.payment WHERE payment_id = 'pay2';
SELECT * FROM dbo.customer WHERE name = 'Student One';
SELECT * FROM dbo.student_information WHERE student_id = 'STU001';
SELECT * FROM dbo.vehicle WHERE license_plate = '29B-67890';
PRINT 'Test Case 2: SUCCESS';
GO

-- Test Case 3: Invalid - Invalid create_by
PRINT 'Test Case 3: Invalid - Invalid create_by';
BEGIN TRY
    EXEC dbo.sp_create_active_monthly_registration 
        @id = 'amr3',
        @expiration_date = '2025-05-17 23:59:59',
        @issue_date = '2025-04-17 10:00:00',
        @create_by = 'acc999',
        @payment_id = 'pay3',
        @brand = 'Honda',
        @color = 'Black',
        @license_plate = '29C-11111',
        @type_id = 'vt1',
        @name = 'Lecturer Two',
        @gender = 'MALE',
        @dob = '1980-01-01',
        @email = 'lecturer2@example.com',
        @phone_number = '0987654322',
        @address = '123 Street',
        @customer_type = 'LECTURER',
        @lecturer_id = 'LEC002',
        @student_id = NULL,
        @class_info = NULL,
		@faculty = NULL,
		@major = NULL
    PRINT 'Test Case 3: FAILED - Should have thrown error';
END TRY
BEGIN CATCH
    PRINT 'Test Case 3: SUCCESS - Expected error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test Case 4: Invalid - Invalid customer_type
PRINT 'Test Case 4: Invalid - Invalid customer_type';
BEGIN TRY
    EXEC dbo.sp_create_active_monthly_registration 
        @id = 'amr4',
        @expiration_date = '2025-05-18 23:59:59',
        @issue_date = '2025-04-18 10:00:00',
        @create_by = 'acc1',
        @payment_id = 'pay4',
        @brand = 'Yamaha',
        @color = 'Green',
        @license_plate = '29D-22222',
        @type_id = 'vt1',
        @name = 'Customer One',
        @gender = 'MALE',
        @dob = '1990-01-01',
        @email = 'customer1@example.com',
        @phone_number = '0987654323',
        @address = '456 Street',
        @customer_type = 'INVALID',
        @lecturer_id = NULL,
        @student_id = NULL,
        @class_info = NULL,
		@faculty = NULL,
		@major = NULL
    PRINT 'Test Case 4: FAILED - Should have thrown error';
END TRY
BEGIN CATCH
    PRINT 'Test Case 4: SUCCESS - Expected error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test Case 5: Invalid - Missing student_id for STUDENT
PRINT 'Test Case 5: Invalid - Missing student_id for STUDENT';
BEGIN TRY
    EXEC dbo.sp_create_active_monthly_registration 
        @id = 'amr5',
        @expiration_date = '2025-05-19 23:59:59',
        @issue_date = '2025-04-19 10:00:00',
        @create_by = 'acc1',
        @payment_id = 'pay5',
        @brand = 'Honda',
        @color = 'White',
        @license_plate = '29E-33333',
        @type_id = 'vt1',
        @name = 'Student Two',
        @gender = 'FEMALE',
        @dob = '2000-01-01',
        @email = 'student2@example.com',
        @phone_number = '0987654324',
        @address = '789 Street',
        @customer_type = 'STUDENT',
        @lecturer_id = NULL,
        @student_id = 'student02',
		@class_info = 'class02',
		@faculty = 'Information Technology',
		@major = 'Computer Science'
    PRINT 'Test Case 5: FAILED - Should have thrown error';
END TRY
BEGIN CATCH
    PRINT 'Test Case 5: SUCCESS - Expected error: ' + ERROR_MESSAGE();
END CATCH;
GO
