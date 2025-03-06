-- create a database
CREATE DATABASE SuperstoreSales;
-- use the created database
USE SuperstoreSales;
-- create a table under the database
CREATE TABLE superstoresales (
    Row_ID INT,
    Order_Priority VARCHAR(255),
    Discount FLOAT,
    Unit_Price FLOAT,
    Shipping_Cost FLOAT,
    Customer_ID INT,
    Customer_Name VARCHAR(255),
    Ship_Mode VARCHAR(255),
    Customer_Segment VARCHAR(255),
    Product_Category VARCHAR(255),
    Product_SubCategory VARCHAR(255),
    Product_Container VARCHAR(255),
    Product_Name VARCHAR(255),
    Product_BaseMargin FLOAT,
    Region VARCHAR(255),
    Manager VARCHAR(255),
    State_Province VARCHAR(255),
    City VARCHAR(255),
    Postal_Code INT,
    Order_Date INT,
    Ship_Date INT,
    Profit FLOAT,
    Quantity INT,
    Sales FLOAT,
    Order_ID INT,
    Return_Status VARCHAR(255)
);

-- count the number of data in the table after bulk import(9426 data)
select count(*) from superstoresales;

-- display the table
select * from superstoresales;




-- explore the data

select Order_Priority,count(*) 
from superstoresales
group by Order_Priority;

select Customer_Name,count(*) 
from superstoresales
group by Customer_Name;




-- data cleaning

select row_ID, count(*) 
from superstoresales
group by row_ID
having count(*) > 1;

select count(*) 
from superstoresales
where Product_BaseMargin = '';

SET SQL_SAFE_UPDATES = 0;

delete 
from superstoresales
where Product_BaseMargin = '';




-- exploratory data analysis

-- 'Sales' column
select 
    COUNT(*) as Total_Count,
    AVG(Sales) as Average_Sales,
    STD(Sales) as Standard_Deviation,
    MIN(Sales) as Minimum_Sale,
    MAX(Sales) as Maximum_Sale
from superstoresales;

-- 'Profit' column
select 
    AVG(Profit) as Average_Profit,
    STD(Profit) as Standard_Deviation,
    MIN(Profit) as Minimum_Profit,
    MAX(Profit) as Maximum_Profit
from superstoresales;

--  customer segment
select Customer_Segment, count(*) as Count
from superstoresales
group by Customer_Segment;

--  product categories
select Product_Category, count(*) as Count
FROM superstoresales
group by Product_Category;

-- Ship mode 
select Ship_Mode, count(*) as Count
from superstoresales
group by Ship_Mode;

-- Monthly sales trend
select 
    EXTRACT(YEAR FROM Order_Date) as Year,
    EXTRACT(MONTH FROM Order_Date) as Month,
    SUM(Sales) AS Total_Sales
from superstoresales
group by Year, Month
order by Year, Month;

-- Seasonal patterns in order quantity
select 
    EXTRACT(MONTH FROM Order_Date) as Month,
    AVG(Quantity) as Quantity
from superstoresales
group by Month
order by Month;




-- RFM Segmentation
update superstoresales
SET Order_Date = DATE_ADD('1899-12-30', INTERVAL Order_Date DAY) ;

update superstoresales
set Order_Date = str_to_date(Order_Date, '%Y-%m-%d');

select max(Order_Date) 
from superstoresales;
select * from superstoresales;

CREATE OR REPLACE VIEW RFM_SCORE_DATA AS
WITH CUSTOMER_AGGREGATED_DATA AS
(SELECT
	Customer_Name,
    DATEDIFF((SELECT MAX(Order_Date) FROM SALES_SAMPLE_DATA), MAX(Order_Date)) AS RECENCY_VALUE,
    COUNT(DISTINCT Order_ID) AS FREQUENCY_VALUE,
    ROUND(SUM(SALES),0) AS MONETARY_VALUE
FROM superstoresales
GROUP BY Customer_Name),

RFM_SCORE AS
(SELECT 
	C.*,
    NTILE(4) OVER (ORDER BY RECENCY_VALUE DESC) AS R_SCORE,
    NTILE(4) OVER (ORDER BY FREQUENCY_VALUE ASC) AS F_SCORE,
    NTILE(4) OVER (ORDER BY MONETARY_VALUE ASC) AS M_SCORE
FROM CUSTOMER_AGGREGATED_DATA AS C)

SELECT
	R.Customer_Name,
    R.RECENCY_VALUE,
    R_SCORE,
    R.FREQUENCY_VALUE,
    F_SCORE,
    R.MONETARY_VALUE,
    M_SCORE,
    (R_SCORE + F_SCORE + M_SCORE) AS TOTAL_RFM_SCORE,
    CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) AS RFM_SCORE_COMBINATION
FROM RFM_SCORE AS R;

SELECT * FROM RFM_SCORE_DATA WHERE RFM_SCORE_COMBINATION = '111';

SELECT RFM_SCORE_COMBINATION FROM RFM_SCORE_DATA;


CREATE OR REPLACE VIEW RFM_ANALYSIS AS
SELECT 
    RFM_SCORE_DATA.*,
    CASE
        WHEN RFM_SCORE_COMBINATION IN (111, 112, 121, 132, 211, 211, 212, 114, 141) THEN 'CHURNED CUSTOMER'
        WHEN RFM_SCORE_COMBINATION IN (133, 134, 143, 224, 334, 343, 344, 144) THEN 'SLIPPING AWAY, CANNOT LOSE'
        WHEN RFM_SCORE_COMBINATION IN (311, 411, 331) THEN 'NEW CUSTOMERS'
        WHEN RFM_SCORE_COMBINATION IN (222, 231, 221,  223, 233, 322) THEN 'POTENTIAL CHURNERS'
        WHEN RFM_SCORE_COMBINATION IN (323, 333,321, 341, 422, 332, 432) THEN 'ACTIVE'
        WHEN RFM_SCORE_COMBINATION IN (433, 434, 443, 444) THEN 'LOYAL'
    ELSE 'Other'
    END AS CUSTOMER_SEGMENT
FROM RFM_SCORE_DATA;


SELECT
	CUSTOMER_SEGMENT,
    COUNT(*) AS NUMBER_OF_CUSTOMERS,
    ROUND(AVG(MONETARY_VALUE),0) AS AVERAGE_MONETARY_VALUE
FROM RFM_ANALYSIS
GROUP BY CUSTOMER_SEGMENT;