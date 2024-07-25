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
		-- Month 	Visits
		-- 1		8112
		-- 2		13645
		-- 3		8255
		-- 4		2311
		-- 5		411


-- What is the number of events for each event type?
		select event_name, count(visits) as visits
		from (select e.visit_id as visits, i.event_name as event_name from events as e
		join event_identifier as i on i.event_type=e.event_type) subquery
		group by i.event_name;
		-- Event_name 		Visits
		-- Page View		20928
		-- Add to Cart		8451
		-- Purchase			1777
		-- Ad Impression	876
		-- Ad Click			702


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
		-- events			visits	%
		-- Page View		20928	0.64
		-- Add to Cart		8451	0.26
		-- Purchase			1777	0.05
		-- Ad Impression	876		0.03
		-- Ad Click			702		0.02
		

-- What is the percentage of visits which view the checkout page but do not have a purchase event?
		use clique_bait;
SELECT *
FROM (
    SELECT
        e.visit_id AS visit_id,
        SUM(CASE WHEN i.event_name = 'Page View' THEN 1 ELSE 0 END) AS 'Page_View',
        SUM(CASE WHEN i.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS 'Add_to_Cart',
        SUM(CASE WHEN i.event_name = 'Purchase' THEN 1 ELSE 0 END) AS 'Purchase',
        SUM(CASE WHEN i.event_name = 'Ad Impression' THEN 1 ELSE 0 END) AS 'Ad_Impression',
        SUM(CASE WHEN i.event_name = 'Ad Click' THEN 1 ELSE 0 END) AS 'Ad_Click'
    FROM
        events AS e
    JOIN
        event_identifier AS i ON i.event_type = e.event_type
    GROUP BY
        e.visit_id
) subquery 
having Purchase =0 and Add_to_Cart<>0; -- Check alias casing and usage


            
-- What are the top 3 pages by number of views?
-- What is the number of views and cart adds for each product category?
-- What are the top 3 products by purchases?

select count(distinct(user_id)) as users from users;



-- 3. Product Funnel Analysis
-- Using a single SQL query - create a new output table which has the following details:
-- How many times was each product viewed?
-- How many times was each product added to cart?
-- How many times was each product added to a cart but not purchased (abandoned)?
-- How many times was each product purchased?
-- Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
-- Use your 2 new output tables - answer the following questions:
-- Which product had the most views, cart adds and purchases?
-- Which product was most likely to be abandoned?
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