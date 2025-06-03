-- Step 1: Tạo dữ liệu mẫu
-- Thêm dữ liệu vào bảng account
DELETE FROM dbo.parking_record_history;
DELETE FROM dbo.staff;
DELETE FROM DBO.account;

INSERT INTO dbo.account (account_id, password, role, username)
VALUES 
    ('acc1', 'Staff@Pass2023!', 'STAFF', 'staff1'),
    ('acc2', 'Staff@Pass2023!', 'STAFF', 'staff2'),
    ('acc3', 'Staff@Pass2023!', 'STAFF', 'staff3');

-- Thêm dữ liệu vào bảng staff
INSERT INTO dbo.staff (account_id, address, dob, email, gender, identification, is_active, name, phone_number)
VALUES 
    ('acc1', '123 Street', '1990-01-01', 'staff1@example.com', 'MALE', '123456789', 1, 'Staff One', '1234567890'),
    ('acc2', '456 Street', '1992-02-02', 'staff2@example.com', 'FEMALE', '987654321', 0, 'Staff Two', '0987654321');

-- Step 2: Các trường hợp kiểm tra
-- Trường hợp 1: Hợp lệ - Chuyển trạng thái từ 1 sang 0
PRINT 'Case 1: Toggle status acc1 from 1 to 0';
SELECT 'Before run', account_id, is_active FROM dbo.staff WHERE account_id = 'acc1';
EXEC dbo.sp_toggle_staff_status @account_id = 'acc1';
SELECT 'After run', account_id, is_active FROM dbo.staff WHERE account_id = 'acc1';
SELECT 'Account not change', account_id, username FROM dbo.account WHERE account_id = 'acc1';

-- Trường hợp 2: Hợp lệ - Chuyển trạng thái từ 0 sang 1
PRINT 'Case 2: Toggle status acc2 from 0 to 1';
SELECT 'Before run', account_id, is_active FROM dbo.staff WHERE account_id = 'acc2';
EXEC dbo.sp_toggle_staff_status @account_id = 'acc2';
SELECT 'After run', account_id, is_active FROM dbo.staff WHERE account_id = 'acc2';
SELECT 'Account not change', account_id, username FROM dbo.account WHERE account_id = 'acc2';

-- Trường hợp 3: Không hợp lệ - account_id không tồn tại trong staff
PRINT 'Case 3: account_id not existed (acc999)';
BEGIN TRY
    EXEC dbo.sp_toggle_staff_status @account_id = 'acc999';
END TRY
BEGIN CATCH
    PRINT 'Expected error: ' + ERROR_MESSAGE();
END CATCH;

-- Trường hợp 4: Không hợp lệ - account_id có trong account nhưng không có trong staff
PRINT 'Case 4: account_id exist in account, but not assigned to any staff (acc3)';
BEGIN TRY
    EXEC dbo.sp_toggle_staff_status @account_id = 'acc3';
END TRY
BEGIN CATCH
    PRINT 'Expected error: ' + ERROR_MESSAGE();
END CATCH;
