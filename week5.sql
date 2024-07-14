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
		avg_transaction int,
        platform VARCHAR(7),
	);

	INSERT INTO clean_weekly_sales (week_date, segment, sales, transactions, platform)
	SELECT week_date, segment, sales, transactions, platform
	FROM weekly_sales;

-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- Add a new demographic column using the following mapping for the first letter in the segment values:
-- segment demographic-- C Couples-- F Families
	UPDATE clean_weekly_sales
	SET demographic =
		CASE
			WHEN segment LIKE 'C%' THEN 'Couples'  
			WHEN segment LIKE 'F%' THEN 'Families'  
			ELSE 'Unknown'
		END;

-- ------------------------------------------------------------
-- /*Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
	select segment, age_band, demographic, count(*)
	FROM clean_weekly_sales
	Where segment = 'null'
	GROUP BY segment, age_band, demographic;

-- ------------------------------------------------------------
-- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record*/
	UPDATE clean_weekly_sales
	SET avg_transaction = ROUND(sales / transactions, 2);

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

-- ------------------------------------------------------------
-- What day of the week is used for each week_date value?
	ALTER TABLE clean_weekly_sales
	ADD COLUMN week_day VARCHAR(20);
	
    UPDATE clean_weekly_sales
	SET week_day = DAYNAME(date_format);
	
    select week_day, count(*)
	from clean_weekly_sales
	group by week_day; -- all dates are mondays 

-- ------------------------------------------------------------
-- What range of week numbers are missing from the dataset?
		ALTER TABLE clean_weekly_sales
		ADD COLUMN week_number VARCHAR(20);

		UPDATE clean_weekly_sales
		SET week_number = week(date_format);
		select week_number, count(*)
		from clean_weekly_sales
		group by week_number
		order by week_number asc;

-- ------------------------------------------------------------ 
-- What range of week numbers are missing from the dataset?
		WITH RECURSIVE Weeks AS (
			SELECT 1 AS week_num
			UNION ALL
			SELECT week_num + 1
			FROM Weeks
			WHERE week_num < 52)
		SELECT w.week_num AS missing_week_number
		FROM Weeks w
		LEFT JOIN (
			SELECT DISTINCT week_number
			FROM clean_weekly_sales
		) existing_weeks ON w.week_num = existing_weeks.week_number
		WHERE existing_weeks.week_number IS NULL
		ORDER BY missing_week_number;

-- -----------------------------------------------------------------------
-- How many total transactions were there for each year in the dataset?
		select year_number, count(*)
		from clean_weekly_sales
		group by year_number
		order by year_number asc;
		-- 18	5698
		-- 19	5708
		-- 20	5711

-- -------------------------------------------------------------
-- What is the total count of transactions for each platform
		select platform, count(*) as quantity
		from weekly_sales
		group by platform
		order by quantity asc;
		-- Shopify	8549
		-- Retail	8568

-- -----------------------------------------------------------------------
-- What is the percentage of sales for Retail vs Shopify for each month?
        select
			year_number, month_number, 
			max(case when platform = 'Retail' then percentage_sales else 0 end) as '%Retail',
			max(case when platform = 'Shopify' then percentage_sales else 0 end) as '%Shopify'
        from(
        SELECT
			s.month_number,
			s.year_number,
			s.platform,
			SUM(s.sales) AS platform_sales,
			t.total_sales_all_platforms,
			ROUND((SUM(s.sales) / t.total_sales_all_platforms) * 100, 2) AS percentage_sales
		FROM
			clean_weekly_sales s
		JOIN (
			-- Subquery to get total sales for each month
			SELECT
				month_number,
				year_number,
				SUM(sales) AS total_sales_all_platforms
			FROM
				clean_weekly_sales
			GROUP BY
				month_number, year_number
		) t ON s.month_number = t.month_number AND s.year_number = t.year_number
		GROUP BY
			s.month_number, s.year_number, s.platform, t.total_sales_all_platforms
		ORDER BY
			s.year_number, s.month_number, s.platform) as subquery
            GROUP BY
			year_number, month_number 
			ORDER BY
			year_number, month_number;
			-- Y	M	Retail  Shopify
			-- 18	3	97.92	2.08
			-- 18	4	97.93	2.07
			-- 18	5	97.73	2.27
			-- 18	6	97.76	2.24
			-- 18	7	97.75	2.25
			-- 18	8	97.71	2.29
			-- 18	9	97.68	2.32
			-- 19	3	97.71	2.29
			-- 19	4	97.80	2.20
			-- 19	5	97.52	2.48
			-- 19	6	97.42	2.58
			-- 19	7	97.35	2.65
			-- 19	8	97.21	2.79
			-- 19	9	97.09	2.91
			-- 20	3	97.30	2.70
			-- 20	4	96.96	3.04
			-- 20	5	96.71	3.29
			-- 20	6	96.80	3.20
			-- 20	7	96.67	3.33
			-- 20	8	96.51	3.49

-- --------------------------------------------------------------------------------
-- What is the percentage of sales by demographic for each year in the dataset?

-- --------------------------------------------------------------------------------
-- Which age_band and demographic values contribute the most to Retail sales?

-- ------------------------------------------------------------------------------------------------------------------
-- Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 

-- ---------------------------------------------------- 
-- If not - how would you calculate it instead?*/

	USE data_mart;
	select * from clean_weekly_sales;
	select * from weekly_sales;
    
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