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
    -- | Perc.25		|	Perc.50			|	Perc.75
    -- | 326.18			|	441.00			|	572.75


-- What is the average discount value per transaction?
		select round(avg(total_discount),2) as avg_descount
		from(
			select txn_id, sum(discount) as total_discount 
			from(
				SELECT
					txn_id,
					prod_id,
					round(sum((qty*price)*((discount)/100)),2) AS discount 
				from sales
				group by txn_id, prod_id
				order by txn_id asc
			) as discount_per_product
			group by txn_id
		) as discounts_per_transation; -- 62,49


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
		select 
			s.prod_id,
			p.product_name,
			round(sum((s.qty)*(s.price)),2) as rev_bef_desc 
		from sales as s
			join product_details as p on s.prod_id=p.product_id
			group by prod_id, product_name
			order by rev_bef_desc desc
			limit 3;
			-- Prod_id	| 	Product_name					|	Revenue before descount
			-- 2a2353	|	Blue Polo Shirt - Mens			|	217.683
			-- 9ec847	|	Grey Fashion Jacket - Womens	|	209.304
			-- 5d267b	|	White Tee Shirt - Mens			|	152.000


-- What is the total quantity, revenue and discount for each segment?
		select 
			p.segment_name as segment,
			sum(qty) AS quantity,
            round(sum((qty*s.price)*((100-discount)/100)),2) AS revenue,
            round(sum((qty*s.price)*((discount)/100)),2) AS discount
		from sales as s
			join product_details as p on s.prod_id=p.product_id
			group by segment;
			-- segment	|	quantity	|	revenue		|	discount
			-- Jeans	|	11349		|	183006.03	|	25343.97
			-- Shirt	|	11265		|	356548.73	|	49594.27
			-- Socks	|	11217		|	270963.56	|	37013.44
			-- Jacket	|	11385		|	322705.54	|	44277.46


-- What is the top selling product for each segment?
		select 
			p.product_id as product_id,
            p.product_name as product,
			sum(qty) AS sales
		from sales as s
			join product_details as p on s.prod_id=p.product_id
			group by product, product_id
            order by sales desc
            limit 1; 
            -- Grey Fashion Jacket - Womens	3876


-- What is the total quantity, revenue and discount for each category?
		select 
			p.category_name as category,
			sum(qty) AS quantity,
            round(sum((qty*s.price)*((100-discount)/100)),2) AS revenue,
            round(sum((qty*s.price)*((discount)/100)),2) AS discount
		from sales as s
			join product_details as p on s.prod_id=p.product_id
			group by category;
			-- category | quantity	|	revenue		|	discount
			-- Womens	|	22734	|	505711.57	|	69621.43
			-- Mens		|	22482	|	627512.29	|	86607.71


-- What is the top selling product for each category?
		WITH RankedProducts AS (
			SELECT 
				p.product_name AS product,
				p.category_name AS category,
				SUM(s.qty) AS total_sales,
				ROW_NUMBER() OVER (PARTITION BY p.category_name ORDER BY SUM(s.qty) DESC) AS ranking
			FROM 
				sales AS s
				JOIN product_details AS p ON s.prod_id = p.product_id
			GROUP BY 
				p.product_name, p.category_name
		)
		SELECT 
			product,
			category,
			total_sales
		FROM 
			RankedProducts
		WHERE 
			ranking = 1;
		-- Blue Polo Shirt - Mens		| 	Mens	| 	3819
		-- Grey Fashion Jacket - Womens	| 	Womens	| 	3876


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