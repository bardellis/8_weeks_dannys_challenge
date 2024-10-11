## 1. Data Cleansing Steps
In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
*Convert the week_date to a DATE format
*Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
*Add a month_number with the calendar month for each week_date value as the 3rd column
*Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
*Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

| segment |age_band
|--------|-------
| 1 |Young Adults
| 2 |Middle Aged
| 3 or 4 |Retirees


````sql
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
        region VARCHAR(13),
		avg_transaction int,
        platform VARCHAR(7),
        customer_type VARCHAR(8)
	);

INSERT INTO clean_weekly_sales (week_date, segment, sales, transactions, platform, region, customer_type)
	SELECT week_date, segment, sales, transactions, platform, region, customer_type
	FROM weekly_sales;
````

Add day_number, month_number, year_number

````sql
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
    
    UPDATE clean_weekly_sales
	SET date_format = STR_TO_DATE(week_date, '%d/%m/%y');

Mapping segment a age_band

````sql
	UPDATE clean_weekly_sales
	SET age_band =
		CASE
			WHEN segment LIKE '%1' THEN 'Young Adults'  
			WHEN segment LIKE '%2' THEN 'Middle Aged'  
			WHEN segment LIKE '%3' THEN 'Retirees'     
			WHEN segment LIKE '%4' THEN 'Retirees'     
			ELSE 'Unknown'
		END;
````
* Add a new demographic column using the following mapping for the first letter in the segment values:
| segment |age_band
|--------|-------
| 1 |Young Adults
| 2 |Middle Aged
| 3 or 4 |Retirees

````sql
	UPDATE clean_weekly_sales
	SET demographic =
		CASE
			WHEN segment LIKE 'C%' THEN 'Couples'  
			WHEN segment LIKE 'F%' THEN 'Families'  
			ELSE 'Unknown'
		END;

````

*Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
````sql
	select segment, age_band, demographic, count(*)
	FROM clean_weekly_sales
	Where segment = 'null'
	GROUP BY segment, age_band, demographic;
````
*Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

````sql
	UPDATE clean_weekly_sales
	SET avg_transaction = ROUND(sales / transactions, 2);

## 2. Data Exploration
1. What day of the week is used for each week_date value?

````sql
	ALTER TABLE clean_weekly_sales
	ADD COLUMN week_day VARCHAR(20);
	
    UPDATE clean_weekly_sales
	SET week_day = DAYNAME(date_format);
	
    select week_day, count(*)
	from clean_weekly_sales
	group by week_day; -- all dates are mondays 
````

2. What range of week numbers are missing from the dataset?
````sql
		ALTER TABLE clean_weekly_sales
		ADD COLUMN week_number VARCHAR(20);

		UPDATE clean_weekly_sales
		SET week_number = week(date_format);
		select week_number, count(*)
		from clean_weekly_sales
		group by week_number
		order by week_number asc;
````
3. How many total transactions were there for each year in the dataset?
````sql
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



5. What is the total sales for each region for each month?

````sql
		select year_number, count(*)
		from clean_weekly_sales
		group by year_number
		order by year_number asc;
````
		-- 18	5698
		-- 19	5708
		-- 20	5711

  
6. What is the total count of transactions for each platform
````sql
		select platform, count(*) as quantity
		from weekly_sales
		group by platform
		order by quantity asc;
````
		-- Shopify	8549
		-- Retail	8568

7. What is the percentage of sales for Retail vs Shopify for each month?
````sql
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
````
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
   
7. What is the percentage of sales by demographic for each year in the dataset?

````sql
select
			year_number, 
			max(case when region = 'OCEANIA' then percentage_sales else 0 end) as '%OCEANIA',
            max(case when region = 'AFRICA' then percentage_sales else 0 end) as '%AFRICA',
            max(case when region = 'ASIA' then percentage_sales else 0 end) as '%ASIA',
			max(case when region = 'USA' then percentage_sales else 0 end) as '%USA',
            max(case when region = 'CANADA' then percentage_sales else 0 end) as '%CANADA',
            max(case when region = 'SOUTH AMERICA' then percentage_sales else 0 end) as '%S.AMERICA',
            max(case when region = 'EUROPE' then percentage_sales else 0 end) as '%EUROPE'
        from(
        SELECT
			s.year_number,
			s.region,
			SUM(s.sales) AS platform_sales,
			t.total_sales_all_regions,
			ROUND((SUM(s.sales) / t.total_sales_all_regions) * 100, 2) AS percentage_sales
		FROM
			clean_weekly_sales s
		JOIN (
			-- Subquery to get total sales for each month
			SELECT
				year_number,
				SUM(sales) AS total_sales_all_regions
			FROM
				clean_weekly_sales
			GROUP BY
				year_number
		) t ON s.year_number = t.year_number
		GROUP BY
			s.year_number, s.region, t.total_sales_all_regions
		ORDER BY
			s.year_number, s.region) as subquery
            GROUP BY
			year_number 
			ORDER BY
			year_number;
````
            	-- year_number %OCEANIA %AFRICA %ASIA 	%USA 	%CANADA %S.AMIRICA 	%EUROPE
            	-- 18		32.49	24.59	22.25	9.76	6.12	3.02		1.77
		-- 19		32.82	24.44	22.37	9.64	6.14	2.98		1.61
		-- 20		32.89	24.18	22.84	9.53	5.99	2.99		1.58
  
8. Which age_band and demographic values contribute the most to Retail sales?
````sql
			SELECT
				age_band,
				percentage_total_sales
				from(
			SELECT
				age_band,
				platform,
				SUM(sales) AS total_sales,
				ROUND((SUM(sales) / total_retail_sales.total_sales_retail) * 100, 2) AS percentage_total_sales
			FROM
				clean_weekly_sales
			JOIN (
				SELECT
					SUM(sales) AS total_sales_retail
				FROM
					clean_weekly_sales
				WHERE
					platform = 'Retail'
			) AS total_retail_sales ON 1=1  -- Dummy join condition to ensure the subquery is executed once
			WHERE
				platform = 'Retail'
			GROUP BY
				age_band, platform, total_retail_sales.total_sales_retail
			ORDER BY
				total_sales DESC) subquery;
````		
            		-- Unknown		40.52
			-- Retirees		32.80
			-- Middle Aged		15.66
			-- Young Adults		11.03

9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?*/
  ````sql
SELECT
			year_number, 
			round(max(CASE WHEN platform = 'Shopify' THEN avg_transaction_size ELSE 0 END), 2) AS AVG_Shopify,
            round(max(CASE WHEN platform = 'Retail' THEN avg_transaction_size ELSE 0 END), 2) AS AVG_Retail
		FROM(
			select year_number, platform, avg(avg_transaction) as avg_transaction_size
			from clean_weekly_sales
			group by year_number, platform) subquery
            group by year_number;
````
			-- year_number 		AVG.Retail 	AVG.Shopify
			-- 20			40.65		174.89
			-- 19			41.97		177.58
			-- 18			42.91		188.29

## 3. Before & After Analysis
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

Using this analysis approach - answer the following questions:
1.a What is the total sales for the 4 weeks before and after 2020-06-15? 
````sql
			SELECT 'Before' AS period, round(SUM(sales)/1000000,2) AS sales_in_M
			FROM clean_weekly_sales
			WHERE date_format BETWEEN '2020-05-18' AND '2020-06-14'
			UNION ALL
			SELECT 'After' AS period, round(SUM(sales)/1000000,2) AS sales_in_M
			FROM clean_weekly_sales
			WHERE date_format BETWEEN '2020-06-16' AND '2020-07-13';
````
			-- Before 	(millons)	2345.88
			-- After 	(millons) 	2334.91

1.b What is the growth or reduction rate in actual values and percentage of sales?
````sql
			SELECT 
			Sales_in_M_Before,
			Sales_in_M_After,
			(Sales_in_M_After-Sales_in_M_Before) AS growth_reduction_in_M,
			ROUND((Sales_in_M_After-Sales_in_M_Before) / Sales_in_M_Before * 100, 2) AS PCT_sales
			FROM (
				SELECT
					MAX(CASE WHEN period = 'Before' THEN sales_in_M ELSE 0 END) AS Sales_in_M_Before,
					MAX(CASE WHEN period = 'After' THEN sales_in_M ELSE 0 END) AS Sales_in_M_After
				FROM (
					SELECT 'Before' AS period, ROUND(SUM(sales) / 1000000, 2) AS sales_in_M
					FROM clean_weekly_sales
					WHERE date_format BETWEEN '2020-05-18' AND '2020-06-14'
					
					UNION ALL
					
					SELECT 'After' AS period, ROUND(SUM(sales) / 1000000, 2) AS sales_in_M
					FROM clean_weekly_sales
					WHERE date_format BETWEEN '2020-06-16' AND '2020-07-13'
				) AS subquery
			) AS subquery2;
````			
            		| Before(Millons)	|	After(Millons)	|	Growth(Millons)	|	%_increase|
	      		|--------------|------------------|----------------|--------------|
			| 2345.88	|		2334.91		|	-10.97		|	-%0.47|

2. What about the entire 12 weeks before and after?
````sql
			SELECT 
			Sales_in_M_Before,
			Sales_in_M_After,
			(Sales_in_M_After-Sales_in_M_Before) AS growth_reduction_in_M,
			ROUND((Sales_in_M_After-Sales_in_M_Before) / Sales_in_M_Before * 100, 2) AS PCT_sales
			FROM (
				SELECT
					MAX(CASE WHEN period = 'Before' THEN sales_in_M ELSE 0 END) AS Sales_in_M_Before,
					MAX(CASE WHEN period = 'After' THEN sales_in_M ELSE 0 END) AS Sales_in_M_After
				FROM (
					SELECT 'Before' AS period, ROUND(SUM(sales) / 1000000, 2) AS sales_in_M
					FROM clean_weekly_sales
					WHERE date_format BETWEEN '2020-03-23' AND '2020-06-14'
					
					UNION ALL
					
					SELECT 'After' AS period, ROUND(SUM(sales) / 1000000, 2) AS sales_in_M
					FROM clean_weekly_sales
					WHERE date_format BETWEEN '2020-06-15' AND '2020-09-07'
				) AS subquery
			) AS subquery2;
````

   
4. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?*/
````sql
SELECT 
year_number,
Sales_in_M_Before,
Sales_in_M_After,
(Sales_in_M_After-Sales_in_M_Before) AS growth_reduction_in_M,
ROUND((Sales_in_M_After-Sales_in_M_Before) / Sales_in_M_Before * 100, 2) AS PCT_sales
			FROM (
				SELECT
					year_number,
					MAX(CASE WHEN period = 'Before' THEN sales_in_M ELSE 0 END) AS Sales_in_M_Before,
					MAX(CASE WHEN period = 'After' THEN sales_in_M ELSE 0 END) AS Sales_in_M_After
				FROM (
					SELECT 'Before' AS period, year_number, ROUND(SUM(sales) / 1000000, 2) AS sales_in_M
					FROM clean_weekly_sales
					WHERE date_format BETWEEN '2020-03-23' AND '2020-06-14' 
						OR date_format BETWEEN '2019-03-23' AND '2019-06-14' 
						OR date_format BETWEEN '2018-03-23' AND '2018-06-14'
					group by year_number
                    
					UNION ALL
					
					SELECT 'After' AS period, year_number,  ROUND(SUM(sales) / 1000000, 2) AS sales_in_M
					FROM clean_weekly_sales
					WHERE date_format BETWEEN '2020-06-15' AND '2020-09-07' 
						OR date_format BETWEEN '2019-06-15' AND '2019-09-07' 
						OR date_format BETWEEN '2018-06-15' AND '2018-09-07'
                    group by year_number
				) AS subquery
                group by year_number
			) AS subquery2;
````

| Before(Millons)|After(Millons)|Growth(Millons)|%_increase
|--------------|---------------|------------|---
|7126.27	|6973.95	|-152.32	|-2.14
|6883.39	|6862.65	|-20.74		|-0.30
|6396.56	|6500.82	|104.26		|1.63


## 4. Bonus Question
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
* region
* platform
* age_band
* demographic
* customer_type
Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?

````sql
			SELECT 
			platform, age_band, demographic, customer_type,
			sum(case when region = 'OCEANIA' then (Sales_in_M_After-Sales_in_M_Before) else 0 end) as 'OCEANIA',
            sum(case when region = 'ASIA' then (Sales_in_M_After-Sales_in_M_Before) else 0 end) as 'ASIA',
            sum(case when region = 'AFRICA' then (Sales_in_M_After-Sales_in_M_Before) else 0 end) as 'AFRICA',
			sum(case when region = 'USA' then (Sales_in_M_After-Sales_in_M_Before) else 0 end) as 'USA',
            sum(case when region = 'CANADA' then (Sales_in_M_After-Sales_in_M_Before) else 0 end) as 'CANADA',
			sum(case when region = 'SOUTH AMERICA' then (Sales_in_M_After-Sales_in_M_Before) else 0 end) as 'S.AMERICA',
            sum(case when region = 'EUROPE' then (Sales_in_M_After-Sales_in_M_Before) else 0 end) as 'EUROPE',
            sum(Sales_in_M_After-Sales_in_M_Before) as Total_growth
			FROM (
				SELECT
					region, platform, age_band, demographic, customer_type,
					MAX(CASE WHEN period = 'Before' THEN sales_in_M ELSE 0 END) AS Sales_in_M_Before,
					MAX(CASE WHEN period = 'After' THEN sales_in_M ELSE 0 END) AS Sales_in_M_After
				FROM (
					SELECT 'Before' AS period, region, platform, age_band, demographic, customer_type, ROUND(SUM(sales) / 1000000, 2) AS sales_in_M
					FROM clean_weekly_sales
					WHERE date_format BETWEEN '2020-03-23' AND '2020-06-14' 
					group by region, platform, age_band, demographic, customer_type
                    
					UNION ALL
					
					SELECT 'After' AS period, region, platform, age_band, demographic, customer_type, ROUND(SUM(sales) / 1000000, 2) AS sales_in_M
					FROM clean_weekly_sales
					WHERE date_format BETWEEN '2020-06-15' AND '2020-09-07' 
                    group by region, platform, age_band, demographic, customer_type
				) AS subquery
                group by region, platform, age_band, demographic, customer_type
			) AS subquery2
			group by platform, age_band, demographic, customer_type
            order by Total_growth;
````

| platform | age_band |demographic | customer_type | OCEANIA | ASIA | AFRICA | ASIA | CANADA | S.AMERICA | EUROPE | TOTAL
|----------|----------|------------|---------------|---------|------|--------|------|--------|-----------|--------|-------
| Retail |Unknown	|Unknown	|Guest		|-32.85		|-28.43		|-8.23		|-7.11	|-4.20	|-4.47	|2.38	|-82.91
| Retail | Retirees	|Couples	|Existing	|-11.87		|-9.53		|-0.70		|-1.18	|-1.47	|-0.20	|0.95	|-24.00
| Retail |Middle Aged	|Families	|Existing	|-9.97		|-5.99		|-3.89		|-1.83	|-1.03	|-0.03	|0.09	|-22.65


## Conclusion
This case study actually is based off a real life change in Australia retailers where plastic bags were no longer provided for free - as you can expect, 
some customers would have changed their shopping behaviour because of this change!
Analysis which is related to certain key events which can have a significant impact on sales or engagement metrics is always a part of the data analytics menu. 
Learning how to approach these types of problems is a super valuable lesson and hopefully these ideas can help you next time you’re faced with a tough problem like this in the workplace!
Ready for the next 8 Week SQL challenge case study? Click on the banner below to get started with case study #6!*/
