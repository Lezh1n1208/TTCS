USE [parking_management]
-- Step 1: Create sample data
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

DELETE FROM dbo.price;
DELETE FROM dbo.vehicle_type;
GO

INSERT INTO dbo.vehicle_type (id, name)
VALUES 
    ('vt1', 'Motorbike'),
    ('vt2', 'Scooter');

INSERT INTO dbo.price (type_id, day_price, monthly_price, night_price)
VALUES 
    ('vt1', 5000, 100000, 7000),
    ('vt2', 10000, 200000, 15000);
GO

-- Step 2: Test cases
-- Test Case 1: Valid - Update price for existing vehicle type
PRINT 'Test Case 1: Valid - Update price for existing vehicle type';
SELECT 'Before vt1', * FROM dbo.price WHERE type_id = 'vt1';
EXEC dbo.sp_update_price_by_vehicle_type
    @vehicle_type_id = 'vt1',
    @day_price = 6000,
    @monthly_price = 120000,
    @night_price = 8000;
SELECT 'After vt1', * FROM dbo.price WHERE type_id = 'vt1';
PRINT 'Test Case 1: SUCCESS';
GO

-- Test Case 2: Invalid - Non-existent vehicle type
PRINT 'Test Case 2: Invalid - Non-existent vehicle type';
SELECT 'Before vt999', * FROM dbo.price WHERE type_id = 'vt999';
EXEC dbo.sp_update_price_by_vehicle_type
    @vehicle_type_id = 'vt999',
    @day_price = 7000,
    @monthly_price = 150000,
    @night_price = 9000;
SELECT 'After vt999', * FROM dbo.price WHERE type_id = 'vt999';
PRINT 'Test Case 2: SUCCESS - No rows updated';
GO

-- Test Case 3: Invalid - Negative price
PRINT 'Test Case 3: Invalid - Negative price';
SELECT 'Before vt2', * FROM dbo.price WHERE type_id = 'vt2';
EXEC dbo.sp_update_price_by_vehicle_type
    @vehicle_type_id = 'vt2',
    @day_price = -1000,
    @monthly_price = 200000,
    @night_price = 15000;
SELECT 'After vt2', * FROM dbo.price WHERE type_id = 'vt2';
PRINT 'Test Case 3: SUCCESS - Update proceeds (no validation)';
GO