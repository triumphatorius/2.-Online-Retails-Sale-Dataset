USE victor;
SELECT 
    *
FROM
    online_retail;

-- convert the InvoiceDate column from TEXT to DATE in the format "23-12-2010" (day-month-year)
UPDATE online_retail 
SET 
    InvoiceDate = STR_TO_DATE(InvoiceDate, '%d-%m-%Y');

ALTER TABLE online_retail
MODIFY COLUMN InvoiceDate DATE;

-- convert the InvoiceTime column from TEXT to TIME in the format "23-12-2010" (day-month-year)
UPDATE online_retail 
SET 
    InvoiceTime = STR_TO_DATE(InvoiceTime, '%h:%i:%s %p');

ALTER TABLE online_retail
MODIFY COLUMN InvoiceTime TIME;

-- check data types
DESCRIBE online_retail;

-- Top Countries by Sales:
SELECT 
    Country, ROUND(SUM(TotalSale)) AS Total_Sales
FROM
    online_retail
GROUP BY Country
ORDER BY Total_Sales DESC
LIMIT 10;

-- Bottom Countries by Sales:
SELECT 
    Country, ROUND(SUM(TotalSale)) AS Total_Sales
FROM
    online_retail
GROUP BY Country
ORDER BY Total_Sales
LIMIT 10;

-- Monthly Sales Trend from top to bottom:
SELECT 
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS Month,
    FORMAT(SUM(Totalsale), 2) AS MonthlySale
FROM
    online_retail
GROUP BY Month
ORDER BY SUM(Totalsale) DESC;

-- Time Sales Trend from top to bottom:
SELECT 
    InvoiceTime AS Time, FORMAT(SUM(Totalsale), 0) AS HourSale
FROM
    online_retail
GROUP BY InvoiceTime
ORDER BY SUM(Totalsale) DESC;
-- order by MonthlySale desc;

SELECT 
    StockCode, Description, SUM(Quantity) AS TotalQuantitySold
FROM
    online_retail
GROUP BY StockCode , Description
ORDER BY TotalQuantitySold DESC
LIMIT 10;

-- Customer Analysis:
SELECT 
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    FORMAT(AVG(Totalsale), 0) AS AVGPurchasedValue
FROM
    online_retail;

-- RFM (Recency, Frequency, Monetary) analysis.
-- Analyzing customers based on how recently they made a purchase, how often they make purchases, and how much they spend.
SELECT 
    CustomerID,
    MAX(InvoiceDate) AS LastPurcaseDate,
    COUNT(DISTINCT InvoiceNo) AS TotalTransaction,
    ROUND(SUM(Totalsale)) AS TotalSpent
FROM
    online_retail
WHERE
    CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY LastPurcaseDate DESC;

-- Determine the percentage of customers who made repeat purchases.
SELECT 
    COUNT(DISTINCT CustomerID) AS TotalCustomers,
    COUNT(DISTINCT CASE
            WHEN TotalTransactions > 1 THEN CustomerID
        END) AS RepeatCustomers,
    COUNT(DISTINCT CASE
            WHEN TotalTransactions > 1 THEN CustomerID
        END) / COUNT(DISTINCT CustomerID) * 100 AS RetentionRate
FROM
    (SELECT 
        CustomerID, COUNT(DISTINCT InvoiceNo) AS TotalTransactions
    FROM
        online_retail
    GROUP BY CustomerID) AS CustomerSummary;
    
    
-- Product with the Highest Sales
SELECT 
    StockCode,
    Description,
    FORMAT(SUM(Totalsale), 0) AS TotalSales
FROM
    online_retail
GROUP BY StockCode , Description
ORDER BY SUM(Totalsale) DESC
LIMIT 1;

-- Product with the Lowest Sales
SELECT 
    StockCode,
    Description,
    FORMAT(SUM(Totalsale), 0) AS TotalSales
FROM
    online_retail
GROUP BY StockCode , Description
ORDER BY SUM(Totalsale)
LIMIT 1;


-- products with a significant increase or decrease in sales
-- Step 1: Common Table Expression (CTE) named SalesChange
-- Calculates the total sales for each product and finds the latest date of sale
WITH SalesChange AS (
    SELECT
        StockCode,
        Description,
        MAX(InvoiceDate) AS LatestDate,
        SUM(Totalsale) AS TotalSales
    FROM online_retail
    GROUP BY StockCode, Description
)

-- Step 2: Main Query
-- Compares the total sales for each product in the latest period with the total sales in the previous period
SELECT
    s.StockCode,
    s.Description,
    s.TotalSales AS LatestTotalSales,
    p.TotalSales AS PreviousTotalSales,
    round(((s.TotalSales - p.TotalSales) / p.TotalSales) * 100) AS SalesChangePercentage
FROM SalesChange s
JOIN SalesChange p ON s.StockCode = p.StockCode

-- Step 3: Filtering
-- Filters the results based on the time period for the latest and previous dates
WHERE s.LatestDate >=  '2011-12-09'  -- Change the time period as needed
  AND p.LatestDate >= '2010-12-01' -- Change the time period as needed

-- Step 4: Ordering
-- Orders the results by the percentage change in sales in descending order

ORDER BY SalesChangePercentage DESC;

SELECT 
    MAX(InvoiceDate), MIN(InvoiceDate)
FROM
    online_retail;

-- average unit price per product
SELECT 
    StockCode,
    Description,
    ROUND(AVG(UnitPrice), 2) AVG_per_unit
FROM
    online_retail
GROUP BY StockCode , Description
ORDER BY AVG_per_unit DESC;

-- How do sales vary across different countries 
SELECT 
    Country, ROUND(SUM(Totalsale), 2) AS TotalSalesPerCountry
FROM
    online_retail
GROUP BY Country
ORDER BY TotalSalesPerCountry DESC;

-- Are there specific products that are popular in certain countries?
SELECT 
    Country,
    Description,
    ROUND(SUM(Totalsale), 0) AS TotalSalesPerCountry
FROM
    online_retail
GROUP BY Country , Description
ORDER BY TotalSalesPerCountry DESC;

-- the most popular product for each country
with CTE_ranked_product as (
select
Country,
Description as  MostPopularProduct,
sum(Quantity) as TotalQuantitySold,
rank() over(partition by Country order by sum(Quantity) desc) as rank_popularity
from online_retail
group by Country, Description
order by sum(Quantity) desc
)

SELECT 
    *
FROM
    CTE_ranked_product
WHERE
    rank_popularity = 1;

-- =================================================================================================
-- Country-wise Analysis:

SELECT 
    Country, ROUND(SUM(Totalsale)) AS Totalsales
FROM
    online_retail
GROUP BY Country
ORDER BY SUM(Totalsale) DESC;


-- What is the distribution of customers across countries?
SELECT 
    Country,
    COUNT(DISTINCT CustomerID) AS total_distincts_customers
FROM
    online_retail
GROUP BY Country
ORDER BY total_distincts_customers DESC;

-- What is the distribution rate  of customers across countries?
WITH TotalCounts AS (
    SELECT COUNT(DISTINCT CustomerID) AS total_customers
    FROM online_retail
)

SELECT
    Country,
    COUNT(DISTINCT CustomerID) AS total_distincts_customers,
    (COUNT(DISTINCT CustomerID) / tc.total_customers) * 100 AS CustomerDistributionRate
FROM
    online_retail
JOIN TotalCounts tc ON 1 = 1
GROUP BY
    Country, tc.total_customers
ORDER BY
    total_distincts_customers DESC;


-- ========================================================================================================
-- Invoice Analysis:
-- How many unique invoices are there in the dataset?
SELECT 
    COUNT(DISTINCT InvoiceNo)
FROM
    online_retail;

-- What is the average and total sale per invoice?
SELECT 
    InvoiceNo,
    AVG(Totalsale) AS AVG_,
    ROUND(SUM(Totalsale)) AS Totalsales
FROM
    online_retail
GROUP BY InvoiceNo
ORDER BY SUM(Totalsale) DESC;

-- Is there any correlation between the time of the day and the sales amount?
SELECT 
    InvoiceTime, ROUND(AVG(Totalsale)) AS AverageSale
FROM
    online_retail
GROUP BY InvoiceTime
ORDER BY AverageSale DESC;


-- =========================================================================================
SELECT 
    Description, SUM(Quantity)
FROM
    online_retail
GROUP BY Description;


-- What is the distribution rate of quantities sold for different products?
WITH CTE_total_quantity AS (
    SELECT sum(Quantity) AS total_quantity
    FROM online_retail
)

SELECT
    Description,
    round((sum(Quantity) / tq.total_quantity) * 100 ,2)  AS quantity_distribution_rate
FROM
    online_retail
JOIN CTE_total_quantity tq ON 1 = 1
GROUP BY
    Description, tq.total_quantity
ORDER BY
    quantity_distribution_rate DESC;

-- Are there any outliers in terms of extremely high or low quantities?
WITH QuantityStats AS (
    SELECT
        Description,
        Quantity,
        SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(Quantity ORDER BY Quantity), ',', 25), ',', -1) AS Q1,
        SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(Quantity ORDER BY Quantity), ',', 75), ',', -1) AS Q3
    FROM
        online_retail
    GROUP BY
        Description, Quantity
)

SELECT
    Description,
    Quantity,
    CASE
        WHEN Quantity < Q1 - 1.5 * (Q3 - Q1) OR Quantity > Q3 + 1.5 * (Q3 - Q1) THEN 'Outlier'
        ELSE 'Not an Outlier'
    END AS OutlierStatus
FROM
    QuantityStats;

-- ===================================================================================
-- Customer Segmentation:
-- Can we categorize customers into segments based on their purchasing behavior?
with CTE_customer_segment as (
select
CustomerID,
count( distinct InvoiceNo) AS TotalTransactions,
round(sum(Totalsale)) as  TotalSpent,
round(avg(Totalsale)) as  AvgTransactionAmount
from online_retail
group by CustomerID
order by TotalSpent desc
)

SELECT 
    CustomerID,
    TotalTransactions,
    TotalSpent,
    CASE
        WHEN
            TotalTransactions >= 10
                AND TotalSpent >= 3000
        THEN
            'High Value Customer'
        WHEN
            TotalTransactions >= 5
                AND TotalSpent >= 2000
        THEN
            'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS Segment
FROM
    CTE_customer_segment;

-- ===========================================================================================
--      Return Analysis:
-- =======================================================
-- Are there instances of returned items in the dataset?
SELECT 
    Description, Quantity, Totalsale, Country
FROM
    online_retail
WHERE
    Quantity < 0
ORDER BY Totalsale;


-- What is the frequency and value of returned items?
SELECT 
    Description,
    COUNT(*) AS returned_item_count,
    ROUND(SUM(Totalsale)) AS Total_losses
FROM
    online_retail
WHERE
    Quantity < 0 AND Description IS NOT NULL
GROUP BY Description
ORDER BY returned_item_count DESC;


-- Can we identify any patterns related to returned products?
-- Examine how returns vary over time and countries
SELECT 
    Description,
    InvoiceDate,
    Country,
    COUNT(*) AS returned_item_count
FROM
    online_retail
WHERE
    Quantity < 0 AND Description IS NOT NULL
GROUP BY Description , InvoiceDate , Country
ORDER BY returned_item_count DESC;

-- =====================================================================
--          -- Time-based Analysis: --
-- =========================================================

SELECT 
    DAYNAME(InvoiceDate) AS day_of_week, COUNT(*) AS sales_count
FROM
    online_retail
WHERE
    DAYNAME(InvoiceDate) IS NOT NULL
GROUP BY day_of_week
ORDER BY sales_count DESC;

SELECT 
    MONTHNAME(InvoiceDate) AS month, COUNT(*) AS sales_count
FROM
    online_retail
WHERE
    MONTHNAME(InvoiceDate) IS NOT NULL
GROUP BY month
ORDER BY sales_count DESC;

-- Is there any correlation between the time of the day and the quantity of products sold?
SELECT 
    InvoiceTime AS time_of_day, COUNT(*) AS sales_count
FROM
    online_retail
GROUP BY time_of_day
ORDER BY sales_count DESC;

SELECT 
    InvoiceTime AS time_of_day, COUNT(*) AS sales_count
FROM
    online_retail
GROUP BY time_of_day
HAVING COUNT(*) <= 2
ORDER BY sales_count DESC;



    

















