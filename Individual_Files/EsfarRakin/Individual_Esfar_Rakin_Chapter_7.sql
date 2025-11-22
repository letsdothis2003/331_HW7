Use WideWorldImporters 

/* Article 1
A Beginner’s Guide to SQL Window Functions (With Real Examples)
Medium – TowardsDev
Author: The Code Studio
Link: https://medium.com/towardsdev/a-beginners-guide-to-sql-window-functions-with-real-examples-9e381574e40e */

-- Propositon 1: Rank customers by total spending
SELECT 
    o.CustomerID,
    SUM(ol.Quantity * ol.UnitPrice) AS TotalSpent,
    RANK() OVER (ORDER BY SUM(ol.Quantity * ol.UnitPrice) DESC) AS SpendingRank
FROM Sales.Orders o
JOIN Sales.OrderLines ol 
    ON o.OrderID = ol.OrderID
GROUP BY o.CustomerID;

-- Proposition 2: Running total of spending per customer over time
SELECT 
    o.CustomerID,
    o.OrderID,
    SUM(ol.Quantity * ol.UnitPrice) AS OrderValue,
    SUM(SUM(ol.Quantity * ol.UnitPrice)) OVER (
        PARTITION BY o.CustomerID
        ORDER BY o.OrderID
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal
FROM Sales.Orders o
JOIN Sales.OrderLines ol 
    ON o.OrderID = ol.OrderID
GROUP BY o.CustomerID, o.OrderID;

-- Propositon 3: Compare order values to previous and next orders
SELECT 
    o.CustomerID,
    o.OrderID,
    SUM(ol.Quantity * ol.UnitPrice) AS OrderValue,
    LAG(SUM(ol.Quantity * ol.UnitPrice)) 
        OVER (PARTITION BY o.CustomerID ORDER BY o.OrderID) AS PreviousOrder,
    LEAD(SUM(ol.Quantity * ol.UnitPrice)) 
        OVER (PARTITION BY o.CustomerID ORDER BY o.OrderID) AS NextOrder
FROM Sales.Orders o
JOIN Sales.OrderLines ol 
    ON o.OrderID = ol.OrderID
GROUP BY o.CustomerID, o.OrderID;

-- Proposition 4: Average order amount per customer
SELECT 
    o.CustomerID,
    o.OrderID,
    SUM(ol.Quantity * ol.UnitPrice) AS OrderValue,
    AVG(SUM(ol.Quantity * ol.UnitPrice)) OVER (
        PARTITION BY o.CustomerID
    ) AS CustomerAvgOrder
FROM Sales.Orders o
JOIN Sales.OrderLines ol 
    ON o.OrderID = ol.OrderID
GROUP BY o.CustomerID, o.OrderID;

/* Article 2

Mastering SQL: Pivoting and Unpivoting Technique(s)
Author: Moses Otu
Link: https://medium.com/@otimoses5/mastering-sql-pivoting-and-unpivoting-technique-s-e54256e8d61d */

-- Proposition 5: Pivot total yearly sales for each customer
SELECT *
FROM (
    SELECT 
        o.CustomerID,
        YEAR(o.OrderDate) AS OrderYear,
        SUM(ol.Quantity * ol.UnitPrice) AS YearlySales
    FROM Sales.Orders o
    JOIN Sales.OrderLines ol 
        ON o.OrderID = ol.OrderID
    GROUP BY o.CustomerID, YEAR(o.OrderDate)
) AS Src
PIVOT (
    SUM(YearlySales)
    FOR OrderYear IN ([2013],[2014],[2015],[2016])
) AS Pvt;



-- Propositon 6: Simple average vs total order value for each customer
SELECT
    o.CustomerID,
    SUM(ol.Quantity * ol.UnitPrice) AS TotalSpent,
    AVG(SUM(ol.Quantity * ol.UnitPrice)) 
        OVER() AS AvgOrderValueAllCustomers
FROM Sales.Orders o
JOIN Sales.OrderLines ol
    ON o.OrderID = ol.OrderID
GROUP BY o.CustomerID;

-- Proposition 7: Very simple unpivot-style example using UNION ALL
SELECT CustomerID, 2015 AS SalesYear, SUM(ol.Quantity * ol.UnitPrice) AS TotalSales
FROM Sales.Orders o
JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE YEAR(o.OrderDate) = 2015
GROUP BY CustomerID

UNION ALL

SELECT CustomerID, 2016 AS SalesYear, SUM(ol.Quantity * ol.UnitPrice) AS TotalSales
FROM Sales.Orders o
JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
WHERE YEAR(o.OrderDate) = 2016
GROUP BY CustomerID;

-- Proposition 8: Simple monthly sales totals
SELECT
    YEAR(o.OrderDate) AS OrderYear,
    MONTH(o.OrderDate) AS OrderMonth,
    SUM(ol.Quantity * ol.UnitPrice) AS MonthlySales
FROM Sales.Orders o
JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY OrderYear, OrderMonth;


-- Proposition 9: Count how many orders each customer made
SELECT 
    o.CustomerID,
    o.OrderID,
    COUNT(o.OrderID) OVER(PARTITION BY o.CustomerID) AS TotalOrdersPerCustomer
FROM Sales.Orders o;


-- Proposition 10: Top 5 most expensive stock items
WITH ItemRanks AS (
    SELECT
        StockItemID,
        StockItemName,
        UnitPrice,
        ROW_NUMBER() OVER (ORDER BY UnitPrice DESC) AS PriceRank
    FROM Warehouse.StockItems
)
SELECT StockItemID, StockItemName, UnitPrice, PriceRank
FROM ItemRanks
WHERE PriceRank <= 5;
