--- Create a new Schema
CREATE SCHEMA vw AUTHORIZATION dbo;

CREATE OR ALTER VIEW vw.FactUnified AS
SELECT 
    r.FactID,
    r.DateID,
    r.RouteID,
    r.StopID,
    r.FareTypeID,
    r.VehicleID,
    r.BoardingCount,
    fr.FareAmount,
    fr.TotalRevenue
FROM FactRidership r
JOIN FactRevenue fr
    ON r.DateID = fr.DateID
   AND r.RouteID = fr.RouteID
   AND r.StopID = fr.StopID
   AND r.FareTypeID = fr.FareTypeID
   AND r.VehicleID = fr.VehicleID;
