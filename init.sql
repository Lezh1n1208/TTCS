-- Script for parking_management database
-- Created for parking management system with RBAC and full business logic
-- Fixed for SQL Server 2022 container (password policy, role assignment)
-- Date: 2025-04-17

-- Step 1: Drop database if exists to avoid conflicts
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'parking_management')
    DROP DATABASE parking_management;
GO

-- Step 2: Create database with file paths suitable for container
CREATE DATABASE [parking_management]
ON PRIMARY 
( NAME = N'parking_management', FILENAME = N'/var/opt/mssql/data/parking_management.mdf', SIZE = 8192KB, MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
LOG ON 
( NAME = N'parking_management_log', FILENAME = N'/var/opt/mssql/data/parking_management_log.ldf', SIZE = 8192KB, MAXSIZE = 2048GB, FILEGROWTH = 65536KB );
GO

-- Step 3: Configure database settings
USE [parking_management];
GO

ALTER DATABASE [parking_management] SET COMPATIBILITY_LEVEL = 160;
ALTER DATABASE [parking_management] SET ANSI_NULL_DEFAULT OFF;
ALTER DATABASE [parking_management] SET ANSI_NULLS ON;
ALTER DATABASE [parking_management] SET ANSI_PADDING ON;
ALTER DATABASE [parking_management] SET ANSI_WARNINGS ON;
ALTER DATABASE [parking_management] SET ARITHABORT ON;
ALTER DATABASE [parking_management] SET AUTO_CLOSE OFF;
ALTER DATABASE [parking_management] SET AUTO_SHRINK OFF;
ALTER DATABASE [parking_management] SET AUTO_UPDATE_STATISTICS ON;
ALTER DATABASE [parking_management] SET CURSOR_CLOSE_ON_COMMIT OFF;
ALTER DATABASE [parking_management] SET CURSOR_DEFAULT GLOBAL;
ALTER DATABASE [parking_management] SET CONCAT_NULL_YIELDS_NULL ON;
ALTER DATABASE [parking_management] SET NUMERIC_ROUNDABORT OFF;
ALTER DATABASE [parking_management] SET QUOTED_IDENTIFIER ON;
ALTER DATABASE [parking_management] SET RECURSIVE_TRIGGERS OFF;
ALTER DATABASE [parking_management] SET ENABLE_BROKER;
ALTER DATABASE [parking_management] SET AUTO_UPDATE_STATISTICS_ASYNC OFF;
ALTER DATABASE [parking_management] SET DATE_CORRELATION_OPTIMIZATION OFF;
ALTER DATABASE [parking_management] SET TRUSTWORTHY OFF;
ALTER DATABASE [parking_management] SET ALLOW_SNAPSHOT_ISOLATION OFF;
ALTER DATABASE [parking_management] SET PARAMETERIZATION SIMPLE;
ALTER DATABASE [parking_management] SET READ_COMMITTED_SNAPSHOT OFF;
ALTER DATABASE [parking_management] SET HONOR_BROKER_PRIORITY OFF;
ALTER DATABASE [parking_management] SET RECOVERY FULL;
ALTER DATABASE [parking_management] SET MULTI_USER;
ALTER DATABASE [parking_management] SET PAGE_VERIFY CHECKSUM;
ALTER DATABASE [parking_management] SET DB_CHAINING OFF;
ALTER DATABASE [parking_management] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF );
ALTER DATABASE [parking_management] SET TARGET_RECOVERY_TIME = 60 SECONDS;
ALTER DATABASE [parking_management] SET DELAYED_DURABILITY = DISABLED;
ALTER DATABASE [parking_management] SET ACCELERATED_DATABASE_RECOVERY = OFF;
GO

EXEC sys.sp_db_vardecimal_storage_format N'parking_management', N'ON';
GO

ALTER DATABASE [parking_management] SET QUERY_STORE = ON;
ALTER DATABASE [parking_management] SET QUERY_STORE (
    OPERATION_MODE = READ_WRITE,
    CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30),
    DATA_FLUSH_INTERVAL_SECONDS = 900,
    INTERVAL_LENGTH_MINUTES = 60,
    MAX_STORAGE_SIZE_MB = 1000,
    QUERY_CAPTURE_MODE = AUTO,
    SIZE_BASED_CLEANUP_MODE = AUTO,
    MAX_PLANS_PER_QUERY = 200
);
GO

-- Step 4: Create logins and users with error handling
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'login_admin')
        CREATE LOGIN [login_admin] WITH PASSWORD = 'Admin@123', DEFAULT_DATABASE = [parking_management];
END TRY
BEGIN CATCH
    PRINT 'Error creating login admin: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO

BEGIN TRY
    IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'login_staff')
        CREATE LOGIN [login_staff] WITH PASSWORD = 'Staff@456', DEFAULT_DATABASE = [parking_management];
END TRY
BEGIN CATCH
    PRINT 'Error creating login staff: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO

USE [parking_management];
GO

-- Create user and assign to login
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'APP_ADMIN')
        CREATE USER [APP_ADMIN] FOR LOGIN [login_admin] WITH DEFAULT_SCHEMA = [dbo];
END TRY
BEGIN CATCH
    PRINT 'Error creating staff user: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO

BEGIN TRY
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'APP_STAFF')
        CREATE USER [APP_STAFF] FOR LOGIN [login_staff] WITH DEFAULT_SCHEMA = [dbo];
END TRY
BEGIN CATCH
    PRINT 'Error creating admin user: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO

-- Step 5: Create roles and assign permissions
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'ROLE_ADMIN' AND type = 'R')
    CREATE ROLE [ROLE_ADMIN];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'ROLE_STAFF' AND type = 'R')
    CREATE ROLE [ROLE_STAFF];
GO

-- Grant database permissions to roles (not roles to avoid Msg 15413)
ALTER ROLE [db_datareader] ADD MEMBER [ROLE_ADMIN];
ALTER ROLE [db_datawriter] ADD MEMBER [ROLE_ADMIN];
ALTER ROLE [db_datareader] ADD MEMBER [ROLE_STAFF];
ALTER ROLE [db_datawriter] ADD MEMBER [ROLE_STAFF];
GO

-- Assign users to roles
ALTER ROLE [ROLE_ADMIN] ADD MEMBER [APP_ADMIN];
ALTER ROLE [ROLE_STAFF] ADD MEMBER [APP_STAFF];
GO

-- Step 6: Create tables
IF OBJECT_ID('dbo.account', 'U') IS NOT NULL DROP TABLE dbo.account;
CREATE TABLE dbo.account (
    account_id VARCHAR(36) NOT NULL PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(10) NOT NULL CHECK (role IN ('STAFF', 'ADMIN')),
    username VARCHAR(50) NOT NULL UNIQUE

);

IF OBJECT_ID('dbo.staff', 'U') IS NOT NULL DROP TABLE dbo.staff;
CREATE TABLE dbo.staff (
    account_id VARCHAR(36) NOT NULL PRIMARY KEY,
    address VARCHAR(200) NOT NULL,
    dob DATE NOT NULL,
    email VARCHAR(100) NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('MALE', 'FEMALE')),
    identification VARCHAR(20) NOT NULL UNIQUE,
    is_active BIT NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    FOREIGN KEY (account_id) REFERENCES account(account_id)
);

IF OBJECT_ID('dbo.vehicle_type', 'U') IS NOT NULL DROP TABLE dbo.vehicle_type;
CREATE TABLE dbo.vehicle_type (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

IF OBJECT_ID('dbo.price', 'U') IS NOT NULL DROP TABLE dbo.price;
CREATE TABLE dbo.price (
    type_id VARCHAR(36) NOT NULL PRIMARY KEY,
    day_price INT NOT NULL,
    monthly_price INT NOT NULL,
    night_price INT NOT NULL,
    FOREIGN KEY (type_id) REFERENCES vehicle_type(id)
);

IF OBJECT_ID('dbo.customer', 'U') IS NOT NULL DROP TABLE dbo.customer;
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

IF OBJECT_ID('dbo.lecturer_information', 'U') IS NOT NULL DROP TABLE dbo.lecturer_information;
CREATE TABLE dbo.lecturer_information (
    customer_id VARCHAR(36) NOT NULL PRIMARY KEY,
    lecturer_id VARCHAR(20) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

IF OBJECT_ID('dbo.student_information', 'U') IS NOT NULL DROP TABLE dbo.student_information;
CREATE TABLE dbo.student_information (
    customer_id VARCHAR(36) NOT NULL PRIMARY KEY,
    class_info VARCHAR(50) NOT NULL,
    faculty VARCHAR(100) NOT NULL,
    major VARCHAR(100) NOT NULL,
    student_id VARCHAR(20) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

IF OBJECT_ID('dbo.vehicle', 'U') IS NOT NULL DROP TABLE dbo.vehicle;
CREATE TABLE dbo.vehicle (
    vehicle_id VARCHAR(36) NOT NULL PRIMARY KEY,
    brand VARCHAR(50) NULL,
    color VARCHAR(30) NULL,
    license_plate VARCHAR(20) NULL UNIQUE,
    type_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (type_id) REFERENCES vehicle_type(id)
);

IF OBJECT_ID('dbo.parking_card', 'U') IS NOT NULL DROP TABLE dbo.parking_card;
CREATE TABLE dbo.parking_card (
    card_id INT NOT NULL PRIMARY KEY
);

IF OBJECT_ID('dbo.payment', 'U') IS NOT NULL DROP TABLE dbo.payment;
CREATE TABLE dbo.payment (
    payment_id VARCHAR(36) NOT NULL PRIMARY KEY,
    amount INT NOT NULL,
    create_at DATETIME2(6) NOT NULL,
    payment_type VARCHAR(10) NOT NULL CHECK (payment_type IN ('PARKING', 'MONTHLY', 'MISSING'))
);

IF OBJECT_ID('dbo.parking_record', 'U') IS NOT NULL DROP TABLE dbo.parking_record;
CREATE TABLE dbo.parking_record (
    record_id VARCHAR(36) NOT NULL PRIMARY KEY,
    entry_time DATETIME2(6) NOT NULL,
    identifier VARCHAR(50) NULL,
    license_plate VARCHAR(20) NULL,
    type VARCHAR(10) NOT NULL CHECK (type IN ('MONTHLY', 'DAILY')),
    card_id INT NOT NULL,
    staff_in VARCHAR(36) NOT NULL,
    vehicle_type VARCHAR(36) NOT NULL,
    FOREIGN KEY (card_id) REFERENCES parking_card(card_id),
    FOREIGN KEY (staff_in) REFERENCES account(account_id),
    FOREIGN KEY (vehicle_type) REFERENCES vehicle_type(id)
);

IF OBJECT_ID('dbo.parking_record_history', 'U') IS NOT NULL DROP TABLE dbo.parking_record_history;
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

IF OBJECT_ID('dbo.active_monthly_registration', 'U') IS NOT NULL DROP TABLE dbo.active_monthly_registration;
CREATE TABLE dbo.active_monthly_registration (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    expiration_date DATETIME2(6) NOT NULL,
    issue_date DATETIME2(6) NOT NULL,
    create_by VARCHAR(36) NOT NULL,
    customer_id VARCHAR(36) NOT NULL,
    payment_id VARCHAR(36) NOT NULL UNIQUE,
    vehicle_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (create_by) REFERENCES account(account_id),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (payment_id) REFERENCES payment(payment_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id)
);

IF OBJECT_ID('dbo.expire_monthly_registration', 'U') IS NOT NULL DROP TABLE dbo.expire_monthly_registration;
CREATE TABLE dbo.expire_monthly_registration (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    expiration_date DATETIME2(6) NOT NULL,
    issue_date DATETIME2(6) NOT NULL,
    create_by VARCHAR(36) NOT NULL,
    customer_id VARCHAR(36) NOT NULL,
    payment_id VARCHAR(36) NOT NULL UNIQUE,
    vehicle_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (create_by) REFERENCES account(account_id),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (payment_id) REFERENCES payment(payment_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id)
);

IF OBJECT_ID('dbo.missing_report', 'U') IS NOT NULL DROP TABLE dbo.missing_report;
CREATE TABLE dbo.missing_report (
    report_id VARCHAR(36) NOT NULL PRIMARY KEY,
    address VARCHAR(200) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    color VARCHAR(30) NOT NULL,
    create_at DATETIME2(6) NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('MALE', 'FEMALE')),
    identification VARCHAR(30) NOT NULL,
    identifier VARCHAR(20) NULL,
    license_plate VARCHAR(20) NULL,
    name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    create_by VARCHAR(36) NOT NULL,
    payment_id VARCHAR(36) NOT NULL UNIQUE,
    record_id VARCHAR(36) NULL UNIQUE,
    vehicle_type VARCHAR(36) NOT NULL,
    FOREIGN KEY (create_by) REFERENCES account(account_id),
    FOREIGN KEY (payment_id) REFERENCES payment(payment_id),
    FOREIGN KEY (record_id) REFERENCES parking_record_history(history_id),
    FOREIGN KEY (vehicle_type) REFERENCES vehicle_type(id)
);
GO

-- Step 7: Create indexes
CREATE NONCLUSTERED INDEX IX_parking_record_license_plate_card_id
ON parking_record (license_plate, card_id);

CREATE NONCLUSTERED INDEX IX_active_monthly_registration_expiration_date
ON active_monthly_registration (expiration_date);

CREATE NONCLUSTERED INDEX IX_payment_create_at
ON payment (create_at);
GO

-- Step 8: Create triggers
IF OBJECT_ID('dbo.tr_check_staff_identification', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_check_staff_identification;
GO
CREATE TRIGGER dbo.tr_check_staff_identification
ON dbo.staff
FOR INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN staff s ON s.identification = i.identification
        WHERE s.account_id != i.account_id
    )
    BEGIN
        THROW 50001, 'Duplicate identification found.', 1;
        ROLLBACK;
    END
END;
GO

IF OBJECT_ID('dbo.tr_check_monthly_registration_customer', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_check_monthly_registration_customer;
GO
CREATE TRIGGER dbo.tr_check_monthly_registration_customer
ON dbo.active_monthly_registration
FOR INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN customer c ON c.customer_id = i.customer_id
        WHERE c.customer_type NOT IN ('LECTURER', 'STUDENT')
    )
    BEGIN
        THROW 50002, 'Only LECTURER or STUDENT can register monthly.', 1;
        ROLLBACK;
    END
END;
GO

IF OBJECT_ID('dbo.tr_check_parking_card_usage', 'TR') IS NOT NULL DROP TRIGGER dbo.tr_check_parking_card_usage;
GO
CREATE TRIGGER dbo.tr_check_parking_card_usage
ON dbo.parking_record
FOR INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN parking_record pr ON pr.card_id = i.card_id
        WHERE pr.record_id != i.record_id
    )
    BEGIN
        THROW 50003, 'Card is already in use.', 1;
        ROLLBACK;
    END
END;
GO

-- Step 9: Create stored procedures

-- **ADMIN**
-- Account and Staff Management
-- Stored procedure Create staff account
IF OBJECT_ID('dbo.sp_create_staff_account', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_create_staff_account;
GO
CREATE PROCEDURE dbo.sp_create_staff_account
    @account_id VARCHAR(36),
    @username NVARCHAR(50),
    @password NVARCHAR(50),
    @role VARCHAR(10),
    @address VARCHAR(200),
    @dob DATE,
    @email VARCHAR(100),
    @gender VARCHAR(10),
    @identification VARCHAR(20),
    @is_active BIT,
    @name VARCHAR(100),
    @phone_number VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Insert into account table
        INSERT INTO account (account_id, username, password, role)
        VALUES (@account_id, @username, HASHBYTES('SHA2_256', @password), @role);

        -- Insert into staff table
        IF NOT EXISTS (SELECT 1 FROM account WHERE account_id = @account_id)
            THROW 50005, 'Account does not exist.', 1;

        INSERT INTO staff (account_id, address, dob, email, gender, identification, is_active, name, phone_number)
        VALUES (@account_id, @address, @dob, @email, @gender, @identification, @is_active, @name, @phone_number);

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        PRINT 'Error in sp_create_staff_account: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
GO

-- Store procedure update staff
IF OBJECT_ID('dbo.sp_update_staff', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_update_staff;
GO
CREATE PROCEDURE dbo.sp_update_staff
    @account_id VARCHAR(36),
    @address VARCHAR(200),
    @dob DATE,
    @email VARCHAR(100),
    @gender VARCHAR(10),
    @identification VARCHAR(20),
    @is_active BIT,
    @name VARCHAR(100),
    @phone_number VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE staff
    SET address = @address,
        dob = @dob,
        email = @email,
        gender = @gender,
        identification = @identification,
        is_active = @is_active,
        name = @name,
        phone_number = @phone_number
    WHERE account_id = @account_id;
END;
GO

-- Stored procedure to toggle staff status between ACTIVE and INACTIVE
IF OBJECT_ID('dbo.sp_toggle_staff_status', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_toggle_staff_status;
GO
CREATE PROCEDURE dbo.sp_toggle_staff_status
    @account_id VARCHAR(36)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate account_id
        IF NOT EXISTS (SELECT 1 FROM dbo.staff WHERE account_id = @account_id)
            THROW 50026, 'Invalid account_id. Not a staff account.', 1;

        -- Toggle is_active status in staff
        UPDATE dbo.staff
        SET is_active = CASE WHEN is_active = 1 THEN 0 ELSE 1 END
        WHERE account_id = @account_id;

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        PRINT 'Error in sp_toggle_staff_status: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
GO

-- Stored procedured to get staff by account_id
IF OBJECT_ID('dbo.sp_get_staff', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_get_staff;
GO
CREATE PROCEDURE dbo.sp_get_staff
    @account_id VARCHAR(36)
AS
BEGIN
    SELECT * FROM staff WHERE account_id = @account_id;
END;
GO

-- Stored procedured to get all staffs
IF OBJECT_ID('dbo.sp_get_all_staff', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_get_all_staff;
GO
CREATE PROCEDURE dbo.sp_get_all_staff
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        s.account_id,
        s.name,
        s.address,
        s.dob,
        s.email,
        s.gender,
        s.identification,
        s.is_active,
        s.phone_number,
        a.username,
        a.role
    FROM staff s
    JOIN account a ON s.account_id = a.account_id
    ORDER BY s.name;
END;
GO

-- Price Management for admin
-- Stored procedure update price by vehicle type
IF OBJECT_ID('dbo.sp_update_price_by_vehicle_type', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_update_price_by_vehicle_type;
GO
CREATE PROCEDURE dbo.sp_update_price_by_vehicle_type
    @vehicle_type_id VARCHAR(36),
    @day_price INT,
    @monthly_price INT,
    @night_price INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE price
    SET day_price = @day_price,
        monthly_price = @monthly_price,
        night_price = @night_price
    WHERE type_id = @vehicle_type_id;
END;
GO

-- Get price by vehicle_type
IF OBJECT_ID('dbo.sp_get_price_by_vehicle_type', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_get_price_by_vehicle_type;
GO
CREATE PROCEDURE dbo.sp_get_price_by_vehicle_type
    @vehicle_type_id VARCHAR(36)
AS
BEGIN
    SELECT p.type_id, vt.name AS vehicle_type_name, p.day_price, p.monthly_price, p.night_price
    FROM price p
    JOIN vehicle_type vt ON vt.id = p.type_id
    WHERE p.type_id = @vehicle_type_id;
END;
GO

-- History for admin
-- Stored procedure to get parking record history
IF OBJECT_ID('dbo.sp_get_parking_record_history', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_get_parking_record_history;
GO
CREATE PROCEDURE dbo.sp_get_parking_record_history
    @start_date DATE = NULL,
    @end_date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        prh.history_id,
        prh.entry_time,
        prh.exit_time,
        prh.identifier,
        prh.license_plate,
        prh.type,
        prh.card_id,
        prh.payment_id,
        prh.staff_in,
        si.name AS staff_in_name,
        prh.staff_out,
        so.name AS staff_out_name,
        prh.vehicle_type,
        vt.name AS vehicle_type_name
    FROM parking_record_history prh
    JOIN vehicle_type vt ON prh.vehicle_type = vt.id
    JOIN account ai ON prh.staff_in = ai.account_id
    JOIN staff si ON ai.account_id = si.account_id
    LEFT JOIN account ao ON prh.staff_out = ao.account_id
    LEFT JOIN staff so ON ao.account_id = so.account_id
    WHERE (@start_date IS NULL OR prh.entry_time >= @start_date)
      AND (@end_date IS NULL OR prh.entry_time <= @end_date)
    ORDER BY prh.entry_time DESC;
END;
GO

-- Stored procedure to get monthly registration history (active and expired)
IF OBJECT_ID('dbo.sp_get_monthly_registration_history', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_get_monthly_registration_history;
GO
CREATE PROCEDURE sp_get_monthly_registration_history
    @status VARCHAR(10) = 'ALL' -- ALL, ACTIVE, EXPIRED
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Validate status parameter
        IF @status NOT IN ('ALL', 'ACTIVE', 'EXPIRED')
            THROW 50023, 'Invalid status. Must be ALL, ACTIVE, or EXPIRED.', 1;

        -- Query for active registrations
        DECLARE @active_registrations TABLE (
            id VARCHAR(36),
            expiration_date DATETIME2(6),
            issue_date DATETIME2(6),
            create_by VARCHAR(36),
            creator_name VARCHAR(100),
            customer_id VARCHAR(36),
            customer_name VARCHAR(100),
            payment_id VARCHAR(36),
            vehicle_id VARCHAR(36),
            license_plate VARCHAR(20),
            status VARCHAR(10)
        );

        INSERT INTO @active_registrations
        SELECT 
            amr.id,
            amr.expiration_date,
            amr.issue_date,
            amr.create_by,
            s.name AS creator_name,
            amr.customer_id,
            c.name AS customer_name,
            amr.payment_id,
            amr.vehicle_id,
            v.license_plate,
            'Active' AS status
        FROM active_monthly_registration amr
        JOIN customer c ON amr.customer_id = c.customer_id
        JOIN vehicle v ON amr.vehicle_id = v.vehicle_id
        JOIN account a ON amr.create_by = a.account_id
        JOIN staff s ON a.account_id = s.account_id;

        -- Query for expired registrations
        DECLARE @expired_registrations TABLE (
            id VARCHAR(36),
            expiration_date DATETIME2(6),
            issue_date DATETIME2(6),
            create_by VARCHAR(36),
            creator_name VARCHAR(100),
            customer_id VARCHAR(36),
            customer_name VARCHAR(100),
            payment_id VARCHAR(36),
            vehicle_id VARCHAR(36),
            license_plate VARCHAR(20),
            status VARCHAR(10)
        );

        INSERT INTO @expired_registrations
        SELECT 
            emr.id,
            emr.expiration_date,
            emr.issue_date,
            emr.create_by,
            s.name AS creator_name,
            emr.customer_id,
            c.name AS customer_name,
            emr.payment_id,
            emr.vehicle_id,
            v.license_plate,
            'Expired' AS status
        FROM expire_monthly_registration emr
        JOIN customer c ON emr.customer_id = c.customer_id
        JOIN vehicle v ON emr.vehicle_id = v.vehicle_id
        JOIN account a ON emr.create_by = a.account_id
        JOIN staff s ON a.account_id = s.account_id;

        -- Combine results based on status
        IF @status = 'ALL'
            SELECT * FROM @active_registrations
            UNION ALL
            SELECT * FROM @expired_registrations
            ORDER BY issue_date DESC;
        ELSE IF @status = 'ACTIVE'
            SELECT * FROM @active_registrations
            ORDER BY issue_date DESC;
        ELSE IF @status = 'EXPIRED'
            SELECT * FROM @expired_registrations
            ORDER BY issue_date DESC;
    END TRY
    BEGIN CATCH
        PRINT 'Error in sp_get_monthly_registration_history: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
GO

-- Stored procedure to get missing report history
IF OBJECT_ID('dbo.sp_get_missing_report_history', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_get_missing_report_history;
GO
CREATE PROCEDURE dbo.sp_get_missing_report_history
    @start_date DATE = NULL,
    @end_date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        mr.report_id,
        mr.create_at,
        mr.name,
        mr.gender,
        mr.identification,
        mr.phone_number,
        mr.address,
        mr.brand,
        mr.color,
        mr.license_plate,
        mr.identifier,
        mr.vehicle_type,
        vt.name AS vehicle_type_name,
        mr.create_by,
        s.name AS creator_name,
        mr.payment_id,
        mr.record_id
    FROM dbo.missing_report mr
    JOIN dbo.vehicle_type vt ON mr.vehicle_type = vt.id
    JOIN dbo.account a ON mr.create_by = a.account_id
    JOIN dbo.staff s ON a.account_id = s.account_id
    WHERE (@start_date IS NULL OR mr.create_at >= @start_date)
      AND (@end_date IS NULL OR mr.create_at <= @end_date)
    ORDER BY mr.create_at DESC;
END;
GO

IF OBJECT_ID('dbo.sp_get_payment_history', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_get_payment_history;
GO
CREATE PROCEDURE dbo.sp_get_payment_history
    @start_date DATE = NULL,
    @end_date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        p.payment_id,
        p.amount,
        p.create_at,
        p.payment_type
    FROM dbo.payment p
    WHERE (@start_date IS NULL OR p.create_at >= @start_date)
      AND (@end_date IS NULL OR p.create_at <= @end_date)
    ORDER BY p.create_at DESC;
END;
GO

-- Statistics for Admin
IF OBJECT_ID('dbo.sp_get_revenue_stats', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_get_revenue_stats;
GO
CREATE PROCEDURE dbo.sp_get_revenue_stats
    @start_date DATE,
    @end_date DATE
AS
BEGIN
    SELECT 
        payment_type,
        COUNT(*) AS payment_count,
        SUM(amount) AS total_revenue
    FROM payment
    WHERE create_at BETWEEN @start_date AND @end_date
    GROUP BY payment_type;
END;
GO

IF OBJECT_ID('dbo.sp_get_parking_stats', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_get_parking_stats;
GO
CREATE PROCEDURE dbo.sp_get_parking_stats
    @start_date DATE,
    @end_date DATE
AS
BEGIN
    SELECT 
        vehicle_type,
        COUNT(*) AS total_parkings,
        SUM(CASE WHEN type = 'MONTHLY' THEN 1 ELSE 0 END) AS monthly_parkings,
        SUM(CASE WHEN type = 'DAILY' THEN 1 ELSE 0 END) AS daily_parkings
    FROM parking_record_history
    WHERE entry_time BETWEEN @start_date AND @end_date
    GROUP BY vehicle_type;
END;
GO

-- **STAFF**
-- Parking Management
-- Stored procedure to create parking record with vehicle type constraints
IF OBJECT_ID('dbo.sp_create_parking_record', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_create_parking_record;
GO
CREATE PROCEDURE dbo.sp_create_parking_record
    @record_id VARCHAR(36),
    @license_plate VARCHAR(20) = NULL,
    @identifier VARCHAR(50) = NULL,
    @card_id INT,
    @staff_in VARCHAR(36),
    @vehicle_type VARCHAR(36)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate inputs
        IF NOT EXISTS (SELECT 1 FROM dbo.parking_card WHERE card_id = @card_id)
            THROW 50011, 'Invalid card_id.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.vehicle_type WHERE id = @vehicle_type)
            THROW 50012, 'Invalid vehicle_type.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.account WHERE account_id = @staff_in)
            THROW 50013, 'Invalid staff_in.', 1;

        -- Check if card is already in use (trigger will also enforce this)
        IF EXISTS (SELECT 1 FROM dbo.parking_record WHERE card_id = @card_id)
            THROW 50014, 'Card is already in use.', 1;

        -- Validate license_plate and identifier based on vehicle_type
        DECLARE @vehicle_type_name VARCHAR(50);
        SELECT @vehicle_type_name = name FROM dbo.vehicle_type WHERE id = @vehicle_type;

        IF @vehicle_type_name = 'Bicycle'
        BEGIN
            IF @license_plate IS NOT NULL
                THROW 50015, 'license_plate must be NULL for Bicycle.', 1;
            IF @identifier IS NULL
                THROW 50016, 'identifier cannot be NULL for Bicycle.', 1;
        END
        ELSE IF @vehicle_type_name IN ('Motorbike', 'Scooter')
        BEGIN
            IF @identifier IS NOT NULL
                THROW 50017, 'identifier must be NULL for Motorbike or Scooter.', 1;
            IF @license_plate IS NULL
                THROW 50018, 'license_plate cannot be NULL for Motorbike or Scooter.', 1;
        END;

        -- Determine type (MONTHLY or DAILY)
        DECLARE @type VARCHAR(10) = 'DAILY';
        IF EXISTS (
            SELECT 1
            FROM dbo.active_monthly_registration amr
            JOIN dbo.vehicle v ON amr.vehicle_id = v.vehicle_id
            WHERE (v.license_plate = @license_plate OR v.vehicle_id = @identifier)
              AND amr.expiration_date >= GETDATE()
        )
            SET @type = 'MONTHLY';

        INSERT INTO dbo.parking_record (
            record_id, entry_time, license_plate, identifier, type,
            card_id, staff_in, vehicle_type
        )
        VALUES (
            @record_id, GETDATE(), @license_plate, @identifier, @type,
            @card_id, @staff_in, @vehicle_type
        );

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        PRINT 'Error in sp_create_parking_record: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
GO

-- Stored procedure to process vehicle exit with updated fee calculation
IF OBJECT_ID('dbo.sp_process_vehicle_exit', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_process_vehicle_exit;
GO
CREATE PROCEDURE dbo.sp_process_vehicle_exit
    @license_plate VARCHAR(20) = NULL,
    @identifier VARCHAR(50) = NULL,
    @card_id INT,
    @staff_out VARCHAR(36),
    @history_id VARCHAR(36),
    @payment_id VARCHAR(36) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Find parking record with strict matching
        DECLARE @record_id VARCHAR(36), @entry_time DATETIME2(6), @type VARCHAR(10), @vehicle_type VARCHAR(36);
        DECLARE @vehicle_type_name VARCHAR(50);

        -- Try to find the parking record
        SELECT 
            @record_id = pr.record_id, 
            @entry_time = pr.entry_time, 
            @type = pr.type, 
            @vehicle_type = pr.vehicle_type,
            @vehicle_type_name = vt.name
        FROM dbo.parking_record pr
        JOIN dbo.vehicle_type vt ON pr.vehicle_type = vt.id
        WHERE pr.card_id = @card_id
          AND (
              (vt.name = 'Bicycle' AND pr.identifier = @identifier AND pr.license_plate IS NULL AND @license_plate IS NULL)
              OR 
              (vt.name IN ('Motorbike', 'Scooter') AND pr.license_plate = @license_plate AND pr.identifier IS NULL AND @identifier IS NULL)
          );

        IF @record_id IS NULL
            THROW 50015, 'No matching parking record found. Ensure card_id matches the correct license_plate or identifier for the vehicle type.', 1;

        -- Validate staff_out
        IF NOT EXISTS (SELECT 1 FROM dbo.account WHERE account_id = @staff_out)
            THROW 50016, 'Invalid staff_out.', 1;

        -- Calculate fee for DAILY type
        IF @type = 'DAILY' AND @payment_id IS NOT NULL
        BEGIN
            DECLARE @amount INT, @day_price INT, @night_price INT;
            SELECT @day_price = day_price, @night_price = night_price
            FROM dbo.price
            WHERE type_id = @vehicle_type;

            -- Determine if entry_time is in day (6:00 AM - 6:00 PM) or night (6:00 PM - 6:00 AM)
            DECLARE @hour_of_entry INT = DATEPART(HOUR, @entry_time);
            DECLARE @price INT = 
                CASE 
                    WHEN @hour_of_entry BETWEEN 6 AND 17 THEN @day_price
                    ELSE @night_price
                END;

            -- Calculate number of days (minimum 1 day)
            DECLARE @days INT = DATEDIFF(DAY, @entry_time, GETDATE());
            SET @days = CASE WHEN @days < 1 THEN 1 ELSE @days END;

            -- Calculate total amount
            SET @amount = @price * @days;

            INSERT INTO dbo.payment (payment_id, amount, create_at, payment_type)
            VALUES (@payment_id, @amount, GETDATE(), 'PARKING');
        END

        -- Move to parking_record_history
        INSERT INTO dbo.parking_record_history (
            history_id, entry_time, exit_time, identifier, license_plate, type,
            card_id, payment_id, staff_in, staff_out, vehicle_type
        )
        SELECT 
            @history_id, entry_time, GETDATE(), identifier, license_plate, type,
            card_id, @payment_id, staff_in, @staff_out, vehicle_type
        FROM dbo.parking_record
        WHERE record_id = @record_id;

        -- Delete from parking_record
        DELETE FROM dbo.parking_record WHERE record_id = @record_id;

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        PRINT 'Error in sp_process_vehicle_exit: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
GO

-- Stored procedure to create monthly registration(active) with vehicle and customer information
IF OBJECT_ID('dbo.sp_create_active_monthly_registration', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_create_active_monthly_registration;
GO
CREATE PROCEDURE dbo.sp_create_active_monthly_registration
    @id VARCHAR(36),
    @expiration_date DATETIME2(6),
    @issue_date DATETIME2(6),
    @create_by VARCHAR(36),
    @payment_id VARCHAR(36),
    -- Vehicle information
    @brand VARCHAR(50),
    @color VARCHAR(50),
    @license_plate VARCHAR(20) = NULL,
    @type_id VARCHAR(36),
    -- Customer information
    @name VARCHAR(100),
    @gender VARCHAR(10),
    @dob DATE,
    @email VARCHAR(100),
    @phone_number VARCHAR(15),
    @address VARCHAR(200),
    @customer_type VARCHAR(20), -- LECTURER or STUDENT
    -- Lecturer-specific information
    @lecturer_id VARCHAR(36) = NULL,
    -- Student-specific information
    @student_id VARCHAR(36) = NULL,
	@class_info VARCHAR(50) = NULL,
    @faculty VARCHAR(100) = NULL,
	@major VARCHAR(100) = NULL

AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate inputs
        IF NOT EXISTS (SELECT 1 FROM dbo.account WHERE account_id = @create_by)
            THROW 50016, 'Invalid create_by.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.vehicle_type WHERE id = @type_id)
            THROW 50019, 'Invalid vehicle_type.', 1;
        IF @customer_type NOT IN ('LECTURER', 'STUDENT')
            THROW 50020, 'Invalid customer_type. Must be LECTURER or STUDENT.', 1;
        IF @gender NOT IN ('MALE', 'FEMALE')
            THROW 50021, 'Invalid gender. Must be MALE or FEMALE.', 1;

        -- Validate lecturer/student information
        IF @customer_type = 'STUDENT' AND (@student_id IS NULL OR @faculty IS NULL)
            THROW 50023, 'student_id and faculty are required for STUDENT.', 1;

        -- Generate IDs
        DECLARE @vehicle_id VARCHAR(36) = NEWID();
        DECLARE @customer_id VARCHAR(36) = NEWID();

        -- Insert vehicle
        INSERT INTO dbo.vehicle (vehicle_id, brand, color, license_plate, type_id)
        VALUES (@vehicle_id, @brand, @color, @license_plate, @type_id);

        -- Insert customer
        INSERT INTO dbo.customer (customer_id, name, gender, dob, email, phone_number, address, customer_type)
        VALUES (@customer_id, @name, @gender, @dob, @email, @phone_number, @address, @customer_type);

        -- Insert lecturer or student information
        IF @customer_type = 'LECTURER'
        BEGIN
            INSERT INTO dbo.lecturer_information (customer_id, lecturer_id)
            VALUES (@customer_id, @lecturer_id);
        END
        ELSE IF @customer_type = 'STUDENT'
        BEGIN
            INSERT INTO dbo.student_information (customer_id, student_id, class_info, faculty, major)
            VALUES (@customer_id, @student_id, @class_info, @faculty, @major);
        END;

        -- Calculate monthly fee
        DECLARE @monthly_price INT;
        SELECT @monthly_price = monthly_price
        FROM dbo.price
        WHERE type_id = @type_id;

        IF @monthly_price IS NULL
            THROW 50024, 'No monthly price found for the vehicle type.', 1;

        -- Create payment
        INSERT INTO dbo.payment (payment_id, amount, create_at, payment_type)
        VALUES (@payment_id, @monthly_price, GETDATE(), 'MONTHLY');

        -- Insert registration
        INSERT INTO dbo.active_monthly_registration (
            id, expiration_date, issue_date, create_by,
            customer_id, payment_id, vehicle_id
        )
        VALUES (
            @id, @expiration_date, @issue_date, @create_by,
            @customer_id, @payment_id, @vehicle_id
        );

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        PRINT 'Error in sp_create_active_monthly_registration: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
GO

-- Stored procedured get active monthly registration
IF OBJECT_ID('dbo.sp_get_active_monthly_registration', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_get_active_monthly_registration;
GO
CREATE PROCEDURE dbo.sp_get_active_monthly_registration
    @id VARCHAR(36) = NULL
AS
BEGIN
    IF @id IS NULL
        SELECT * FROM active_monthly_registration;
    ELSE
        SELECT * FROM active_monthly_registration WHERE id = @id;
END;
GO

IF OBJECT_ID('dbo.sp_check_expired_monthly_registrations', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_check_expired_monthly_registrations;
GO
CREATE PROCEDURE dbo.sp_check_expired_monthly_registrations
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO expire_monthly_registration (
            id, expiration_date, issue_date, create_by, customer_id, payment_id, vehicle_id
        )
        SELECT id, expiration_date, issue_date, create_by, customer_id, payment_id, vehicle_id
        FROM active_monthly_registration
        WHERE expiration_date < GETDATE();

        DELETE FROM active_monthly_registration
        WHERE expiration_date < GETDATE();

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        PRINT 'Error in sp_check_expired_monthly_registrations: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
GO

-- Stored procedure create Missing Report
IF OBJECT_ID('dbo.sp_create_missing_report', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_create_missing_report;
GO
CREATE PROCEDURE dbo.sp_create_missing_report
    @report_id VARCHAR(36),
    @address VARCHAR(200),
    @brand VARCHAR(50),
    @color VARCHAR(30),
    @create_at DATETIME2(6),
    @gender VARCHAR(10),
    @identification VARCHAR(30),
    @identifier VARCHAR(20) = NULL,
    @license_plate VARCHAR(20) = NULL,
    @name VARCHAR(100),
    @phone_number VARCHAR(15),
    @create_by VARCHAR(36),
    @payment_id VARCHAR(36),
    @record_id VARCHAR(36) = NULL,
    @vehicle_type VARCHAR(36),
    @missing_fee INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate inputs
        IF NOT EXISTS (SELECT 1 FROM account WHERE account_id = @create_by)
            THROW 50020, 'Invalid create_by.', 1;
        IF NOT EXISTS (SELECT 1 FROM vehicle_type WHERE id = @vehicle_type)
            THROW 50021, 'Invalid vehicle_type.', 1;
        IF @record_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM parking_record WHERE record_id = @record_id)
            THROW 50022, 'Invalid record_id.', 1;
        IF @gender NOT IN ('MALE', 'FEMALE')
            THROW 50023, 'Invalid gender. Must be MALE or FEMALE.', 1;
        IF @missing_fee < 0
            THROW 50024, 'Missing fee cannot be negative.', 1;

        -- Declare variable to store history_id
        DECLARE @history_id VARCHAR(36) = NULL;

		-- Create payment for missing fee
        INSERT INTO payment (payment_id, amount, create_at, payment_type)
        VALUES (@payment_id, @missing_fee, @create_at, 'MISSING');

        -- Move parking record to history if record_id is provided
        IF @record_id IS NOT NULL
        BEGIN
            SET @history_id = NEWID();
            INSERT INTO parking_record_history (
                history_id, entry_time, exit_time, identifier, license_plate, type,
                card_id, payment_id, staff_in, staff_out, vehicle_type
            )
            SELECT 
                @history_id, entry_time, GETDATE(), identifier, license_plate, type,
                card_id, @payment_id, staff_in, @create_by, vehicle_type
            FROM parking_record
            WHERE record_id = @record_id;

            DELETE FROM parking_record WHERE record_id = @record_id;
        END

        -- Insert missing report (use history_id as record_id)
        INSERT INTO missing_report (
            report_id, address, brand, color, create_at, gender,
            identification, identifier, license_plate, name,
            phone_number, create_by, payment_id, record_id, vehicle_type
        )
        VALUES (
            @report_id, @address, @brand, @color, @create_at, @gender,
            @identification, @identifier, @license_plate, @name,
            @phone_number, @create_by, @payment_id, @history_id, @vehicle_type
        );

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        PRINT 'Error in sp_create_missing_report: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
GO

-- Step 10: Grant permissions to roles
GRANT EXECUTE ON dbo.sp_create_parking_record TO ROLE_STAFF;
GRANT EXECUTE ON dbo.sp_process_vehicle_exit TO ROLE_STAFF;
GRANT EXECUTE ON dbo.sp_create_active_monthly_registration TO ROLE_STAFF;
GRANT EXECUTE ON dbo.sp_create_missing_report TO ROLE_STAFF;
GRANT EXECUTE ON dbo.sp_get_active_monthly_registration TO ROLE_STAFF;
GRANT EXECUTE ON dbo.sp_check_expired_monthly_registrations TO ROLE_STAFF;

GRANT EXECUTE ON dbo.sp_create_staff_account TO ROLE_ADMIN;
GRANT EXECUTE ON dbo.sp_update_staff TO ROLE_ADMIN;
GRANT EXECUTE ON dbo.sp_toggle_staff_status TO ROLE_ADMIN;
GRANT EXECUTE ON dbo.sp_get_all_staff TO ROLE_ADMIN;
GRANT EXECUTE ON dbo.sp_get_staff TO ROLE_ADMIN;
GRANT EXECUTE ON dbo.sp_get_price_by_vehicle_type TO ROLE_ADMIN;
GRANT EXECUTE ON dbo.sp_update_price_by_vehicle_type TO ROLE_ADMIN;
GRANT EXECUTE ON dbo.sp_get_parking_record_history TO ROLE_ADMIN;
GRANT EXECUTE ON dbo.sp_get_monthly_registration_history TO ROLE_ADMIN;
GRANT EXECUTE ON dbo.sp_get_missing_report_history TO ROLE_ADMIN;
GRANT EXECUTE ON dbo.sp_get_payment_history TO ROLE_ADMIN;
GRANT EXECUTE ON dbo.sp_get_revenue_stats TO ROLE_ADMIN;
GRANT EXECUTE ON dbo.sp_get_parking_stats TO ROLE_ADMIN;
GO

-- Step 11: Create schedule job for expired monthly registrations
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'CheckExpiredMonthlyRegistrations')
BEGIN TRY
    EXEC msdb.dbo.sp_add_job
        @job_name = N'CheckExpiredMonthlyRegistrations';
    EXEC msdb.dbo.sp_add_jobstep
        @job_name = N'CheckExpiredMonthlyRegistrations',
        @step_name = N'RunCheck',
        @subsystem = N'TSQL',
        @command = N'EXEC sp_check_expired_monthly_registrations';
    EXEC msdb.dbo.sp_add_jobschedule
        @job_name = N'CheckExpiredMonthlyRegistrations',
        @name = N'DailySchedule',
        @freq_type = 4, -- Daily
        @freq_interval = 1,
        @active_start_time = 000000; -- 00:00
    EXEC msdb.dbo.sp_add_jobserver
        @job_name = N'CheckExpiredMonthlyRegistrations';
END TRY
BEGIN CATCH
    PRINT 'Error creating schedule job: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO

-- Step 12: Set database to read-write
ALTER DATABASE [parking_management] SET READ_WRITE;
GO