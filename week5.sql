/*Case Study Questions
The following case study questions require some data cleaning steps before we start to unpack Danny’s key business questions in more depth.*/

CREATE SCHEMA data_mart;
USE data_mart;

DROP TABLE IF EXISTS data_mart.weekly_sales;

CREATE TABLE data_mart.weekly_sales (
  week_date VARCHAR(7),
  region VARCHAR(13),
  platform VARCHAR(7),
  segment VARCHAR(4),
  customer_type VARCHAR(8),
  transactions INTEGER,
  sales INTEGER
);

-- INSERT INTO data_mart.weekly_sales (week_date, region, platform, segment, customer_type, transactions, sales) VALUES

USE data_mart;

-- 1. Data Cleansing Steps
/*In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
Convert the week_date to a DATE format
Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
Add a month_number with the calendar month for each week_date value as the 3rd column
Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value*/
-- segment age_band
-- 1 Young Adults
-- 2 Middle Aged
-- 3 or 4 Retirees

DROP TABLE IF EXISTS data_mart.clean_weekly_sales;

CREATE TABLE clean_weekly_sales (
    week_date VARCHAR(7) NOT NULL,
    date_format DATE,
    segment VARCHAR(4), -- Asumiendo que segment existe en la tabla original
    day_number INT,
    month_number INT,
    year_number INT,
    age_band VARCHAR(20),
    demographic VARCHAR(20),
    transactions int,
    sales int,
    avg_transaction int
);

INSERT INTO clean_weekly_sales (week_date, segment, sales, transactions)
SELECT week_date, segment, sales, transactions
FROM weekly_sales;

-- Agregar day_number, month_number, year_number
UPDATE clean_weekly_sales
SET 
    day_number = CAST(SUBSTRING_INDEX(week_date, '/', 1) AS UNSIGNED),
    month_number = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(week_date, '/', 2), '/', -1) AS UNSIGNED),
    year_number = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(week_date, '/', -1), '/', 1) AS UNSIGNED);

UPDATE clean_weekly_sales
SET date_format = STR_TO_DATE(CONCAT(year_number, '-', LPAD(month_number, 2, '00'), '-', LPAD(day_number, 2, '00')), '%Y-%m-%d')
WHERE year_number IS NOT NULL AND month_number IS NOT NULL AND day_number IS NOT NULL;

-- Convertir week_date a formato DATE si es necesario
UPDATE clean_weekly_sales
SET date_format = STR_TO_DATE(CONCAT('01/', week_date), '%d/%m/%Y');

-- Mapear segment a age_band
UPDATE clean_weekly_sales
SET age_band =
    CASE
        WHEN segment LIKE '%1' THEN 'Young Adults'  
        WHEN segment LIKE '%2' THEN 'Middle Aged'  
        WHEN segment LIKE '%3' THEN 'Retirees'     
        WHEN segment LIKE '%4' THEN 'Retirees'     
        ELSE 'Unknown'
    END;

-- Add a new demographic column using the following mapping for the first letter in the segment values:
-- segment demographic
-- C Couples
-- F Families

UPDATE clean_weekly_sales
SET demographic =
    CASE
        WHEN segment LIKE 'C%' THEN 'Couples'  
        WHEN segment LIKE 'F%' THEN 'Families'  
        ELSE 'Unknown'
    END;

-- /*Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
select segment, age_band, demographic, count(*)
FROM clean_weekly_sales
Where segment = 'null'
GROUP BY segment, age_band, demographic;

-- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record*/
UPDATE clean_weekly_sales
SET avg_transaction = ROUND(sales / transactions, 2);

select * from clean_weekly_sales;

-- 2. Data Exploration
/*What day of the week is used for each week_date value?
What range of week numbers are missing from the dataset?
How many total transactions were there for each year in the dataset?
What is the total sales for each region for each month?
What is the total count of transactions for each platform
What is the percentage of sales for Retail vs Shopify for each month?
What is the percentage of sales by demographic for each year in the dataset?
Which age_band and demographic values contribute the most to Retail sales?
Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 
If not - how would you calculate it instead?*/

-- 3. Before & After Analysis
/* This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
Using this analysis approach - answer the following questions:
What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
What about the entire 12 weeks before and after?
How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?*/

-- 4. Bonus Question
/*Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
region
platform
age_band
demographic
customer_type
Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?*/

-- Conclusion
/*This case study actually is based off a real life change in Australia retailers where plastic bags were no longer provided for free - as you can expect, 
some customers would have changed their shopping behaviour because of this change!
Analysis which is related to certain key events which can have a significant impact on sales or engagement metrics is always a part of the data analytics menu. 
Learning how to approach these types of problems is a super valuable lesson and hopefully these ideas can help you next time you’re faced with a tough problem like this in the workplace!
Ready for the next 8 Week SQL challenge case study? Click on the banner below to get started with case study #6!*/