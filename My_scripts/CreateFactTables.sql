--Task 2: Aggregate and Explore
--Use the following queries to understand the data:

-- Total boardings by fare type
SELECT FareTypeID, SUM(BoardingCount) AS TotalBoardings
FROM FactRidership 
GROUP BY FareTypeID
ORDER BY FareTypeID;

-- Total revenue by route
SELECT r.RouteName, SUM(fr.TotalRevenue) AS TotalRevenue
FROM FactRevenue AS fr
JOIN dimRoute AS r ON fr.RouteID = r.RouteID
GROUP BY r.RouteName
ORDER BY TotalRevenue DESC

-- Total revenue by route
SELECT RouteName, SUM(TotalRevenue) AS TotalRevenue
FROM FactRevenue AS r
INNER JOIN dimRoute AS rn ON r.RouteID = rn.RouteID
GROUP BY RouteName
ORDER BY TotalRevenue DESC


-- Boardings by route
SELECT rt.RouteName, SUM(r.BoardingCount) AS TotalBoardings
FROM FactRevenue AS r
LEFT JOIN dimRoute rt ON r.RouteID = rt.RouteID
GROUP BY rt.RouteName
ORDER BY TotalBoardings DESC