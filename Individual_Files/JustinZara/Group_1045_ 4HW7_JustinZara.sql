USE WideWorldImporters;
--Medium articles used:
--https://medium.com/%40arun-iiests/window-function-advanced-sql-a580556f8f1b
--https://medium.com/%40ebrubddl/rollup-and-cube-in-sql-4086746ec62b

--8 examples of code from 
--Proposition 1:List the most populated countries whose region is the Americas.

SELECT c.CountryName ,
ROW_NUMBER() OVER (ORDER BY c.LatestRecordedPopulation  DESC) AS Row_Number ,
RANK() OVER (ORDER BY c.LatestRecordedPopulation  DESC) AS Top_Most_Populated_Countries_Rank, c.LatestRecordedPopulation 
FROM Application.Countries c
WHERE c.Region ='Americas';
--The resulting query outputs countries in order of most populated descending, and the row number of each country

--Proposition 2: Select the quantity of the previous order for the first 10 orderlines
SELECT TOP 10 ol.OrderLineID , LAG(Quantity) OVER (ORDER BY ol.OrderID) AS QuantityOfPreviousOrderLines
FROM Sales.OrderLines ol;

--Proposition 3: Select the quantity of the next orderline
SELECT TOP 10 ol.OrderLineID , LEAD(Quantity) OVER (ORDER BY ol.OrderID) AS QuantityOfNextOrderLine
FROM Sales.OrderLines ol;

--Proposition 4: List out the dense rank of delivery methods used by purchase orders.
SELECT po.DeliveryMethodID, COUNT(*) as Count_Of_Purchase_Orders,
DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS Dense_Rank_Of_Delivery_Method
FROm Purchasing.PurchaseOrders po
GROUP BY  po.DeliveryMethodID;

--Proposition 5: List the running running average of the transaction amount excluding tax
SELECT st.SupplierTransactionID , st.AmountExcludingTax ,
AVG(st.AmountExcludingTax) OVER (ORDER BY st.SupplierTransactionID ASC) as Running_Average
FROM  Purchasing.SupplierTransactions st

--Proposition 6: Select the subtotal rows of each region, and the grand total of all subregions.
SELECT c.Region , c.CountryName, Count(*) as Num_Of_countries
fROM Application.Countries c
GROUP BY ROLLUP (c.Region ,c.CountryName);
--resulting query shows the subtotals, then the grand total.

--Proposition 7: List out the countries grouped by region, the subtotal per region, the subtotal per country for all regions, and the grand total
SELECT c.Region, c.CountryName,
COUNT(*) AS Num_Of_Countries
FROM Application.Countries c
GROUP BY CUBE (c.Region, c.CountryName );

--Proposition 8: Select the subtotal of rows for each stock item, and the grand total for all stock items
SELECT ol.StockItemID , ol.OrderID, Count(*) as Num_Of_Stock_Items
fROM  Sales.OrderLines ol
GROUP BY ROLLUP (ol.StockItemID, ol.OrderID);

--proposition 9: List out the quantity per stock item ID + Order ID, the total quantity by stock item ID, the total quantity by order ID, and the grand total.
SELECT ol.StockItemID, ol.OrderID,
SUM(ol.Quantity) AS TotalQuantity
FROm Sales.OrderLines ol
GROUP BY CUBE(ol.StockItemID, ol.OrderID );
--resulting query shows all possible combinations of stock item ID and order ID.

--proposition 10: Get the subtotal of Supplier ID and Orderdate, Subtotal where theres no supplier, and the grand total
SELECT po.SupplierId, po.OrderDate,
COUNT(*) as OrderCount
FROM Purchasing.PurchaseOrders po 
GROUP BY ROLLUP (po.SupplierID, po.OrderDate )
ORDER BY po.SupplierID, po.OrderDate;


