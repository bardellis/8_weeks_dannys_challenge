## DROP TABLE IF EXISTS data_mart.clean_weekly_sales;
CREATE TABLE data_mart.clean_weekly_sales AS
SELECT
  TO_DATE(week_date, 'dd/mm/yy') AS week_date,
  DATE_PART('week', TO_DATE(week_date, 'dd/mm/yy')) AS week_number,
  DATE_PART('month', TO_DATE(week_date, 'dd/mm/yy')) AS month_number,
  DATE_PART('year', TO_DATE(week_date, 'dd/mm/yy')) AS calendar_year,
  region,
  platform,
  CASE
    WHEN segment = 'null' THEN 'Unknown'
    ELSE segment
  END AS segment,
