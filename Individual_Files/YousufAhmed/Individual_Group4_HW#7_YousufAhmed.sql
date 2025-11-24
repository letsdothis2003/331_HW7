-- Query 1: Rank of each customer by total spent
SELECT 
    c.CustomerID,
    c.CustomerName,
    SUM(il.ExtendedPrice) AS TotalSpent,
    RANK() OVER (ORDER BY SUM(il.ExtendedPrice) DESC) AS SpendingRank
FROM Sales.Invoices i
JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Query 2: Running total sales of each customer
SELECT 
    c.CustomerName,
    i.InvoiceDate,
    SUM(il.ExtendedPrice) AS InvoiceAmount,
    SUM(SUM(il.ExtendedPrice)) OVER 
        (PARTITION BY c.CustomerName ORDER BY i.InvoiceDate) AS RunningTotal
FROM Sales.Invoices i
JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
GROUP BY c.CustomerName, i.InvoiceDate;

-- Query 3: Compare sales to previous month using LAG
SELECT 
    YEAR(i.InvoiceDate) AS SalesYear,
    MONTH(i.InvoiceDate) AS SalesMonth,
    SUM(il.ExtendedPrice) AS MonthlySales,
    LAG(SUM(il.ExtendedPrice)) 
        OVER (ORDER BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)) AS PreviousMonthSales
FROM Sales.Invoices i
JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate);

-- Query 4: Compare sales to next month using LEAD
SELECT 
    YEAR(i.InvoiceDate) AS SalesYear,
    MONTH(i.InvoiceDate) AS SalesMonth,
    SUM(il.ExtendedPrice) AS MonthlySales,
    LEAD(SUM(il.ExtendedPrice)) 
        OVER (ORDER BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)) AS NextMonthSales
FROM Sales.Invoices i
JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate);

-- Query 5: Percent Ranking of items by quantity sold
SELECT 
    il.StockItemID,
    SUM(il.Quantity) AS TotalUnits,
    PERCENT_RANK() OVER (ORDER BY SUM(il.Quantity))*100 AS PercentileRank
FROM Sales.InvoiceLines il
GROUP BY il.StockItemID
order by PercentileRank DESC;

-- Query 6: Bottom 10% of items based on their percent rank
WITH ProductSales AS 
(
    SELECT 
        il.StockItemID,
        SUM(il.Quantity) AS TotalUnits,
        PERCENT_RANK() OVER (ORDER BY SUM(il.Quantity))*100 AS PercentileRank
    FROM Sales.InvoiceLines il
    GROUP BY il.StockItemID
)
SELECT 
    StockItemID,
    TotalUnits,
    PercentileRank
FROM ProductSales
WHERE PercentileRank <= 10
ORDER BY PercentileRank, TotalUnits;

-- Query 6: Pivot each customer's total order by month
SELECT *
FROM
(
    SELECT 
        c.CustomerName,
        MONTH(i.InvoiceDate) AS SalesMonth,
        il.ExtendedPrice
    FROM Sales.Invoices i
    JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
    JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
) AS SourceTable
PIVOT
(
    SUM(ExtendedPrice)
    FOR SalesMonth IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
) AS PivotTable;

-- Query 7: Grouping sales by customer, month, and getting total sales
SELECT 
    c.CustomerName,
    MONTH(i.InvoiceDate) AS SalesMonth,
    SUM(il.ExtendedPrice) AS TotalSales
FROM Sales.Invoices i
JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
GROUP BY 
    GROUPING SETS (
        (c.CustomerName, MONTH(i.InvoiceDate)),
        (c.CustomerName)
    );

-- Query 8: Rollup group by year, month, and total sales
SELECT 
    YEAR(i.InvoiceDate) AS SalesYear,
    MONTH(i.InvoiceDate) AS SalesMonth,
    SUM(il.ExtendedPrice) AS TotalSales
FROM Sales.Invoices i
JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
GROUP BY ROLLUP (YEAR(i.InvoiceDate), MONTH(i.InvoiceDate));

-- Query 9: Grouping items by name, brand, and getting total sales

SELECT 
    si.StockItemName,
    si.Brand,
    SUM(il.ExtendedPrice) AS TotalSales
FROM Sales.InvoiceLines il
JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID
GROUP BY 
    GROUPING SETS (
        (si.StockItemName, si.Brand),
        (si.Brand)
    );

-- Query 10: Rank of each customer based on their average monthly total
WITH MonthlySales AS (
    SELECT 
        c.CustomerName,
        YEAR(i.InvoiceDate) AS SalesYear,
        MONTH(i.InvoiceDate) AS SalesMonth,
        SUM(il.ExtendedPrice) AS MonthlyTotal
    FROM Sales.Invoices i
    JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
    JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
    GROUP BY c.CustomerName, YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)
),
CustAvg AS (
    SELECT 
        CustomerName,
        AVG(MonthlyTotal) AS AvgMonthlyTotal
    FROM MonthlySales
    GROUP BY CustomerName
)
SELECT *,
    RANK() OVER (ORDER BY AvgMonthlyTotal DESC) AS RankByAvgMonthly
FROM CustAvg;




