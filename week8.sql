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
    -- Do you think these values are valid and why? This happens because the value of month_year is month/year, so we do not know what day the metric was entered
		select 
		i._month, i._year, i.month_year, i.interest_id, i.composition, i.index_value, i.ranking, i.percentile_ranking, i.new_month_year,
		m.interest_name, m.interest_summary, m.created_at, m.last_modified
		from fresh_segments.interest_metrics as i
		left join fresh_segments.interest_map as m on m.id = i.interest_id
		where i.new_month_year < m.created_at;


-- Interest Analysis
-- Which interests have been present in all month_year dates in our dataset?
-- Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
-- If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
-- Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
-- After removing these interests - how many unique interests are there for each month?

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
