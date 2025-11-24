/* Query 1 – Rank Customers by Total Sales
Functional Specification
- Join Customers → Invoices → InvoiceLines.
- Sum invoice line amounts grouped by customer.
- Use RANK() to order customers by total ExtendedPrice.
- Return rank, id, name, and total revenue.
*/
SELECT
    c.CustomerID,
    c.CustomerName,
    SUM(il.ExtendedPrice) AS TotalSales,
    RANK() OVER (ORDER BY SUM(il.ExtendedPrice) DESC) AS SalesRank
FROM WideWorldImporters.Sales.Customers AS c
JOIN WideWorldImporters.Sales.Invoices AS i
  ON c.CustomerID = i.CustomerID
JOIN WideWorldImporters.Sales.InvoiceLines AS il
  ON il.InvoiceID = i.InvoiceID
GROUP BY c.CustomerID, c.CustomerName;

/* Query 2 – Previous Invoice Amount (LAG)
Functional Specification
- Compute total amount per invoice.
- Use LAG() to show the previous invoice’s total.
- Order by InvoiceID.
*/
WITH InvTotals AS (
  SELECT InvoiceID, SUM(ExtendedPrice) AS TotalAmt
  FROM WideWorldImporters.Sales.InvoiceLines
  GROUP BY InvoiceID
)
SELECT
    InvoiceID,
    TotalAmt,
    LAG(TotalAmt) OVER (ORDER BY InvoiceID) AS PrevTotal
FROM InvTotals;

/* Query 3 – Running Total of Sales
Functional Specification
- Sum daily sales from invoice lines.
- Use SUM() OVER(ORDER BY) to compute a running total.
- Return date, day sales, and cumulative sales.
*/
SELECT
    i.InvoiceDate,
    SUM(il.ExtendedPrice) AS DaySales,
    SUM(SUM(il.ExtendedPrice)) OVER (ORDER BY i.InvoiceDate) AS RunningTotal
FROM WideWorldImporters.Sales.Invoices AS i
JOIN WideWorldImporters.Sales.InvoiceLines AS il
  ON il.InvoiceID = i.InvoiceID
GROUP BY i.InvoiceDate;

/* Query 4 – Top 3 Most Expensive Items
Functional Specification
- Use ROW_NUMBER() to order items by UnitPrice.
- Keep only the top 3 most expensive.
- Return item id, name, and price.
*/
WITH R AS (
  SELECT
      StockItemID,
      StockItemName,
      UnitPrice,
      ROW_NUMBER() OVER (ORDER BY UnitPrice DESC) AS rn
  FROM WideWorldImporters.Warehouse.StockItems
)
SELECT StockItemID, StockItemName, UnitPrice
FROM R
WHERE rn <= 3;

/* Query 5 – Pivot Sales by Year
Functional Specification
- Group invoice revenue by year.
- Pivot selected years (2013–2015) into columns.
- Return revenue per year.
*/
WITH Y AS (
  SELECT YEAR(i.InvoiceDate) AS SalesYear,
         il.ExtendedPrice AS Amount
  FROM WideWorldImporters.Sales.Invoices AS i
  JOIN WideWorldImporters.Sales.InvoiceLines AS il
    ON il.InvoiceID = i.InvoiceID
)
SELECT *
FROM Y
PIVOT (
  SUM(Amount)
  FOR SalesYear IN ([2013], [2014], [2015])
) AS p;

/* Query 6 – Unpivot Basic Attributes (Fixed)
Functional Specification
- CAST both values to NVARCHAR to avoid type conflicts.
- Unpivot ColorID and Size into (Attr, Val) rows.
*/
SELECT si.StockItemID, Attr, Val
FROM WideWorldImporters.Warehouse.StockItems AS si
CROSS APPLY (VALUES
  ('Color', CAST(si.ColorID AS nvarchar(50))),
  ('Size',  CAST(si.Size    AS nvarchar(50)))
) AS v(Attr, Val);


/* Query 7 – Grouping Sets: Year, Customer, Total
Functional Specification
- Use GROUPING SETS to produce:
  • Total per year
  • Total per customer
  • Grand total
- Return grouping combinations and total revenue.
*/
SELECT
    YEAR(i.InvoiceDate) AS SalesYear,
    c.CustomerName,
    SUM(il.ExtendedPrice) AS TotalSales
FROM WideWorldImporters.Sales.Invoices AS i
JOIN WideWorldImporters.Sales.InvoiceLines AS il
  ON il.InvoiceID = i.InvoiceID
JOIN WideWorldImporters.Sales.Customers AS c
  ON c.CustomerID = i.CustomerID
GROUP BY GROUPING SETS (
    (YEAR(i.InvoiceDate)),
    (c.CustomerName),
    ()
);

/* Query 8 – Weekly Sales (DATE_BUCKET)
Functional Specification
- Use DATE_BUCKET to group invoice dates into weekly buckets.
- Summarize TotalDryItems per bucket.
- Return WeekStart and total quantity.
*/
SELECT
    DATE_BUCKET(WEEK, 1, InvoiceDate) AS WeekStart,
    SUM(TotalDryItems) AS TotalQty
FROM WideWorldImporters.Sales.Invoices
GROUP BY DATE_BUCKET(WEEK, 1, InvoiceDate)
ORDER BY WeekStart;

/* Query 9 – Items Above Average Price (Window AVG)
Functional Specification
- Compute AVG(UnitPrice) per ColorID using a window function.
- Filter in an outer query because window functions cannot be in WHERE.
*/
WITH X AS (
    SELECT
        si.StockItemID,
        si.StockItemName,
        si.UnitPrice,
        AVG(si.UnitPrice) OVER (PARTITION BY si.ColorID) AS AvgPriceByColor
    FROM WideWorldImporters.Warehouse.StockItems AS si
)
SELECT *
FROM X
WHERE UnitPrice > AvgPriceByColor;

/* Query 10 – Latest Invoice Per Customer
Functional Specification
- Use ROW_NUMBER() partitioned by CustomerID.
- Order each customer’s invoices by date descending.
- Keep only the latest invoice (rn = 1).
*/
WITH R AS (
  SELECT
      i.CustomerID,
      i.InvoiceID,
      i.InvoiceDate,
      ROW_NUMBER() OVER (
          PARTITION BY i.CustomerID
          ORDER BY i.InvoiceDate DESC
      ) AS rn
  FROM WideWorldImporters.Sales.Invoices AS i
)
SELECT CustomerID, InvoiceID, InvoiceDate
FROM R
WHERE rn = 1;
