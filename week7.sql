-- Interactive SQL Instance
-- You can use the embedded DB Fiddle below to easily access these example datasets - this interactive session has everything you need to start solving these questions using SQL.
-- You can click on the Edit on DB Fiddle link on the top right hand corner of the embedded session below and it will take you to a fully functional SQL 
-- editor where you can write your own queries to analyse the data.
-- You can feel free to choose any SQL dialect you’d like to use, the existing Fiddle is using PostgreSQL 13 as default.
-- Serious SQL students will have access to the same relevant schema SQL and example solutions which they can use with their Docker setup from within the course player!

-- Case Study Questions
-- The following questions can be considered key business questions and metrics that the Balanced Tree team requires for their monthly reports.
-- Each question can be answered using a single query - but as you are writing the SQL to solve each individual problem, keep in mind how you would generate all of these 
-- metrics in a single SQL script which the Balanced Tree team can run each month.


-- High Level Sales Analysis
-- What was the total quantity sold for all products?
		select sum(qty) as quantity from sales; -- 45216
-- What is the total generated revenue for all products before discounts?
		select sum(qty*price) as revenue from sales; -- 1.289.453
-- What was the total discount amount for all products?
		select sum((qty*price)*discount/100) as discount from sales; -- 156.229


-- Transaction Analysis
-- How many unique transactions were there?
		select count(distinct(txn_id)) as transactions from sales; -- 2500


-- What is the average unique products purchased in each transaction?
		select avg(unique_products) as avg_unique_prod 
		from (
			select txn_id as transaction, count(distinct(prod_id)) as unique_products
			from sales
			group by txn_id
		) subquery; -- 6.04


-- What are the 25th, 50th and 75th percentile values for the revenue per transaction?
with RevenuePerTransaction as (
	SELECT 
	RANK() OVER (ORDER BY total_revenue asc) AS ranking,
	txn_id, 
	total_revenue
	FROM(
		select txn_id, sum(revenue) as total_revenue 
		from(
			SELECT 
			txn_id, 
			prod_id,
			round(sum((qty*price)*((100-discount)/100)),2) AS revenue
			FROM sales
			GROUP BY txn_id, prod_id
			order by prod_id) subquery
		group by txn_id
		order by txn_id asc) subquery2
	ORDER BY ranking),
    RankedRevenue AS (
    SELECT total_revenue,
           @rownum := @rownum + 1 AS ranking,
           @total_rows := @rownum
    FROM RevenuePerTransaction, (SELECT @rownum := 0) AS r
    ORDER BY total_revenue
	)
	SELECT
		MIN(CASE WHEN ranking >= CEIL(0.25 * @total_rows) THEN total_revenue END) AS p25,
		MIN(CASE WHEN ranking >= CEIL(0.50 * @total_rows) THEN total_revenue END) AS p50,
		MIN(CASE WHEN ranking >= CEIL(0.75 * @total_rows) THEN total_revenue END) AS p75
	FROM RankedRevenue; 
    -- | P25		|	P50			|	P75
    -- | 326.18		|	441.00		|	572.75


-- What is the average discount value per transaction?
		select round(avg(total_descount),2) as avg_descount
		from(
			select txn_id, sum(descount) as total_descount 
			from(
				SELECT
					txn_id,
					prod_id,
					round(sum((qty*price)*((discount)/100)),2) AS descount 
				from sales
				group by txn_id, prod_id
				order by txn_id asc
			) as descount_per_product
			group by txn_id
		) as descounts_per_transation; -- 62,49


-- What is the percentage split of all transactions for members vs non-members?
		select 
			case when members=1 then 'member' else 'non-member' end as client_type,
			qty_member,
			qty_total, 
            round((qty_member/qty_total),2) as pct 
		from (select 
				members,
				count(*) as qty_member,
					(select count(*) from sales) as qty_total
					from sales
				group by members)
		subquery; 
        -- members		9061	15095	0.60
		-- non-members	6034	15095	0.40


-- What is the average revenue for member transactions and non-member transactions?
		select 
			case when members=1 then 'member' else 'non-member' end as client_type,
            round(avg(revenue),2) as avg_revenue 
		from(
			SELECT
            members,
			txn_id,
            prod_id,
			round(sum((qty*price)*((100-discount)/100)),2) AS revenue
			FROM sales
			GROUP BY members, txn_id, prod_id
			order by txn_id, prod_id)
		subquery
        group by client_type;
		-- non-member	74.54
		-- member		75.43
use balanced_tree;
select * from product_details;
select * from product_hierarchy;
select * from product_prices;
select * from sales;


-- Product Analysis
-- What are the top 3 products by total revenue before discount?
-- What is the total quantity, revenue and discount for each segment?
-- What is the top selling product for each segment?
-- What is the total quantity, revenue and discount for each category?
-- What is the top selling product for each category?
-- What is the percentage split of revenue by product for each segment?
-- What is the percentage split of revenue by segment for each category?
-- What is the percentage split of total revenue by category?
-- What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
-- What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?


-- Reporting Challenge
-- Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.
-- Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.
-- He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).
-- Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)


-- Bonus Challenge
-- Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.
-- Hint: you may want to consider using a recursive CTE to solve this problem!


-- Conclusion
-- Sales, transactions and product exposure is always going to be a main objective for many data analysts and data scientists when working within a company that sells some type of product - Spoiler alert: nearly all companies will sell products!
-- Being able to navigate your way around a product hierarchy and understand the different levels of the structures as well as being able to join these details to sales related datasets will be super valuable for anyone wanting to work within a financial, customer or exploratory analytics capacity.
-- Hopefully these questions helped provide some exposure to the type of analysis we perform daily in these sorts of roles!
-- Ready for the next 8 Week SQL challenge case study? Click on the banner below to get started with case study #8!