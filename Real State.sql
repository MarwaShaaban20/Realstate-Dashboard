--Create Database
CREATE DATABASE RealEstateDB;
GO

USE RealEstateDB;
GO
-- Create Tables
CREATE TABLE Property (
    PropertyID INT PRIMARY KEY,
    PropertyType VARCHAR(50),
    Location VARCHAR(255),
    Size_sqm INT,
    PriceUSD INT
);
CREATE TABLE Clients (
    ClientID INT PRIMARY KEY,
    FirstName VARCHAR(100),
    LastName VARCHAR(100),
    Phone VARCHAR(50),
    Email VARCHAR(100)
);
CREATE TABLE Agents (
    AgentID INT PRIMARY KEY,
    FirstName VARCHAR(100),
    LastName VARCHAR(100),
    Phone VARCHAR(50),
    Email VARCHAR(100)
);
CREATE TABLE Sales (
    SaleID INT PRIMARY KEY,
    PropertyID INT,
    ClientID INT,
    AgentID INT,
    SaleDate DATE,
    SalePrice INT,
    FOREIGN KEY (PropertyID) REFERENCES Property(PropertyID),
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID),
    FOREIGN KEY (AgentID) REFERENCES Agents(AgentID)
);
CREATE TABLE Visits (
    VisitID INT PRIMARY KEY,
    PropertyID INT,
    ClientID INT,
    AgentID INT,
    VisitDate DATE,
    FOREIGN KEY (PropertyID) REFERENCES property(PropertyID),
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID),
    FOREIGN KEY (AgentID) REFERENCES Agents(AgentID)
);
---- ≈ŸÂ«— «·≈⁄œ«œ«  «·„ ﬁœ„…
--EXEC sp_configure 'show advanced options', 1;
--RECONFIGURE;

----  ›⁄Ì· «· Õ„Ì· „‰ «·„·›«  «·Œ«—ÃÌ… (Ad Hoc Queries)
--EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;

--Load Data
BULK INSERT Property
FROM 'D:\Data Analysis\My Projects\Data\Realstate\property.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n'
);
select*
from Property;
BULK INSERT Clients
FROM 'D:\Data Analysis\My Projects\Data\Realstate\Clients.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n'
);
select*
from Clients;
BULK INSERT Agents
FROM 'D:\Data Analysis\My Projects\Data\Realstate\Agents.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n'
);
select*
from Agents;
BULK INSERT Sales
FROM 'D:\Data Analysis\My Projects\Data\Realstate\Sales.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n'
);
select*
from Sales
BULK INSERT Visits
FROM 'D:\Data Analysis\My Projects\Data\Realstate\Visits.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n'
);
select*
from Visits;

--SQLQueries

Alter Table Agents
Add FullName AS (FirstName + ' '+ LastName);
Select * 
from Agents

Alter Table Clients
Add FullName AS (FirstName + ' '+ LastName);
Select * 
from Clients

ALTER TABLE Clients
ADD TotalVisited INT,
    TotalPurchased INT;

UPDATE c
SET 
    c.TotalVisited = ISNULL(v.VisitCount, 0),
    c.TotalPurchased = ISNULL(s.PurchaseCount, 0)
FROM Clients c
LEFT JOIN (
    SELECT ClientID, COUNT(*) AS VisitCount
    FROM Visits
    GROUP BY ClientID
) v ON c.ClientID = v.ClientID
LEFT JOIN (
    SELECT ClientID, COUNT(*) AS PurchaseCount
    FROM Sales
    GROUP BY ClientID
) s ON c.ClientID = s.ClientID;


ALTER TABLE Clients
ADD IsRepeatBuyer BIT; 

UPDATE Clients
SET IsRepeatBuyer = CASE 
    WHEN s.PurchaseCount > 1 THEN 1
    ELSE 0
END
FROM Clients c
LEFT JOIN (
    SELECT ClientID, COUNT(*) AS PurchaseCount
    FROM Sales
    GROUP BY ClientID
) s ON c.ClientID = s.ClientID;

ALTER TABLE Agents
ADD AgentNumber VARCHAR(20);
UPDATE Agents
SET AgentNumber = CAST(AgentID AS VARCHAR);
Select *
from Agents

ALTER TABLE Clients
ADD EmailType VARCHAR(20);

UPDATE Clients
SET EmailType = CASE
    WHEN Email LIKE '%@gmail.%'
        OR Email LIKE '%@yahoo.%'
        OR Email LIKE '%@hotmail.%'
        OR Email LIKE '%@outlook.%'
        OR Email LIKE '%@icloud.%'
        OR Email LIKE '%@live.%'
        THEN 'Personal'
    ELSE 'Business'
END;

SELECT 
    ClientID,
    Email,
    CASE
        WHEN Email LIKE '%@gmail.%'
          OR Email LIKE '%@yahoo.%'
          OR Email LIKE '%@hotmail.%'
          OR Email LIKE '%@outlook.%'
          OR Email LIKE '%@icloud.%'
          OR Email LIKE '%@live.%'
        THEN 'Personal'
        ELSE 'Business'
    END AS EmailType
FROM Clients;

SELECT 
    s.SaleID,
    s.SaleDate,
    s.SalePrice,
    s.ClientID,
    s.AgentID,
    p.PropertyID,
    p.PropertyType,
    p.Location,
    p.Size_sqm,
    p.PriceUSD
INTO SalesProperty
FROM Sales s
JOIN Property p ON s.PropertyID = p.PropertyID;

Select *
from SalesProperty

--Average sale value per property type
SELECT 
    p.PropertyType,
    AVG(s.SalePrice) AS AvgSalesValue
FROM Sales s
JOIN Property p ON s.PropertyID = p.PropertyID
GROUP BY  p.PropertyType
Order By AvgSalesValue Desc;

SELECT 
    CAST(s.saleDate AS DATE) AS saleDate,
    p.PropertyType,
    AVG(s.SalePrice) AS AvgSalesValue
FROM Sales s
JOIN Property p ON s.PropertyID = p.PropertyID
WHERE s.saleDate IS NOT NULL
GROUP BY 
    CAST(s.saleDate AS DATE),
    p.PropertyType
ORDER BY 
    saleDate,
    AvgSalesValue DESC;

--Conversion rate = (sales / visits) per property or agent
--ﬂ«„ ⁄„Ì· “«— ⁄ﬁ«—° Ê›⁄·Ì« «‘ —Ï »⁄œ «·“Ì«—…ø
SELECT 
    p.PropertyType,
    COUNT(DISTINCT s.SaleID) * 1.0 /  NULLIF(COUNT(DISTINCT v.VisitID), 0)AS ConversionRate
FROM Property p
LEFT JOIN Sales s ON p.PropertyID = s.PropertyID
LEFT JOIN Visits v ON p.PropertyID = v.PropertyID
GROUP BY p.PropertyType;

--Number of properties visited per client
SELECT Top 5
    CONCAT(c.FirstName, ' ', c.LastName) AS FullName,
    COUNT(DISTINCT v.PropertyID) AS PropertiesVisited
FROM Clients c
JOIN Visits v ON c.ClientID = v.ClientID
GROUP BY CONCAT(c.FirstName, ' ', c.LastName)
Order By PropertiesVisited DESC;
--Â‰« ⁄œœ «·⁄ﬁ«—«  «··Ì “«—Â« ﬂ· ⁄„Ì· ›ﬁÊ·  «ÃÌ» «”„«¡ «ﬂ — Œ„” ⁄„·Â ⁄„·Â “Ì«—«  
--Top clients by sale value
SELECT top 5
  CONCAT(c.FirstName, ' ', c.LastName) AS FullName,
   SUM(s.SalePrice) AS TotalPurchasesValue
FROM Clients c
JOIN Sales s ON c.ClientID = s.ClientID
GROUP BY CONCAT(c.FirstName, ' ', c.LastName)
ORDER BY TotalPurchasesValue DESC;
--First-time vs repeat buyers
--Â‰« «‰« Âÿ·⁄ ﬂ«„ ⁄„Ì· «Ê· „—Â Ì‘ —Ì Ê ﬂ«„ ⁄„Ì· «‘ —Ì «ﬂ — „‰ „—Â
SELECT 
    BuyerType,
    COUNT(*) AS TotalClients
FROM (
    SELECT 
        CASE 
            WHEN COUNT(*) = 1 THEN 'First-time Buyer'
            ELSE 'Repeat Buyer'
        END AS BuyerType
    FROM Sales
    GROUP BY ClientID
) AS Buyers
GROUP BY BuyerType;

--Region-based client interest (visits by city)
--Â‰« «ﬂ — „œ‰ ›ÌÂ« “Ì«—«  Ê «Â „«„ »«·⁄„·«¡ «··Ì ⁄‰œ‰«
SELECT 
    p.Location,
    COUNT(v.VisitID) AS TotalVisits
FROM Visits v
JOIN Property p ON v.PropertyID = p.PropertyID
GROUP BY p.Location;

--High-performing areas (most sold or highest priced)
SELECT 
    p.Location,
    COUNT(s.SaleID) AS SalesCount,
    AVG(s.SalePrice) AS AvgSalePrice
FROM Sales s
JOIN Property p ON s.PropertyID = p.PropertyID
GROUP BY p.Location
ORDER BY SalesCount DESC, AvgSalePrice DESC;

--Average visit-to-sale ratio per location
--‰Õ”» „⁄œ· «· ÕÊÌ· „‰ “Ì«—«  ≈·Ï „»Ì⁄«  (Visit-to-Sale Ratio) ·ﬂ· „Êﬁ⁄ (Location)
-- Ì⁄‰Ì „‰ ﬂ«„ ﬂ· “Ì«—Â Õ’· »Ì⁄ ·ﬂ· „œÌ‰Â
SELECT 
    p.Location,
    COUNT(DISTINCT s.SaleID) * 1.0 / COUNT(DISTINCT v.VisitID) AS VisitToSaleRatio
FROM Property p
LEFT JOIN Visits v ON p.PropertyID = v.PropertyID
LEFT JOIN Sales s ON p.PropertyID = s.PropertyID
GROUP BY p.Location
Order By VisitToSaleRatio DESC;

--Number of listed properties by type and location
select  Location ,PropertyType,COUNT(*) as Number_of_Property
from Property
Group by  Location ,PropertyType
ORDER BY  Number_of_Property desc;

--Average price per square meter per city
select Location as city ,round(AVG(priceUSD/Size_sqm) ,2)as AvgPricePerSqm
from Property
group by Location
order by AvgPricePerSqm desc;

--Distribution of property types (Apartment, Villa, etc.)
select PropertyType ,count(*) AS  NumberOfProperties
from Property
group by PropertyType
order by  NumberOfProperties desc;

--Select Sales Date 
SELECT 
  CAST(saleDate AS DATE) AS saleDate
FROM Sales
WHERE saleDate IS NOT NULL
GROUP BY CAST(saleDate AS DATE)
ORDER BY saleDate

--Top 10 most expensive 
select top(10)PriceUSD,PropertyType, location ,Size_sqm
from Property
order by PriceUSD desc;

--Top 10 most visited properties
select top(10) p.PropertyType,count(v.VisitID)as totalvisit
from Property p
left join Visits v on p.PropertyID=v.PropertyID
group by p.PropertyType
order by totalvisit desc;

--Average sale value per property type
select p.PropertyType, avg(SalePrice) as avg_sales
from Property p
join Sales s on p.PropertyID=s.PropertyID
group by p.PropertyType
order by avg_sales desc;

--Conversion rate = (sales / visits) per property or agent
select p.PropertyType, count(distinct (s.SaleID ))*100/nullif(count(distinct(v.VisitID )),0 )as Conversion_rate 
from Sales s
left join Visits v on s.PropertyID=v.PropertyID
left join Property p on p.PropertyID=s.PropertyID
group by p.PropertyType
order by Conversion_rate desc;

  --Number of sales per agent
  select a.FullName,a.AgentID,count(s.SaleID)AS NumberOfSales
  from Agents a
  right join Sales s on a.AgentID=s.AgentID
  group by a.AgentID,a.FullName
  order by NumberOfSales desc;

  --Number of client visits per agent ⁄œœ “Ì«—«  «·⁄„·«¡ ·ﬂ· ÊﬂÌ·
  select a.AgentID,a.FullName ,count(v.VisitID)AS NumberOfClientVisits 
  from Agents a
  right join Visits v on a.AgentID=v.AgentID
  group by a.AgentID,a.FullName
  order by NumberOfClientVisits desc

  --Conversion rate per agent (visits ? sales)„‰ ≈Ã„«·Ì ⁄œœ «·“Ì«—«  «··Ì — »Â« ﬂ· ÊﬂÌ·° ﬂ«„ “Ì«—… „‰Â„ «‰ Â  »⁄„·Ì… »Ì⁄ø
  select a.AgentID, a.FullName ,round(COUNT(DISTINCT v.VisitID) * 1.0 / NULLIF(COUNT(DISTINCT s.SaleID), 0),2) AS Conversion_rateperagent
  from Agents a
  left join Visits v on a.AgentID=v.AgentID
  left join Sales s on a.AgentID=s.AgentID
  group by a.AgentID,a.FullName
  order by Conversion_rateperagent desc 


  --Avg sale value handled by each agent
  select a.FullName, a.AgentID , count(s.SaleID)as NumOfSales,round(avg(s.SalePrice),2) as Avgsale 
  from Agents a
  right join Sales s on a.AgentID=s.AgentID
  group by a.AgentID ,a.FullName
  order by Avgsale ,numofsales desc


  --Number of properties visited per client
  select c.FullName,c.ClientID ,count(v.PropertyID) as Numberofproperties
  from Clients c
  left join Visits v on c.ClientID=v.ClientID
  group by c.FullName,c.ClientID
  order by Numberofproperties desc 

  --Top clients by sale value
  select top( 5) c.FullName,c.ClientID , sum(s.SalePrice)as totalsales
  from Clients c
  left join Sales s on c.ClientID=s.ClientID
  group by c.FullName,c.ClientID
  order by totalsales desc 

  --First-time vs repeat buyers
  select c.FullName,c.ClientID ,  CASE 
    WHEN COUNT(s.SaleID) = 1 THEN 'First-time Buyer'
    ELSE 'Repeat Buyer'
  END AS BuyerType,
  COUNT(*) AS NumberOfClients
  from Clients c
  left join Sales s on c.ClientID=s.ClientID 
  group by c.FullName,c.ClientID
  order by NumberOfClients desc;

 --Region-based client interest (visits by city)
  select c.FullName ,c.ClientID ,count(v.VisitID)as totalvisit,p.Location
  from Clients c
  right join Visits v on c.ClientID=v.ClientID
  right join Property p on p.PropertyID=v.PropertyID
  group by c.FullName,c.ClientID,p.Location
  order by  totalvisit desc; 

  --Total visit by Location
  select count(v.VisitID)as totalvisit,p.Location
  from Clients c
  right join Visits v on c.ClientID=v.ClientID
  right join Property p on p.PropertyID=v.PropertyID
  group by p.Location
  order by  totalvisit desc; 

  -- PropertyType by Sales 
  select p.PropertyType ,sum(s.SalePrice) as totalsales
  from Property p
  left join Sales s on p.PropertyID=s.PropertyID
  group by p.PropertyType
  order by totalsales desc ;

  --location and visit by Sales
  select p.Location,count(s.SaleID) as totalsales ,sum(s.SalePrice) as totalprice
  from Property p
  left join Sales s on p.PropertyID=s.PropertyID
  group by p.Location
  order by totalsales desc ,totalprice desc; 

  --Average visit-to-sale ratio per location 
  select p.PropertyID,p.location ,count(distinct (s.SaleID ))/nullif(count(distinct(v.VisitID )),0 )as Conversion_rate 
  from Property p
  left join Sales s on p.PropertyID=s.PropertyID
  left join Visits v on p.PropertyID=v.PropertyID
  group by  p.PropertyID,p.location 
  order by Conversion_rate  desc;

  --Price and size distributions
  select PropertyType,Size_sqm,PriceUSD,Location
  from Property
  group by PropertyType,Size_sqm,PriceUSD,Location

 --Properties with longest and shortest time on market
 select min(VisitDate)
 from Visits;

 select max(VisitDate)
 from Visits;

 --«·⁄·«ﬁÂ »Ì‰ «·„”«ÕÂ Ê«·„ﬂ«‰ Ê‰Ê⁄Â 
 select Location,count(Size_sqm)as size ,PropertyType
 from Property
 group by Location,PropertyType
 order by size desc ;

  -------kpis--------

  --total clients
  select count(ClientID)as totalclients
  from Clients;

  --total agent
  select count(AgentID)as totalagent
  from Agents;

  --total property
  select count(PropertyID)as totalProperty
  from Property

  --totalvisit
  select count(VisitID)as totalvisit
  from Visits

  --totalsales
  select sum(SalePrice)as totalsales
  from Sales

  --avg_price
  select avg(SalePrice)as avg_price
  from Sales

  --avg Size_sqm
  select avg(Size_sqm)as avg_Size_sqm
  from Property

  --Conversion rates 
  select count(distinct (s.SaleID))*100/nullif(count(distinct(v.VisitID )),0 )as Conversion_rate 
  from Sales s
  left join Visits v on s.PropertyID=v.PropertyID

  --Sales trend over time
  select count(SaleID)as totalsales,SaleDate
  from Sales
  group by SaleDate
  order by totalsales desc;
