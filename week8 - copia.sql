	CREATE SCHEMA fresh_segments;

	CREATE TABLE fresh_segments.interest_map (
	  id INTEGER,
	  interest_name TEXT,
	  interest_summary TEXT,
	  created_at TIMESTAMP,
	  last_modified TIMESTAMP
	);
	  
	-- update the null values
	UPDATE fresh_segments.interest_map
	SET interest_summary = NULL
	WHERE interest_summary = '';

	CREATE TABLE fresh_segments.interest_metrics (
	  _month VARCHAR(4),
	  _year VARCHAR(4),
	  month_year VARCHAR(7),
	  interest_id VARCHAR(5),
	  composition FLOAT,
	  index_value FLOAT,
	  ranking INTEGER,
	  percentile_ranking FLOAT
	);
	  
	-- update NULL values
	-- Update to handle 'NULL' as NULL values and cast to integers where necessary

	UPDATE fresh_segments.interest_metrics
	SET _month = CASE 
		WHEN _month = 'NULL' THEN NULL
		ELSE CAST(_month AS UNSIGNED)
	END;

	UPDATE fresh_segments.interest_metrics
	SET _year = CASE 
		WHEN _year = 'NULL' THEN NULL
		ELSE CAST(_year AS UNSIGNED)
	END;

	UPDATE fresh_segments.interest_metrics
	SET month_year = NULL
	WHERE month_year = 'NULL';

	UPDATE fresh_segments.interest_metrics
	SET interest_id = NULL
	WHERE interest_id = 'NULL';

	use fresh_segments;
	select * from interest_metrics
	where month_year is NULL
	order by new_month_year desc;

-- Case Study Questions
-- The following questions can be considered key business questions that are required to be answered for the Fresh Segments team.
-- Most questions can be answered using a single query however some questions are more open ended and require additional thought and not just a coded solution!

	-- Data Exploration and Cleansing
	-- Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
	ALTER TABLE fresh_segments.interest_metrics
	ADD COLUMN new_month_year DATE;
	UPDATE fresh_segments.interest_metrics
	SET new_month_year = STR_TO_DATE(CONCAT('01-', month_year), '%d-%m-%Y');


	-- What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
	select new_month_year, count(*) as records 
	from fresh_segments.interest_metrics
	group by new_month_year
	order by new_month_year asc;
    
    -- original table
	select month_year, count(*) as records 
	from fresh_segments.interest_metrics_0
	group by month_year
	order by month_year asc;


	-- What do you think we should do with these null values in fresh_segments.interest_metrics?
	-- Considering the importance of the missing values, I suggest removing them.
	DELETE FROM fresh_segments.interest_metrics
	WHERE month_year IS NULL;


	-- How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
	select count(*) from 
		(select interest_id, m.id, count(*) from fresh_segments.interest_metrics as i
		left join fresh_segments.interest_map as m on m.id = i.interest_id
		where month_year IS not NULL
		group by interest_id, m.id
		order by interest_id, m.id
        ) subquery
		where interest_id <> id; -- 0 
    
    select count(*) from
		(select interest_id, m.id, count(*) 
		from fresh_segments.interest_map as m
		left join fresh_segments.interest_metrics as i on i.interest_id = m.id
		where month_year IS not NULL
		group by interest_id, id
		order by interest_id, id
        ) subquery
		where id <> interest_id; -- 0 


	-- Summarise the id values in the fresh_segments.interest_map by its total record count in this table
	SELECT id, COUNT(*) AS record_count
	FROM fresh_segments.interest_map
	GROUP BY id
	ORDER BY record_count DESC;


	-- What sort of table join should we perform for our analysis and why? 
	-- Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics 
	-- and all columns from fresh_segments.interest_map except from the id column.
	-- Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? 
    -- Do you think these values are valid and why? 
    
		-- 188 records/ids belonging to this happens because the value of month_year is month/year, so we do not know what day the metric was entered
		select count(distinct(interest_id)) as id 
			from (select 
			i._month, i._year, i.month_year, i.interest_id, i.composition, i.index_value, i.ranking, i.percentile_ranking, i.new_month_year,
			m.interest_name, m.interest_summary, m.created_at, m.last_modified
			from fresh_segments.interest_metrics as i
			left join fresh_segments.interest_map as m on m.id = i.interest_id
			where i.new_month_year < m.created_at) subquery;


		-- Interest Analysis
		-- Which interests have been present in all month_year dates in our dataset?
			select interest_id 
			from (
				select interest_id, count(distinct(new_month_year)) as total_months
				from fresh_segments.interest_metrics
				group by interest_id
			) as subquery
			where total_months = (select count(distinct(new_month_year)) as total_month
			from fresh_segments.interest_metrics);


		-- Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months 
        -- which total_months value passes the 90% cumulative percentage value? 
        WITH ids_14_months AS (
			SELECT interest_id
			FROM (
				SELECT interest_id, COUNT(DISTINCT new_month_year) AS total_months
				FROM fresh_segments.interest_metrics
				GROUP BY interest_id
			) AS subquery
			WHERE total_months = (
				SELECT COUNT(DISTINCT new_month_year) AS total_month
				FROM fresh_segments.interest_metrics
			)
		),
		all_ids AS (
			SELECT new_month_year, interest_id, COUNT(*) AS records
			FROM fresh_segments.interest_metrics
			GROUP BY new_month_year, interest_id
		),
		monthly_totals AS (
			SELECT new_month_year, SUM(records) AS total_records
			FROM all_ids
			JOIN ids_14_months ON all_ids.interest_id = ids_14_months.interest_id
			GROUP BY new_month_year
		),
		total_records AS (
			SELECT SUM(records) AS grand_total
			FROM all_ids
			JOIN ids_14_months ON all_ids.interest_id = ids_14_months.interest_id
		)
		SELECT
			date_format(mt.new_month_year, '%Y-%m') AS month_year,
			mt.total_records AS records,
			tr.grand_total AS total,
			(mt.total_records / tr.grand_total) * 100 AS percentage,
			SUM((mt.total_records / tr.grand_total) * 100) OVER (ORDER BY mt.new_month_year) AS cumulative_percentage
		FROM
			monthly_totals mt
		CROSS JOIN
			total_records tr
		ORDER BY
			month_year asc;
		-- 2019-07


		-- If we were to remove all interest_id values which are lower than the total_months value we found in the previous question 
		-- how many total data points would we be removing? 
        SELECT SUM(total_months) AS data_points
		FROM (
			-- Subquery to count distinct months per interest_id
			SELECT interest_id, total_months
			FROM (
				SELECT interest_id, COUNT(DISTINCT new_month_year) AS total_months
				FROM fresh_segments.interest_metrics
				GROUP BY interest_id
			) AS subquery
			-- Filter for interest_ids where the total_months is less than the total distinct months
			WHERE total_months < (
				SELECT COUNT(DISTINCT new_month_year) AS total_month
				FROM fresh_segments.interest_metrics
			)
		) AS subquery2;
		-- 6359 data points


		-- Does this decision make sense to remove these data points from a business perspective?
		-- Use an example where there are all 14 months present to a removed interest example for your arguments 
		-- think about what it means to have less months present from a segment perspective.

		DELETE FROM fresh_segments.interest_metrics
		WHERE interest_id IN (
			SELECT 
				interest_id
			FROM (
				SELECT 
					interest_id, 
					COUNT(DISTINCT new_month_year) AS total_months
				FROM 
					fresh_segments.interest_metrics
				GROUP BY 
					interest_id
			) AS subquery
			WHERE total_months < 14
		); 	-- 6359 redords removed
        
			-- ANSWER: From a business perspective, removing interests with incomplete data (e.g., those missing months) makes sense if the goal is to ensure data quality for comprehensive analysis. 
			-- However, it should be considered that when data is removed it may become inconsistent, e.g. the index value column will become inaccurate since interest rates that are not 14 months old will be missing.
			-- In addition, if emerging trends or segment-specific behavior are important, retaining incomplete data may be beneficial despite the challenges, 
			-- If emerging trends or segment-specific behavior are important, however, retaining incomplete data may be beneficial despite the challenges. 
			-- The decision should balance the need for reliable, long-term insights with the potential value of incomplete data. You may choose to:
				-- Remove interests with incomplete data for more accurate and consistent analysis.
				-- Keep interests with partial data for exploratory insights and to capture emerging trends, with the understanding that conclusions might be less reliable.


		-- After removing these interests - how many unique interests are there for each month? 
		select new_month_year, count(distinct(interest_id)) as records from fresh_segments.interest_metrics me
		join fresh_segments.interest_map as ma on ma.id=me.interest_id
		group by new_month_year; 
        -- 480 interests

        
-- Segment Analysis
-- Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? 
-- Only use the maximum composition value for each interest but you must keep the corresponding month_year

-- Which 5 interests had the lowest average ranking value?
-- Which 5 interests had the largest standard deviation in their percentile_ranking value?
-- For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
-- How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?

-- Index Analysis
-- The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.
-- Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.
-- For all of these top 10 interests - which interest appears the most often?
-- What is the average of the average composition for the top 10 interests for each month?
-- What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
-- Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?
