
use balanced_tree;

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
		WITH product_revenue AS (
			SELECT 
				p.segment_id,
				p.segment_name AS segment,
				p.product_name AS product,
				s.prod_id,
				ROUND(SUM((qty * s.price) * ((100 - discount) / 100)), 2) AS revenue
			FROM sales AS s
			JOIN product_details AS p ON s.prod_id = p.product_id
			GROUP BY segment_id, segment, product, prod_id
		),
		segment_revenue AS (
			SELECT 
				p.segment_id,
				p.segment_name AS segment,
				ROUND(SUM((qty * s.price) * ((100 - discount) / 100)), 2) AS segment_revenue
			FROM sales AS s
			JOIN product_details AS p ON s.prod_id = p.product_id
			GROUP BY segment_id, segment
		)
		SELECT 
			p.segment,
			p.prod_id,
			p.product,
			p.revenue,
			round((p.revenue/s.segment_revenue),2) as segment_prc
		FROM product_revenue AS p
		JOIN segment_revenue AS s ON p.segment_id = s.segment_id
		order by segment, segment_prc desc;
		-- Segment	|	prod_id	|	product								revenue		pct
		-- Jacket	|	9ec847	|	Grey Fashion Jacket - Womens		183912.12	0.57
		-- Jacket	|	d5e9a6	|	Khaki Suit Jacket - Womens			76052.95	0.24
		-- Jacket	|	72f5d4	|	Indigo Rain Jacket - Womens			62740.47	0.19

		-- Jeans	|	e83aa3	|	Black Straight Jeans - Womens		106407.04	0.58
		-- Jeans	|	c4a632	|	Navy Oversized Jeans - Womens		43992.39	0.24
		-- Jeans	|	e31d39	|	Cream Relaxed Jeans - Womens		32606.60	0.18

		-- Shirt	|	2a2353	|	Blue Polo Shirt - Mens				190863.93	0.54
		-- Shirt	|	5d267b	|	White Tee Shirt - Mens				133622.40	0.37
		-- Shirt	|	c8d436	|	Teal Button Up Shirt - Mens			32062.40	0.09

		-- Socks	|	f084eb	|	Navy Solid Socks - Mens				119861.64	0.44
		-- Socks	|	2feb6b	|	Pink Fluro Polkadot Socks - Mens	96377.73	0.36
		-- Socks	|	b9a74d	|	White Striped Socks - Mens			54724.19	0.20


-- What is the percentage split of revenue by segment for each category?
		WITH segment_revenue AS (
			SELECT 
				p.segment_id as segment_id,
                p.segment_name AS segment,
                p.category_id as category_id,
				ROUND(SUM((qty * s.price) * ((100 - discount) / 100)), 2) AS segment_revenue
			FROM sales AS s
			JOIN product_details AS p ON s.prod_id = p.product_id
			GROUP BY segment_id, segment, category_id
		),
		category_revenue AS (
			SELECT 
				p.category_id as category_id,
				p.category_name AS category,
				ROUND(SUM((qty * s.price) * ((100 - discount) / 100)), 2) AS category_revenue
			FROM sales AS s
			JOIN product_details AS p ON s.prod_id = p.product_id
			GROUP BY category_id, category
		)
		SELECT 
			c.category,
            s.segment,
			s.segment_revenue,
            round((s.segment_revenue/c.category_revenue),2) as category_prc
		FROM segment_revenue AS s
		JOIN category_revenue AS c ON s.category_id = c.category_id
		order by segment, category_prc desc;
		-- Category	|	Segment	|	revenue		|	pct
		-- Womens	|	Jacket	|	322705.54	|	0.64
		-- Womens	|	Jeans	|	183006.03	|	0.36
		-- Mens		|	Shirt	|	356548.73	|	0.57
		-- Mens		|	Socks	|	270963.56	|	0.43


-- What is the percentage split of total revenue by category?
			select 
            category, 
            category_revenue, 
            (category_revenue/revenue) as prc_revenue 
            from (SELECT 
					p.category_id as category_id,
					p.category_name AS category,
					ROUND(SUM((qty * s.price) * ((100 - discount) / 100)), 2) AS category_revenue,
					(select ROUND(SUM((qty * price) * ((100 - discount) / 100)), 2) AS revenue from sales) as revenue
				FROM sales AS s
				JOIN product_details AS p ON s.prod_id = p.product_id
				GROUP BY category_id, category) 
			subquery;
			-- category	|	revenue		|	prc_total
			-- Womens	|	505711.57	|	0.446259
			-- Mens		|	627512.29	|	0.553741


-- What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
		SELECT
			s.prod_id,
			p.product_name AS product,
			COUNT(DISTINCT s.txn_id) AS txn_count,
			ROUND(
				COUNT(DISTINCT s.txn_id) * 1.0 / (
					SELECT COUNT(DISTINCT txn_id)
					FROM sales
				), 2
			) AS penetration
		FROM sales AS s
		JOIN product_details AS p ON s.prod_id = p.product_id
		GROUP BY s.prod_id, p.product_name
		ORDER BY penetration DESC;
		-- c4a632	Navy Oversized Jeans - Womens		1274	0.51
		-- 5d267b	White Tee Shirt - Mens				1268	0.51
		-- 2a2353	Blue Polo Shirt - Mens				1268	0.51
		-- f084eb	Navy Solid Socks - Mens				1281	0.51
		-- 9ec847	Grey Fashion Jacket - Womens		1275	0.51
		-- b9a74d	White Striped Socks - Mens			1243	0.50
		-- 2feb6b	Pink Fluro Polkadot Socks - Mens	1258	0.50
		-- e31d39	Cream Relaxed Jeans - Womens		1243	0.50
		-- 72f5d4	Indigo Rain Jacket - Womens			1250	0.50
		-- e83aa3	Black Straight Jeans - Womens		1246	0.50
		-- d5e9a6	Khaki Suit Jacket - Womens			1247	0.50
		-- c8d436	Teal Button Up Shirt - Mens			1242	0.50


-- What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
-- Using a Common Table Expression (CTE) to filter transactions with at least three distinct products
		WITH RelevantTransactions AS (
			SELECT txn_id
			FROM sales
			GROUP BY txn_id
			HAVING COUNT(DISTINCT prod_id) >= 3
		)
		-- Cross-joining to find all combinations of three products within the filtered transactions
		, ProductCombinations AS (
			SELECT a.txn_id, a.prod_id AS prod1, b.prod_id AS prod2, c.prod_id AS prod3
			FROM sales a
			JOIN sales b ON a.txn_id = b.txn_id AND a.prod_id < b.prod_id
			JOIN sales c ON a.txn_id = c.txn_id AND b.prod_id < c.prod_id
			WHERE a.txn_id IN (SELECT txn_id FROM RelevantTransactions)
		)
		-- Counting and finding the most common combination
		SELECT prod1, prod2, prod3, COUNT(*) AS occurrence_count
		FROM ProductCombinations
		GROUP BY prod1, prod2, prod3
		ORDER BY occurrence_count DESC
		LIMIT 1;
		-- prod1	|	prod2	|	prod3	|	ocurrences
        -- 5d267b	|	9ec847	|	c8d436	|	352


-- Reporting Challenge
-- Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.
-- Enable Event Scheduler
		SET GLOBAL event_scheduler = ON;
		DROP EVENT IF EXISTS calculate_monthly_report;
		SHOW PROCEDURE STATUS WHERE Name = 'calculate_monthly_report';
		DROP PROCEDURE IF EXISTS calculate_monthly_report;
		CALL calculate_monthly_report;

		DELIMITER //
		CREATE PROCEDURE calculate_monthly_report()
		BEGIN
			DECLARE start_date DATE DEFAULT '2024-07-01';
			DECLARE end_date DATE DEFAULT '2024-07-31';

			-- Total Quantity Sold
			SELECT 
				'Total Quantity Sold' AS metric_name,
				SUM(qty) AS quantity
			FROM sales
			WHERE DATE(start_txn_time) BETWEEN start_date AND end_date;

			-- Total Revenue before Discounts
			SELECT 
				'Total Revenue before Discounts' AS metric_name,
				SUM(qty * price) AS revenue
			FROM sales
			WHERE DATE(start_txn_time) BETWEEN start_date AND end_date;

			-- Total Discount Amount
			SELECT 
				'Total Discount Amount' AS metric_name,
				SUM((qty * price) * discount / 100) AS discount
			FROM sales
			WHERE DATE(start_txn_time) BETWEEN start_date AND end_date;

			-- Unique Transactions
			SELECT 
				'Unique Transactions' AS metric_name,
				COUNT(DISTINCT txn_id) AS transactions
			FROM sales
			WHERE DATE(start_txn_time) BETWEEN start_date AND end_date;

			-- Average Unique Products Purchased per Transaction
			SELECT 
				'Average Unique Products Purchased' AS metric_name,
				AVG(unique_products) AS avg_unique_prod
			FROM (
				SELECT txn_id, COUNT(DISTINCT prod_id) AS unique_products
				FROM sales
				WHERE DATE(start_txn_time) BETWEEN start_date AND end_date
				GROUP BY txn_id
			) AS subquery;

			-- Percentile Values for Revenue per Transaction
			WITH RevenuePerTransaction AS (
				SELECT 
					txn_id,
					ROUND(SUM((qty * price) * ((100 - discount) / 100)), 2) AS total_revenue
				FROM sales
				WHERE DATE(start_txn_time) BETWEEN start_date AND end_date
				GROUP BY txn_id
			),
			RankedRevenue AS (
				SELECT 
					total_revenue,
					ROW_NUMBER() OVER (ORDER BY total_revenue) AS ranking,
					COUNT(*) OVER () AS total_rows
				FROM RevenuePerTransaction
			)
			SELECT 
				'25th, 50th and 75th Percentile Values for Revenue per Transaction' AS metric_name,
				MIN(CASE WHEN ranking >= CEIL(0.25 * total_rows) THEN total_revenue END) AS p25,
				MIN(CASE WHEN ranking >= CEIL(0.50 * total_rows) THEN total_revenue END) AS p50,
				MIN(CASE WHEN ranking >= CEIL(0.75 * total_rows) THEN total_revenue END) AS p75
			FROM RankedRevenue;

			-- Average Discount Value per Transaction
			SELECT 
				'Average Discount Value per Transaction' AS metric_name,
				ROUND(AVG(total_discount), 2) AS avg_discount
			FROM (
				SELECT txn_id, SUM((qty * price) * (discount / 100)) AS total_discount
				FROM sales
				WHERE DATE(start_txn_time) BETWEEN start_date AND end_date
				GROUP BY txn_id
			) AS discount_per_transaction;

			-- Percentage Split of Transactions for Members vs Non-Members
			SELECT 
				'Percentage Split of Transactions for Members vs Non-Members' AS metric_name,
				CASE WHEN members = 1 THEN 'Member' ELSE 'Non-Member' END AS client_type,
				COUNT(*) AS qty_member,
				(SELECT COUNT(*) FROM sales WHERE DATE(start_txn_time) BETWEEN start_date AND end_date) AS qty_total,
				ROUND(COUNT(*) / (SELECT COUNT(*) FROM sales WHERE DATE(start_txn_time) BETWEEN start_date AND end_date), 2) AS pct
			FROM sales
			WHERE DATE(start_txn_time) BETWEEN start_date AND end_date
			GROUP BY members;

			-- Top Selling Product for Each Segment
			SELECT
				'Top Selling Product for Segment' AS metric_name,
				p.product_id AS product_id,
				p.product_name AS product,
				SUM(qty) AS sales
			FROM sales AS s
			JOIN product_details AS p ON s.prod_id = p.product_id
			WHERE DATE(start_txn_time) BETWEEN start_date AND end_date
			GROUP BY product_id, product
			ORDER BY sales DESC
			LIMIT 1;

			-- Total Quantity, Revenue, and Discount for Each Category
			SELECT 
				'Totals for Category' AS metric_name,
				p.category_name AS category,
				SUM(qty) AS quantity,
				ROUND(SUM((qty * s.price) * ((100 - discount) / 100)), 2) AS revenue,
				ROUND(SUM((qty * s.price) * (discount / 100)), 2) AS discount
			FROM sales AS s
			JOIN product_details AS p ON s.prod_id = p.product_id
			WHERE DATE(start_txn_time) BETWEEN start_date AND end_date
			GROUP BY category_name;

			-- Top Selling Product for Each Category
			WITH RankedProducts AS (
				SELECT 
					p.product_name AS product,
					p.category_name AS category,
					SUM(s.qty) AS total_sales,
					ROW_NUMBER() OVER (PARTITION BY p.category_name ORDER BY SUM(s.qty) DESC) AS ranking
				FROM sales AS s
				JOIN product_details AS p ON s.prod_id = p.product_id
				WHERE DATE(start_txn_time) BETWEEN start_date AND end_date
				GROUP BY p.product_name, p.category_name
			)
			SELECT 
				'Top Selling Product for Category' AS metric_name,
				product,
				category,
				total_sales
			FROM RankedProducts
			WHERE ranking = 1;

			-- Percentage Split of Revenue by Product for Each Segment
			WITH product_revenue AS (
				SELECT 
					p.segment_id,
					p.segment_name AS segment,
					p.product_name AS product,
					ROUND(SUM((qty * s.price) * ((100 - discount) / 100)), 2) AS revenue
				FROM sales AS s
				JOIN product_details AS p ON s.prod_id = p.product_id
				WHERE DATE(start_txn_time) BETWEEN start_date AND end_date
				GROUP BY segment_id, segment, product
			),
			segment_revenue AS (
				SELECT 
					p.segment_id,
					p.segment_name AS segment,
					ROUND(SUM((qty * s.price) * ((100 - discount) / 100)), 2) AS segment_revenue
				FROM sales AS s
				JOIN product_details AS p ON s.prod_id = p.product_id
				WHERE DATE(start_txn_time) BETWEEN start_date AND end_date
				GROUP BY segment_id, segment
			)
			SELECT 
				'Percentage by Product for Segment' AS metric_name,
				p.segment,
				p.product,
				p.revenue,
				ROUND(p.revenue / s.segment_revenue, 2) AS segment_prc
			FROM product_revenue AS p
			JOIN segment_revenue AS s ON p.segment_id = s.segment_id
			ORDER BY segment, segment_prc DESC;

			-- Percentage Split of Revenue by Segment for Each Category
			WITH segment_revenue AS (
				SELECT 
					p.segment_id,
					p.segment_name AS segment,
					p.category_id AS category_id,
					ROUND(SUM((qty * s.price) * ((100 - discount) / 100)), 2) AS segment_revenue
				FROM sales AS s
				JOIN product_details AS p ON s.prod_id = p.product_id
				WHERE DATE(start_txn_time) BETWEEN start_date AND end_date
				GROUP BY segment_id, segment, category_id
			),
			category_revenue AS (
				SELECT 
					p.category_id,
					p.category_name AS category,
					ROUND(SUM((qty * s.price) * ((100 - discount) / 100)), 2) AS category_revenue
				FROM sales AS s
				JOIN product_details AS p ON s.prod_id = p.product_id
				WHERE DATE(start_txn_time) BETWEEN start_date AND end_date
				GROUP BY category_id, category
			)
			SELECT 
				'Percentage by Segment for Category' AS metric_name,
				c.category,
				s.segment,
				s.segment_revenue,
				ROUND(s.segment_revenue / c.category_revenue, 2) AS category_prc
			FROM segment_revenue AS s
			JOIN category_revenue AS c ON s.category_id = c.category_id
			ORDER BY segment, category_prc DESC;

			-- Percentage Split of Total Revenue by Category
			SELECT 
				'Percentage Split of Total Revenue by Category' AS metric_name,
				category,
				category_revenue,
				ROUND(category_revenue / revenue, 2) AS prc_revenue
			FROM (
				SELECT 
					p.category_id AS category_id,
					p.category_name AS category,
					ROUND(SUM((qty * s.price) * ((100 - discount) / 100)), 2) AS category_revenue,
					(SELECT ROUND(SUM((qty * price) * ((100 - discount) / 100)), 2) FROM sales) AS revenue
				FROM sales AS s
				JOIN product_details AS p ON s.prod_id = p.product_id
				WHERE DATE(start_txn_time) BETWEEN start_date AND end_date
				GROUP BY category_id, category
			) AS subquery;

			-- Penetration for Each Product
			SELECT 
				'Penetration for Each Product' AS metric_name,
				product_name AS product,
				ROUND(SUM(qty) / (SELECT SUM(qty) FROM sales WHERE DATE(start_txn_time) BETWEEN start_date AND end_date), 2) AS penetration
			FROM sales AS s
			JOIN product_details AS p ON s.prod_id = p.product_id
			WHERE DATE(start_txn_time) BETWEEN start_date AND end_date
			GROUP BY product_name;
			
		END //
		DELIMITER ;

-- Bonus Challenge
-- Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.
-- Hint: you may want to consider using a recursive CTE to solve this problem!


-- Conclusion
-- Sales, transactions and product exposure is always going to be a main objective for many data analysts and data scientists when working within a company that sells some type of product - Spoiler alert: nearly all companies will sell products!
-- Being able to navigate your way around a product hierarchy and understand the different levels of the structures as well as being able to join these details to sales related datasets will be super valuable for anyone wanting to work within a financial, customer or exploratory analytics capacity.
-- Hopefully these questions helped provide some exposure to the type of analysis we perform daily in these sorts of roles!
-- Ready for the next 8 Week SQL challenge case study? Click on the banner below to get started with case study #8!
