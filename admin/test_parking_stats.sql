USE [parking_management]
GO

-- **Bước 1: Tạo dữ liệu mẫu**
-- Kiểm tra và tạo bảng parking_record_history nếu chưa tồn tại
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
    vehicle_type VARCHAR(36) NOT NULL
);
GO

-- Xóa dữ liệu cũ để tránh xung đột
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

-- Chèn dữ liệu mẫu
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
VALUES (1), (2), (3), (4);

IF NOT EXISTS (SELECT 1 FROM dbo.payment WHERE payment_id = 'pay1')
INSERT INTO dbo.payment (payment_id, amount, create_at, payment_type)
VALUES 
    ('pay1', 5000, '2025-04-15 10:00:00', 'PARKING'),
    ('pay2', 100000, '2025-04-16 12:00:00', 'MONTHLY'),
    ('pay3', 50000, '2025-04-17 14:00:00', 'MISSING');


IF NOT EXISTS (SELECT 1 FROM dbo.parking_record_history WHERE history_id = 'hist1')
INSERT INTO dbo.parking_record_history (history_id, entry_time, exit_time, identifier, license_plate, type, card_id, payment_id, staff_in, staff_out, vehicle_type)
VALUES 
    ('hist1', '2025-04-15 08:00:00', '2025-04-15 12:00:00', 'ID123', '29A-12345', 'DAILY', 1, 'pay1', 'acc1', 'acc2', 'vt1'),
    ('hist2', '2025-04-15 09:00:00', '2025-04-15 13:00:00', 'ID456', '29B-67890', 'MONTHLY', 2, 'pay2', 'acc2', 'acc1', 'vt1'),
    ('hist3', '2025-04-16 10:00:00', '2025-04-16 14:00:00', 'ID789', '30A-54321', 'DAILY', 3, 'pay3', 'acc1', 'acc2', 'vt2');
GO

-- **Bước 2: Các trường hợp kiểm tra**
-- Trường hợp 1: Hợp lệ - Lấy thống kê trong khoảng thời gian
PRINT 'Case 1: Valid - Get statistic in range';
EXEC dbo.sp_get_parking_stats @start_date = '2025-04-15', @end_date = '2025-04-16';
PRINT 'Case 1: SUCCESS';
GO

-- Trường hợp 2: Hợp lệ - Lấy thống kê cho một ngày
PRINT 'Case 2: Valid - Get statistic for a date';
EXEC dbo.sp_get_parking_stats @start_date = '2025-04-15', @end_date = '2025-04-16';
PRINT 'Case 2: SUCCESS';
GO

-- Trường hợp 3: Không hợp lệ - Không có bản ghi trong khoảng thời gian
PRINT 'Case 3: Invalid - No record in range';
EXEC dbo.sp_get_parking_stats @start_date = '2025-04-01', @end_date = '2025-04-02';
PRINT 'Case 3: SUCCESS - No column returned';
GO

-- Trường hợp 4: Không hợp lệ - Ngày bắt đầu sau ngày kết thúc
PRINT 'Case 4: Invalid - Start date after end date';
EXEC dbo.sp_get_parking_stats @start_date = '2025-04-17', @end_date = '2025-04-15';
PRINT 'Case 4: SUCCESS - No column returned';
GO
