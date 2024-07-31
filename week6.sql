use clique_bait;
select * from page_hierarchy;

-- Introduction
-- Clique Bait is not like your regular online seafood store - the founder and CEO Danny, was also a part of a digital data analytics team and wanted to expand his knowledge into the seafood industry!
-- In this case study - you are required to support Danny’s vision and analyse his dataset and come up with creative solutions to calculate funnel fallout rates for the Clique Bait online store.

-- Available Data
-- For this case study there is a total of 5 datasets which you will need to combine to solve all of the questions.

-- 2. Digital Analysis
-- Using the available datasets - answer the following questions using a single query for each one:
-- How many users are there?
		SELECT COUNT(DISTINCT user_id) AS users
		FROM users;
        -- 500

-- How many cookies does each user have on average?
		SELECT ROUND(AVG(cookies), 2) AS avg_cookies
		FROM (
			SELECT user_id, COUNT(cookie_id) AS cookies
			FROM users
			GROUP BY user_id
			) AS subquery;
			-- 3.56

-- What is the unique number of visits by all users per month?
		ALTER TABLE events
		ADD COLUMN month_number INT;
		
        UPDATE events
		SET month_number = MONTH(event_time);		
        
        SELECT
			subquery.month_number,
			COUNT(subquery.visit_id) AS visits
		FROM (
			SELECT
				e.visit_id,
				e.cookie_id AS event_cookie_id,
				e.month_number,
				u.user_id
			FROM events AS e
			JOIN users AS u ON e.cookie_id = u.cookie_id
		) AS subquery
		GROUP BY subquery.month_number
		order by month_number asc;
		-- Month 	|	Visits
		-- 1		|	8112
		-- 2		|	13645
		-- 3		|	8255
		-- 4		|	2311
		-- 5		|	411


-- What is the number of events for each event type?
		select event_name, count(visits) as visits
		from (select e.visit_id as visits, i.event_name as event_name from events as e
		join event_identifier as i on i.event_type=e.event_type) subquery
		group by i.event_name;
		-- Event_name 		|	Visits
		-- Page View		|	20928
		-- Add to Cart		|	8451
		-- Purchase		|	1777
		-- Ad Impression	|	876
		-- Ad Click		|	702


-- What is the percentage of visits which have a purchase event?
        SELECT 
			e.event_name, 
			COUNT(*) AS visits, 
			ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM events), 2) AS percentage
		FROM 
			events AS e
		JOIN 
			event_identifier AS i ON i.event_type = e.event_type
		GROUP BY 
			e.event_name;
		-- events			|	visits	|	%
		-- Page View			|	20928	|	0.64
		-- Add to Cart			|	8451	|	0.26
		-- Purchase			|	1777	|	0.05
		-- Ad Impression		|	876	|	0.03
		-- Ad Click			|	702	|	0.02
		

-- What is the percentage of visits which view the checkout page but do not have a purchase event?
		WITH event_counts AS (
			SELECT
				e.visit_id,
				SUM(CASE WHEN i.event_name = 'Page View' THEN 1 ELSE 0 END) AS Page_View,
				SUM(CASE WHEN i.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS Add_to_Cart,
				SUM(CASE WHEN i.event_name = 'Purchase' THEN 1 ELSE 0 END) AS Purchase,
				SUM(CASE WHEN i.event_name = 'Ad Impression' THEN 1 ELSE 0 END) AS Ad_Impression,
				SUM(CASE WHEN i.event_name = 'Ad Click' THEN 1 ELSE 0 END) AS Ad_Click,
				SUM(CASE WHEN p.page_name = 'Checkout' THEN 1 ELSE 0 END) AS Checkout
			FROM events AS e
			JOIN event_identifier AS i ON i.event_type = e.event_type
			JOIN page_hierarchy AS p ON e.page_id = p.page_id
			GROUP BY e.visit_id
		),
		event_conditions AS (
			SELECT
				ec.visit_id,
				CASE
					WHEN ec.Checkout = 1 AND ec.Purchase = 0 THEN 'checkout-no_purchase'
					ELSE 'others'
				END AS event_condition
			FROM event_counts AS ec
		)
		SELECT
			event_condition,
			COUNT(*) AS visits,
			ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_visits
		FROM event_conditions
		GROUP BY event_condition
		ORDER BY event_condition;
		-- event_condition		|	visits	|	percentage
		-- checkout-no_purchase		|	326	|	9.15
		-- others			|	3238	|	90.85  

            
-- What are the top 3 pages by number of views?
		select page_name, count(*) as visits
		from (
			select p.page_name, e.visit_id from events as e
			join event_identifier as i on e.event_type = i.event_Type
			join page_hierarchy as p on e.page_id=p.page_id
			where event_name = 'Page View') subquery
		group by page_name
		Order by visits
		limit 3;
		-- Page			|	visits
		-- Black Truffle	|	1469
		-- Tuna			|	1515
		-- Abalone		|	1525


-- What is the number of views and cart adds for each product category?
			SELECT 
				p.product_category,
				SUM(CASE WHEN i.event_name = 'Page View' THEN 1 ELSE 0 END) AS Page_Views,
				SUM(CASE WHEN i.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS Add_to_Cart
			FROM events AS e
			JOIN event_identifier AS i ON e.event_type = i.event_type
			JOIN page_hierarchy AS p ON e.page_id = p.page_id
			WHERE i.event_name IN ('Page View', 'Add to Cart') 
			  AND p.page_name NOT IN ('Home Page', 'All Products', 'Checkout')
			GROUP BY p.product_category
			ORDER BY p.product_category;
			-- Category		|	Page_v	|	Add_to cart
			-- Luxury		|	3032	|	1870
			-- Shellfish		|	6204	|	3792
			-- Fish			|	4633	|	2789


-- What are the top 3 products by purchases?
			WITH purchases AS (
				SELECT DISTINCT visit_id
				FROM events AS e
				JOIN event_identifier AS i ON e.event_type = i.event_type
				WHERE i.event_name = 'Purchase'
			),
			add_to_cart AS (
				SELECT e.visit_id, p.product_id 
				FROM events AS e
				JOIN event_identifier AS i ON e.event_type = i.event_type
				JOIN page_hierarchy AS p ON e.page_id = p.page_id
				WHERE i.event_name = 'Add to Cart'
			)
			select product_id, count(visit_id) as sales 
				FROM (
					SELECT a.visit_id, a.product_id, 
					CASE WHEN p.visit_id IS NOT NULL THEN 'Yes' ELSE 'No' END AS purchase
					FROM add_to_cart a
					LEFT JOIN purchases p ON a.visit_id = p.visit_id)subquery
					where purchase = 'Yes'
					GROUP BY product_id
					order by sales desc
					limit 3;
				-- product_id		|	sales
				-- 7			|	754
				-- 9			|	726
				-- 8			|	719


-- 3. Product Funnel Analysis
-- Using a single SQL query - create a new output table which has the following details:
-- How many times was each product viewed?
-- How many times was each product added to cart?
-- How many times was each product added to a cart but not purchased (abandoned)?
-- How many times was each product purchased?
				CREATE TABLE IF NOT EXISTS product_metrics (
					product_id INT PRIMARY KEY,
					views INT DEFAULT 0,
					added_to_cart INT DEFAULT 0,
					purchased INT DEFAULT 0,
					abandoned INT DEFAULT 0);

				INSERT INTO product_metrics (product_id, views, added_to_cart, purchased, abandoned)
                WITH purchases AS (
					SELECT DISTINCT visit_id
					FROM events AS e
					JOIN event_identifier AS i ON e.event_type = i.event_type
					WHERE i.event_name = 'Purchase'
				),
				add_to_cart AS (
					SELECT e.visit_id, p.product_id, i.event_name
					FROM events AS e
					JOIN event_identifier AS i ON e.event_type = i.event_type
					JOIN page_hierarchy AS p ON e.page_id = p.page_id
					WHERE i.event_name = 'Add to Cart'
                    or i.event_name = 'Page View' AND product_id IS NOT NULL
				)
				SELECT a.product_id, 
						SUM(CASE WHEN a.event_name = 'Page View' THEN 1 ELSE 0 END) AS views,
						SUM(CASE WHEN a.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS added_to_cart,
						SUM(CASE WHEN a.event_name = 'Add to Cart' AND p.visit_id IS NOT NULL THEN 1 ELSE 0 END) AS purchased,
						SUM(CASE WHEN a.event_name = 'Add to Cart' AND p.visit_id IS NULL THEN 1 ELSE 0 END) AS abandoned
				FROM add_to_cart a
				LEFT JOIN purchases p ON a.visit_id = p.visit_id
                WHERE a.product_id IS NOT NULL
				GROUP BY a.product_id;
				-- product_id 		| views 	| added_to_cart		| purchased 	| abandoned
				-- 4			| 1563		| 946			| 697		| 249
				-- 7			| 1547		| 968			| 754		| 214
				-- 8			| 1564		| 949			| 719		| 230
				-- 9			| 1568		| 943			| 726		| 217
				-- 2			| 1559		| 920			| 707		| 213
				-- 3			| 1515		| 931			| 697		| 234
				-- 5			| 1469		| 924			| 707		| 217
				-- 6			| 1525		| 932			| 699		| 233
				-- 1			| 1559		| 938			| 711		| 227


-- Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
                CREATE TABLE IF NOT EXISTS product_category_metrics (
					product_category VARCHAR(9) PRIMARY KEY,
					views INT DEFAULT 0,
					added_to_cart INT DEFAULT 0,
					purchased INT DEFAULT 0,
					abandoned INT DEFAULT 0);

				INSERT INTO product_category_metrics (product_category, views, added_to_cart, purchased, abandoned)
				WITH purchases AS (
					SELECT DISTINCT visit_id
					FROM events AS e
					JOIN event_identifier AS i ON e.event_type = i.event_type
					WHERE i.event_name = 'Purchase'
				),
				add_to_cart AS (
					SELECT e.visit_id, p.product_id, i.event_name, p.product_category
					FROM events AS e
					JOIN event_identifier AS i ON e.event_type = i.event_type
					JOIN page_hierarchy AS p ON e.page_id = p.page_id
					WHERE i.event_name = 'Add to Cart'
					   OR (i.event_name = 'Page View' AND p.product_id IS NOT NULL)
				)
				SELECT a.product_category,
					   SUM(CASE WHEN a.event_name = 'Page View' THEN 1 ELSE 0 END) AS views,
					   SUM(CASE WHEN a.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS added_to_cart,
					   SUM(CASE WHEN a.event_name = 'Add to Cart' AND p.visit_id IS NOT NULL THEN 1 ELSE 0 END) AS purchased,
					   SUM(CASE WHEN a.event_name = 'Add to Cart' AND p.visit_id IS NULL THEN 1 ELSE 0 END) AS abandoned
				FROM add_to_cart a
				LEFT JOIN purchases p ON a.visit_id = p.visit_id
				WHERE a.product_id IS NOT NULL
				GROUP BY a.product_category;
				-- Category		|	views 	|	added_to_cart	| 	purchased 	| 	abandoned
				-- Fish			| 	4633	|	2789		| 	2115		| 	674
				-- Luxury		| 	3032	|	1870		| 	1404		| 	466
				-- Shellfish		| 	6204	|	3792		| 	2898		| 	894


-- Use your 2 new output tables - answer the following questions:
-- Which product had the most views, cart adds and purchases?
				SELECT product_id, 
					   views, 
					   added_to_cart, 
					   purchased, 
					   (views + added_to_cart + purchased) AS totals
				FROM product_metrics
				GROUP BY product_id, views, added_to_cart, purchased
				ORDER BY totals DESC
				LIMIT 1;
				-- product_id	| views		| cart_adds		| purchases		| totals
                		-- 7		| 1547		| 968			| 754			| 3269


-- Which product was most likely to be abandoned?
				SELECT product_id, 
					   abandoned, 
					   added_to_cart, 
					   (abandoned/added_to_cart) AS probability_of_aband
				FROM product_metrics
                order by probability_of_aband desc
                limit 1;
				-- product_id	| cart_adds 	| 	abandoned 	| 	probability_of_abandone
				-- 4		| 249		|	946		|	0.2632


use clique_bait;
-- Which product had the highest view to purchase percentage?
-- What is the average conversion rate from view to cart add?
-- What is the average conversion rate from cart add to purchase?
				
                   
-- 3. Campaigns Analysis
-- Generate a table that has 1 single row for every unique visit_id record and has the following columns:
	-- user_id
	-- visit_id
	-- visit_start_time: the earliest event_time for each visit
	-- page_views: count of page views for each visit
	-- cart_adds: count of product cart add events for each visit
	-- purchase: 1/0 flag if a purchase event exists for each visit
	-- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
	-- impression: count of ad impressions for each visit
	-- click: count of ad clicks for each visit
-- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)
-- Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.
-- Some ideas you might want to investigate further include:
	-- Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
	-- Does clicking on an impression lead to higher purchase rates?
	-- What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
	-- What metrics can you use to quantify the success or failure of each campaign compared to eachother?
    
    
-- Conclusion
-- This case study is based off my many years working with Digital datasets in consumer banking and retail supermarkets - all of the datasets are designed based off real datasets I’ve come across in challenging problem solving scenarios and the questions reflect similar problems which I worked on.
-- Campaign analysis is almost everywhere in the data world, especially in marketing, digital, UX and retail industries - and being able to analyse views, clicks and other digital behaviour is a critical skill to have in your toolbelt as a data professional!
-- Ready for the next 8 Week SQL challenge case study? Click on the banner below to get started with case study #7!
