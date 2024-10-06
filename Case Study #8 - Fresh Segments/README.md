# 🍊 Case Study #8 - Fresh Segments

<img width="400px"  src="https://8weeksqlchallenge.com/images/case-study-designs/8.png" />


## Introduction
Danny created Fresh Segments, a digital marketing agency that helps other businesses analyse trends in online ad click behaviour for their unique customer base.

Clients share their customer lists with the Fresh Segments team who then aggregate interest metrics and generate a single dataset worth of metrics for further analysis.

In particular - the composition and rankings for different interests are provided for each client showing the proportion of their customer list who interacted with online assets related to each interest for each month.

Danny has asked for your assistance to analyse aggregated metrics for an example client and provide some high level insights about the customer list and their interests.

## Available Data
For this case study there is a total of 2 datasets which you will need to use to solve the questions.

## Interest Metrics
This table contains information about aggregated interest metrics for a specific major client of Fresh Segments which makes up a large proportion of their customer base.

Each record in this table represents the performance of a specific interest_id based on the client’s customer base interest measured through clicks and interactions with specific targeted advertising content.

| segment | demographic | 
| ------- | ----------- |
| C | Couples |
| F | Families |

| _month	|_year	|month_year	|interest_id	|composition	|index_value	|ranking	|percentile_ranking
| ------- |------ |---------- |------------ |------------ |------------ |-------- |-------------------- 
| 7	| 2018	| 07-2018	| 32486	| 11.89	| 6.19	| 1	| 99.86
| 7	|2018	|07-2018	|6106	|9.93	|5.31	|2	|99.73
| 7	|2018	|07-2018	|18923	|10.85	|5.29	|3	|99.59
| 7	|2018	|07-2018	|6344	|10.32	|5.1	|4	|99.45
| 7	|2018	|07-2018	|100	|10.77	|5.04	|5	|99.31
| 7	|2018	|07-2018	|69	|10.82	|5.03	|6	|99.18
| 7	|2018	|07-2018	|79	|11.21	|4.97	|7	|99.04
| 7	|2018	|07-2018	|6111	|10.71	|4.83	|8	|98.9
| 7	|2018	|07-2018	|6214	|9.71	|4.83	|8	|98.9
| 7	|2018	|07-2018	|19422	|10.11	|4.81 |10	|98.63

For example - let’s interpret the first row of the interest_metrics table together:

| _month	|_year	|month_year	|interest_id	|composition	|index_value	|ranking	|percentile_ranking
| ------- |------ |---------- |------------ |------------ |------------ |-------- |-------------------- 
| 7	| 2018	| 07-2018	| 32486	| 11.89	| 6.19	| 1	| 99.86

In July 2018, the composition metric is 11.89, meaning that 11.89% of the client’s customer list interacted with the interest interest_id = 32486 - we can link interest_id to a separate mapping table to find the segment name called “Vacation Rental Accommodation Researchers”

The index_value is 6.19, means that the composition value is 6.19x the average composition value for all Fresh Segments clients’ customer for this particular interest in the month of July 2018.

The ranking and percentage_ranking relates to the order of index_value records in each month year.

## Interest Map
This mapping table links the interest_id with their relevant interest information. You will need to join this table onto the previous interest_details table to obtain the interest_name as well as any details about the summary information.

id	interest_name	interest_summary	created_at	last_modified
1	Fitness Enthusiasts	Consumers using fitness tracking apps and websites.	2016-05-26 14:57:59	2018-05-23 11:30:12
2	Gamers	Consumers researching game reviews and cheat codes.	2016-05-26 14:57:59	2018-05-23 11:30:12
3	Car Enthusiasts	Readers of automotive news and car reviews.	2016-05-26 14:57:59	2018-05-23 11:30:12
4	Luxury Retail Researchers	Consumers researching luxury product reviews and gift ideas.	2016-05-26 14:57:59	2018-05-23 11:30:12
5	Brides & Wedding Planners	People researching wedding ideas and vendors.	2016-05-26 14:57:59	2018-05-23 11:30:12
6	Vacation Planners	Consumers reading reviews of vacation destinations and accommodations.	2016-05-26 14:57:59	2018-05-23 11:30:13
7	Motorcycle Enthusiasts	Readers of motorcycle news and reviews.	2016-05-26 14:57:59	2018-05-23 11:30:13
8	Business News Readers	Readers of online business news content.	2016-05-26 14:57:59	2018-05-23 11:30:12
12	Thrift Store Shoppers	Consumers shopping online for clothing at thrift stores and researching locations.	2016-05-26 14:57:59	2018-03-16 13:14:00
13	Advertising Professionals	People who read advertising industry news.	2016-05-26 14:57:59	2018-05-23 11:30:12

## Interactive SQL Instance
You can use the embedded DB Fiddle below to easily access these example datasets - this interactive session has everything you need to start solving these questions using SQL.

You can click on the Edit on DB Fiddle link on the top right hand corner of the embedded session below and it will take you to a fully functional SQL editor where you can write your own queries to analyse the data.

You can feel free to choose any SQL dialect you’d like to use, the existing Fiddle is using PostgreSQL 13 as default.

Serious SQL students will have access to the same relevant schema SQL and example solutions which they can use with their Docker setup from within the course player!


## Case Study Questions
The following questions can be considered key business questions that are required to be answered for the Fresh Segments team.

Most questions can be answered using a single query however some questions are more open ended and require additional thought and not just a coded solution!

## Data Exploration and Cleansing
Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
What do you think we should do with these null values in the fresh_segments.interest_metrics
How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
Summarise the id values in the fresh_segments.interest_map by its total record count in this table
What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?

## Interest Analysis
Which interests have been present in all month_year dates in our dataset?
Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
After removing these interests - how many unique interests are there for each month?

## Segment Analysis
Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
Which 5 interests had the lowest average ranking value?
Which 5 interests had the largest standard deviation in their percentile_ranking value?
For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?

## Index Analysis
The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.

Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.

What is the top 10 interests by the average composition for each month?
For all of these top 10 interests - which interest appears the most often?
What is the average of the average composition for the top 10 interests for each month?
What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?
Required output for question 4:

month_year	interest_name	max_index_composition	3_month_moving_avg	1_month_ago	2_months_ago
2018-09-01	Work Comes First Travelers	8.26	7.61	Las Vegas Trip Planners: 7.21	Las Vegas Trip Planners: 7.36
2018-10-01	Work Comes First Travelers	9.14	8.20	Work Comes First Travelers: 8.26	Las Vegas Trip Planners: 7.21
2018-11-01	Work Comes First Travelers	8.28	8.56	Work Comes First Travelers: 9.14	Work Comes First Travelers: 8.26
2018-12-01	Work Comes First Travelers	8.31	8.58	Work Comes First Travelers: 8.28	Work Comes First Travelers: 9.14
2019-01-01	Work Comes First Travelers	7.66	8.08	Work Comes First Travelers: 8.31	Work Comes First Travelers: 8.28
2019-02-01	Work Comes First Travelers	7.66	7.88	Work Comes First Travelers: 7.66	Work Comes First Travelers: 8.31
2019-03-01	Alabama Trip Planners	6.54	7.29	Work Comes First Travelers: 7.66	Work Comes First Travelers: 7.66
2019-04-01	Solar Energy Researchers	6.28	6.83	Alabama Trip Planners: 6.54	Work Comes First Travelers: 7.66
2019-05-01	Readers of Honduran Content	4.41	5.74	Solar Energy Researchers: 6.28	Alabama Trip Planners: 6.54
2019-06-01	Las Vegas Trip Planners	2.77	4.49	Readers of Honduran Content: 4.41	Solar Energy Researchers: 6.28
2019-07-01	Las Vegas Trip Planners	2.82	3.33	Las Vegas Trip Planners: 2.77	Readers of Honduran Content: 4.41
2019-08-01	Cosmetics and Beauty Shoppers	2.73	2.77	Las Vegas Trip Planners: 2.82	Las Vegas Trip Planners: 2.77

## Conclusion
You have probably come across this concept of customer segments or marketing segments in your everyday life, maybe without you even noticing it!
Segments or audiences are super popular in the digital marketing space and using these interests or traits of customers is a mainstay of massive businesses like Google, Facebook, Instagram, LinkedIn and other social media where there are targeted advertising.
Traditional businesses such as this client for Fresh Segments usually upload their customer emails or matched cookies into various digital marketing systems in order to generate some sort of match, usually using some machine learning methods, to other similar customers with the same interests.
Hopefully this case study helps you think about how these index metrics and compositions can be used for digital marketing!

***
### Solution
[Click here](https://github.com/bardellis/8_weeks_dannys_challenge/blob/main/Case%20Study%20%238%20-%20Fresh%20Segments/solution.md)
