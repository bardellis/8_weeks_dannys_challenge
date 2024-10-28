## Case Study Questions
The following questions can be considered key business questions that are required to be answered for the Fresh Segments team.
Most questions can be answered using a single query however some questions are more open ended and require additional thought and not just a coded solution!

## Data Exploration and Cleansing
1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
 ````sql
ALTER TABLE fresh_segments.interest_metrics
ADD COLUMN new_month_year DATE;

UPDATE fresh_segments.interest_metrics
SET new_month_year = STR_TO_DATE(CONCAT('01-', month_year), '%d-%m-%Y');
````



2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?

 ````sql
SELECT new_month_year, COUNT(*) AS records 
FROM fresh_segments.interest_metrics
GROUP BY new_month_year
ORDER BY new_month_year ASC;
````

**Answer**

|new_month_year|records
|-----|---------
|NULL|	1194
|12-2018|	995
|11-2018|	928
|10-2018|	857
|09-2018|	780
|08-2019|	1149
|08-2018|	767
|07-2019|	864
|07-2018|	729
|06-2019|	824
|05-2019|	857
|04-2019|	1099
|03-2019|	1136
|02-2019|	1121
|01-2019|	973



3. What do you think we should do with these null values in fresh_segments.interest_metrics?
Considering the importance of the missing values, I suggest removing them...

````sql
DELETE FROM fresh_segments.interest_metrics
WHERE month_year IS NULL;
````



4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
````sql
SELECT COUNT(*)
FROM (
    SELECT 
        interest_id, 
        m.id, 
        COUNT(*) AS total_count
    FROM 
        fresh_segments.interest_metrics AS i
    LEFT JOIN 
        fresh_segments.interest_map AS m ON m.id = i.interest_id
    WHERE 
        month_year IS NOT NULL
    GROUP BY 
        interest_id, 
        m.id
    ORDER BY 
        interest_id, 
        m.id
) AS subquery
WHERE 
    interest_id <> id;
````

**Answer**
0


````sql 
SELECT COUNT(*) 
FROM (
    SELECT 
        interest_id, 
        m.id, 
        COUNT(*) 
    FROM 
        fresh_segments.interest_map AS m
    LEFT JOIN 
        fresh_segments.interest_metrics AS i ON i.interest_id = m.id
    WHERE 
        month_year IS NOT NULL
    GROUP BY 
        interest_id, 
        m.id
    ORDER BY 
        interest_id, 
        m.id
) AS subquery
WHERE 
    m.id <> interest_id;
````

**Answer**
0


5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table

````sql
SELECT id, COUNT(*) AS record_count
FROM fresh_segments.interest_map
GROUP BY id
ORDER BY record_count DESC;
````

6. What sort of table join should we perform for our analysis and why? 
Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics 
and all columns from fresh_segments.interest_map except from the id column.
7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why? 
188 records/ids belonging to this happens because the value of month_year is month/year, so we do not know what day the metric was entered

````sql
SELECT COUNT(DISTINCT(interest_id)) AS id
FROM (
    SELECT 
        i._month, 
        i._year, 
        i.month_year, 
        i.interest_id, 
        i.composition, 
        i.index_value, 
        i.ranking, 
        i.percentile_ranking, 
        i.new_month_year,
        m.interest_name, 
        m.interest_summary, 
        m.created_at, 
        m.last_modified
    FROM 
        fresh_segments.interest_metrics AS i
    LEFT JOIN 
        fresh_segments.interest_map AS m ON m.id = i.interest_id
    WHERE 
        i.new_month_year < m.created_at
) AS subquery;
````

## Interest Analysis
1. Which interests have been present in all month_year dates in our dataset?
````sql
select interest_id 
from (
	select interest_id, count(distinct(new_month_year)) as total_months
	from fresh_segments.interest_metrics
	group by interest_id
	) as subquery
where total_months = (select count(distinct(new_month_year)) as total_month
from fresh_segments.interest_metrics);
````

2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value? 
````sql
WITH ids_14_months AS 	(
			SELECT interest_id
			FROM 	(
				SELECT interest_id, COUNT(DISTINCT new_month_year) AS total_months
				FROM fresh_segments.interest_metrics
				GROUP BY interest_id
				) AS subquery
				WHERE total_months = 	(
							SELECT COUNT(DISTINCT new_month_year) AS total_month
							FROM fresh_segments.interest_metrics
							)
			),
			all_ids AS 	(
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
		FROM monthly_totals mt
		CROSS JOIN
			total_records tr
		ORDER BY
			month_year asc;
````

3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
````sql
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
````
**Answer**

6359 data points


4. Does this decision make sense to remove these data points from a business perspective?
Use an example where there are all 14 months present to a removed interest example for your arguments 
think about what it means to have less months present from a segment perspective.

````sql
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
		);
````
**Answer**

6359 redords removed
        
**Answer**

From a business perspective, removing interests with incomplete data (e.g., those missing months) makes sense if the goal is to ensure data quality for comprehensive analysis. 
However, it should be considered that when data is removed it may become inconsistent, e.g. the index value column will become inaccurate since interest rates that are not 14 months old will be missing.
In addition, if emerging trends or segment-specific behavior are important, retaining incomplete data may be beneficial despite the challenges, 
If emerging trends or segment-specific behavior are important, however, retaining incomplete data may be beneficial despite the challenges. 
The decision should balance the need for reliable, long-term insights with the potential value of incomplete data. You may choose to:
Remove interests with incomplete data for more accurate and consistent analysis.
Keep interests with partial data for exploratory insights and to capture emerging trends, with the understanding that conclusions might be less reliable.

5. After removing these interests - how many unique interests are there for each month?

````sql		
select new_month_year, count(distinct(interest_id)) as records from fresh_segments.interest_metrics me
join fresh_segments.interest_map as ma on ma.id=me.interest_id
group by new_month_year; 
````        
**Answer**

480 interest_ids
