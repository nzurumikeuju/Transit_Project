-- ============================================
-- 1? Create Database
-- ============================================
CREATE DATABASE TransitDW;
GO

USE TransitDW;
GO

-- ============================================
-- 2? Create dimDate
-- ============================================
DROP TABLE IF EXISTS dimDate;
CREATE TABLE dimDate (
    DateID INT PRIMARY KEY,          -- YYYYMMDD format
    FullDate DATE NOT NULL,
    Day INT,
    Month INT,
    Quarter INT,
    Year INT,
    Weekday VARCHAR(10),
    IsWeekend BIT
);

-- Populate dimDate for 3 years (2024-2026)
WITH DateSeries AS (
    SELECT CAST('2024-01-01' AS DATE) AS dt
    UNION ALL
    SELECT DATEADD(DAY, 1, dt)
    FROM DateSeries
    WHERE dt < '2026-12-31'
)
INSERT INTO dimDate (DateID, FullDate, Day, Month, Quarter, Year, Weekday, IsWeekend)
SELECT 
    CAST(FORMAT(dt,'yyyyMMdd') AS INT) AS DateID,
    dt AS FullDate,
    DAY(dt) AS Day,
    MONTH(dt) AS Month,
    DATEPART(QUARTER, dt) AS Quarter,
    YEAR(dt) AS Year,
    DATENAME(WEEKDAY, dt) AS Weekday,
    CASE WHEN DATENAME(WEEKDAY, dt) IN ('Saturday','Sunday') THEN 1 ELSE 0 END AS IsWeekend
FROM DateSeries
OPTION (MAXRECURSION 0);

-- ============================================
-- 3? Create dimRoute
-- ============================================
DROP TABLE IF EXISTS dimRoute;
CREATE TABLE dimRoute (
    RouteID INT IDENTITY(1,1) PRIMARY KEY,
    RouteName VARCHAR(50),
    RouteType VARCHAR(20)  -- e.g., Bus, LRT, Shuttle
);

-- Sample routes
INSERT INTO dimRoute (RouteName, RouteType) VALUES
('Downtown Express', 'Bus'),
('University Connector', 'Bus'),
('Airport Shuttle', 'Shuttle'),
('City Centre LRT', 'LRT'),
('Stadium Line', 'LRT'),
('Hospital Link', 'Bus'),
('North Suburban', 'Bus'),
('South Circular', 'Bus'),
('East LRT', 'LRT'),
('West Bus Rapid', 'Bus');

-- ============================================
-- 4? Create dimStop
-- ============================================
DROP TABLE IF EXISTS dimStop;
CREATE TABLE dimStop (
    StopID INT IDENTITY(1,1) PRIMARY KEY,
    StopName VARCHAR(100),
    Zone VARCHAR(20)
);

-- Sample stops
INSERT INTO dimStop (StopName, Zone) VALUES
('Downtown Station','A'),
('City Centre','A'),
('University','B'),
('Hospital','B'),
('Airport Terminal','C'),
('Stadium','C'),
('North Park','B'),
('South Mall','B'),
('East End','C'),
('West Side','C');

-- ============================================
-- 5? Create dimFareType
-- ============================================
DROP TABLE IF EXISTS dimFareType;
CREATE TABLE dimFareType (
    FareTypeID INT IDENTITY(1,1) PRIMARY KEY,
    FareType VARCHAR(50)
);

INSERT INTO dimFareType (FareType) VALUES
('Adult'),
('Youth'),
('Senior'),
('DayPass'),
('MonthlyPass'),
('LowIncome');

-- ============================================
-- 6? Create dimVehicle
-- ============================================
DROP TABLE IF EXISTS dimVehicle;
CREATE TABLE dimVehicle (
    VehicleID INT IDENTITY(1,1) PRIMARY KEY,
    FleetNumber VARCHAR(10),
    VehicleType VARCHAR(20)
);

INSERT INTO dimVehicle (FleetNumber, VehicleType) VALUES
('B101','Bus'),
('B102','Bus'),
('B103','Bus'),
('B104','Bus'),
('L201','LRT'),
('L202','LRT'),
('S301','Shuttle'),
('S302','Shuttle');

-- ============================================
-- 7? Optional: Check the data
-- ============================================
SELECT COUNT(*) AS TotalDates FROM dimDate;
SELECT TOP 10 * FROM dimDate;

SELECT COUNT(*) AS TotalRoutes FROM dimRoute;
SELECT TOP 10 * FROM dimRoute;

SELECT COUNT(*) AS TotalStops FROM dimStop;
SELECT TOP 10 * FROM dimStop;

SELECT COUNT(*) AS TotalFareTypes FROM dimFareType;
SELECT TOP 10 * FROM dimFareType;

SELECT COUNT(*) AS TotalVehicles FROM dimVehicle;
SELECT TOP 10 * FROM dimVehicle;


-- Drop if exists
DROP TABLE IF EXISTS FactRidership;

-- Create FactRidership
CREATE TABLE FactRidership (
    FactID INT IDENTITY(1,1) PRIMARY KEY,
    DateID INT NOT NULL,
    RouteID INT NOT NULL,
    StopID INT NOT NULL,
    FareTypeID INT NOT NULL,
    VehicleID INT NOT NULL,
    BoardingCount INT NOT NULL
);

-- Populate FactRidership (synthetic data)
INSERT INTO FactRidership (DateID, RouteID, StopID, FareTypeID, VehicleID, BoardingCount)
SELECT 
    d.DateID,
    r.RouteID,
    s.StopID,
    f.FareTypeID,
    v.VehicleID,
    -- Boarding logic based on stop popularity
    CASE
        WHEN s.StopName IN ('Downtown Station','City Centre') THEN ABS(CHECKSUM(NEWID())) % 200 + 300
        WHEN s.StopName IN ('University','Hospital') THEN ABS(CHECKSUM(NEWID())) % 150 + 200
        ELSE ABS(CHECKSUM(NEWID())) % 80 + 50
    END AS BoardingCount
FROM dimDate d
CROSS JOIN dimRoute r
CROSS JOIN dimStop s
CROSS JOIN dimFareType f
CROSS JOIN dimVehicle v;
