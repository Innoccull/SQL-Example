-- POPULATE DATE DIMENSION

-- Declare the date range you want to seed
DECLARE @StartDate DATE = '2000-01-01';
DECLARE @EndDate DATE = '2030-12-31';

-- Create a temporary table to hold all dates in the range
-- Uses a Recursive CTE which creates a temporary table that is populated with date values until the end date is reached
WITH DateSequence AS (
    SELECT @StartDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateSequence
    WHERE DateValue < @EndDate
)

-- Insert into DimDate
INSERT INTO [CricketDB].[dbo].[DimDate] (date, day_of_week, day_of_month, month, year, quarter, day_name, month_name, is_weekend)
SELECT
    DateValue AS date,                                -- Date
    DATEPART(WEEKDAY, DateValue) AS day_of_week,      -- Day of the week (1=Sunday, 7=Saturday)
    DATEPART(DAY, DateValue) AS day_of_month,         -- Day of the month (1-31)
    DATEPART(MONTH, DateValue) AS month,              -- Month (1-12)
    DATEPART(YEAR, DateValue) AS year,                -- Year
    DATEPART(QUARTER, DateValue) AS quarter,          -- Quarter (1-4)
    DATENAME(WEEKDAY, DateValue) AS day_name,         -- Day name (e.g., 'Monday')
    DATENAME(MONTH, DateValue) AS month_name,         -- Month name (e.g., 'January')
    CASE
        WHEN DATEPART(WEEKDAY, DateValue) IN (1, 7) THEN 1  -- Weekend (1 for weekend, 0 for weekday)
        ELSE 0
    END AS is_weekend
FROM DateSequence
OPTION (MAXRECURSION 0);  -- Remove recursion limit
