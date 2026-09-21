
/*CRESTWELL FCMG - ANALYTICAL VIEW 
===========================================*/

--1. Sales Performance
CREATE VIEW [dbo].[vw_SalesPerformance]
AS
SELECT
    s.SalesOrderID,
    s.OrderDate,

    -- Customer
    s.CustomerID,
    c.CustomerName,
    c.Segment,

    -- Product
    s.ProductID,
    p.ProductName,
    p.Brand,
    p.Category,
    p.UnitPrice AS BaseUnitPrice,

    -- Geography
    s.LocationID,
    l.City,
    l.State,
    l.GeopoliticalZone,
    l.Country,

    -- Sales execution
    s.SalesAgentID,
    a.SalesAgentName,

    -- Route-to-market
    s.SalesChannel,
    s.OutletTier,

    -- Sales drivers
    s.Quantity,
    s.UnitPrice,
    s.DiscountAmount,

    -- Financial performance
    s.Revenue,
    s.COGS,

    ROUND(s.Revenue - s.COGS, 2) AS GrossProfit,

    CASE
        WHEN s.Revenue = 0 THEN 0
        ELSE ROUND(
            ((s.Revenue - s.COGS) / s.Revenue) * 100,
            2
        )
    END AS [PercentageGrossProfit],

    s.Currency

FROM dbo.RAW_Sales s

LEFT JOIN dbo.Customers c
    ON s.CustomerID = c.CustomerID

LEFT JOIN dbo.RAW_Products p
    ON s.ProductID = p.ProductID

LEFT JOIN dbo.RAW_Locations l
    ON s.LocationID = l.LocationID

LEFT JOIN dbo.Sales_Agents a
    ON s.SalesAgentID = a.SalesAgentID;
GO


--2. Expense Performance

CREATE   VIEW [dbo].[vw_ExpensePerformance]
AS
SELECT
    e.ExpenseID,
    e.ExpenseDate,
    YEAR(e.ExpenseDate) AS ExpenseYear,
    MONTH(e.ExpenseDate) AS ExpenseMonth,
    e.LocationID,
    l.City,
    e.State,
    l.GeopoliticalZone,
    l.Country,
    e.ExpenseCategory,
    e.Amount,
    e.Currency
FROM dbo.Expenses e
LEFT JOIN dbo.RAW_Locations l
    ON e.LocationID = l.LocationID;
GO


--3. Budget Performance

CREATE   VIEW [dbo].[vw_BudgetPerformance]
AS
WITH State_Revenue as (
                select 
                  Year(OrderDate) as Sales_year,
                  Month(OrderDate) as Sales_month,
                  [State],
                  Category,
                  SalesChannel,
                  sum(Revenue) as State_Revenue
               From [dbo].[vw_SalesPerformance]
               Group by 
                  Year(OrderDate),
                  Month(OrderDate),
                  [State],
                 Category,
                 SalesChannel

),
Month_Revenue as (
              select 
                    Sales_year,
                    Sales_Month,
                    sum(State_Revenue) as Monthly_Revenue
                From State_Revenue
                Group by
                Sales_year,
                Sales_Month

)    
SELECT
    b.BudgetID,
    b.Date AS BudgetDate,

    -- Time
    YEAR(b.Date) AS BudgetYear,
    MONTH(b.Date) AS BudgetMonth,
    sr.[state],
    sr.Category,
    SalesChannel,
    ----------allocating budget to state
     b.RevenueBudget * 
                      (
                      sr.State_Revenue * 1.0 / Nullif(mr.Monthly_Revenue, 0)
                      ) as RevenueBudget,
   
    b.VolumeBudget * 
                      (
                      sr.State_Revenue * 1.0 / Nullif(mr.Monthly_Revenue, 0)
                      ) as VolumeBudget,
    b.ExpenseBudget * 
                      (
                      sr.State_Revenue * 1.0 / Nullif(mr.Monthly_Revenue, 0)
                      ) as ExpenseBudget,
    b.Currency

FROM dbo.Budget b
inner join State_Revenue sr
on YEAR(b.date) = sr.Sales_year
and Month(b.Date) = sr.Sales_month
inner join Month_Revenue mr
on sr.Sales_year = mr.Sales_year
and sr.Sales_month = mr.Sales_month


;
GO


--4. Forecast Performance

CREATE  VIEW [dbo].[vw_ForecastPerformance]
AS
SELECT
    f.ForecastID,
    f.[Date] AS ForecastDate,

    -- Time
    YEAR(f.[Date]) AS ForecastYear,
    MONTH(f.[Date]) AS ForecastMonth,

    -- Forecast measures
    f.RevenueForecast,
    f.VolumeForecast,
    f.OPEXForecast,
    f.Currency

FROM dbo.Forecast f;
GO
