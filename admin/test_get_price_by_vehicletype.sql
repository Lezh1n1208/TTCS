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
    ('vt2', 'Car');

INSERT INTO dbo.price (type_id, day_price, monthly_price, night_price)
VALUES 
    ('vt1', 5000, 100000, 7000),
    ('vt2', 10000, 200000, 15000);
GO

-- Step 2: Test cases
-- Test Case 1: Valid - Get price for existing vehicle type
PRINT 'Test Case 1: Valid - Get price for existing vehicle type';
EXEC dbo.sp_get_price_by_vehicle_type @vehicle_type_id = 'vt1';
PRINT 'Test Case 1: SUCCESS';
GO

-- Test Case 2: Invalid - Non-existent vehicle type
PRINT 'Test Case 2: Invalid - Non-existent vehicle type';
EXEC dbo.sp_get_price_by_vehicle_type @vehicle_type_id = 'vt999';
PRINT 'Test Case 2: SUCCESS - No rows returned';
GO