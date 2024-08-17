
DROP TABLE IF EXISTS data_mart.clean_weekly_sales;
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
  CASE
    WHEN RIGHT(segment, 1) = '1' THEN 'Young Adults'
    WHEN RIGHT(segment, 1) = '2' THEN 'Middle Aged'
    WHEN RIGHT(segment, 1) IN ('3', '4') THEN 'Retirees'
    ELSE 'Unknown'
  END AS age_band,
  CASE
    WHEN LEFT(segment, 1) = 'C' THEN 'Couples'
    WHEN LEFT(segment, 1) = 'F' THEN 'Families'
    ELSE 'Unknown'
  END AS demographic,
  customer_type,
  transactions,
  sales,
  ROUND(
    sales :: NUMERIC / transactions,
    2
  ) AS avg_transaction
FROM
  data_mart.weekly_sales;
SELECT
  *
FROM
  data_mart.clean_weekly_sales
