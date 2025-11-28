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




-- Drop if exists
DROP TABLE IF EXISTS FactRevenue;

-- Create FactRevenue
CREATE TABLE FactRevenue (
    RevenueID INT IDENTITY(1,1) PRIMARY KEY,
    DateID INT NOT NULL,
    RouteID INT NOT NULL,
    StopID INT NOT NULL,
    FareTypeID INT NOT NULL,
    VehicleID INT NOT NULL,
    BoardingCount INT NOT NULL,
    FareAmount DECIMAL(6,2) NOT NULL,
    TotalRevenue AS (BoardingCount * FareAmount) PERSISTED
);

-- Create dimFarePrice table to reference fare prices
DROP TABLE IF EXISTS dimFarePrice;
CREATE TABLE dimFarePrice (
    FareTypeID INT PRIMARY KEY,
    BaseFare DECIMAL(5,2),
    MonthlyPassRate DECIMAL(6,2) NULL,
    DiscountRate DECIMAL(4,2) NULL
);

INSERT INTO dimFarePrice VALUES
(1, 3.50, NULL, NULL),   -- Adult
(2, 2.25, NULL, NULL),   -- Youth
(3, 2.00, NULL, NULL),   -- Senior
(4, 6.50, NULL, NULL),   -- DayPass
(5, 95.00, 95.00, NULL),  -- MonthlyPass
(6, 1.75, NULL, 0.50);   -- LowIncome


-- Populate FactRevenue using FactRidership
INSERT INTO FactRevenue (DateID, RouteID, StopID, FareTypeID, VehicleID, BoardingCount, FareAmount)
SELECT 
    r.DateID,
    r.RouteID,
    r.StopID,
    r.FareTypeID,
    r.VehicleID,
    r.BoardingCount,
    CASE
        WHEN fp.FareTypeID = 5 THEN ISNULL(fp.MonthlyPassRate, 95.00) / 40  -- default 95 if NULL
        WHEN fp.DiscountRate IS NOT NULL THEN fp.BaseFare * fp.DiscountRate
        ELSE fp.BaseFare
    END AS FareAmount
FROM FactRidership r
JOIN dimFarePrice fp ON r.FareTypeID = fp.FareTypeID;


--UPDATE dimFarePrice
--SET MonthlyPassRate = 95.00
--WHERE FareTypeID = 5;
