## 2. Digital Analysis
1. Using the available datasets - answer the following questions using a single query for each one:
2. How many users are there? 500

````sql
		SELECT COUNT(DISTINCT user_id) AS users
		FROM users;
````


4. How many cookies does each user have on average? 3.56
````sql
		SELECT ROUND(AVG(cookies), 2) AS avg_cookies
		FROM (
			SELECT user_id, COUNT(cookie_id) AS cookies
			FROM users
			GROUP BY user_id
			) AS subquery;
````

5. What is the unique number of visits by all users per month?
````sql
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
````

| Month 	|	Visits
|---------------|--------------
| 1		|	8112
| 2		|	13645
| 3		|	8255
| 4		|	2311
| 5		|	411


7. What is the number of events for each event type?
````sql
		select event_name, count(visits) as visits
		from (select e.visit_id as visits, i.event_name as event_name from events as e
		join event_identifier as i on i.event_type=e.event_type) subquery
		group by i.event_name;
````

|Event_name 	|	Visits
|---------------|-----------------
|Page View	|	20928
|Add to Cart	|	8451
|Purchase	|	1777
|Ad Impression	|	876
|Ad Click	|	702


8. What is the percentage of visits which have a purchase event?
````sql
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
````

| events		|	visits	|	%
|-----------------------|---------------|---------------
| Page View		|	20928	|	0.64
| Add to Cart		|	8451	|	0.26
| Purchase		|	1777	|	0.05
| Ad Impression		|	876	|	0.03
| Ad Impression		|	876	|	0.03
| Ad Click		|	702	|	0.02
		

6. What is the percentage of visits which view the checkout page but do not have a purchase event?
````sql
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
````
			
| event_condition		|	visits	|	percentage
|-------------------------------|---------------|------------------------
| checkout-no_purchase		|	326	|	9.15
| others			|	3238	|	90.85  

	    
8. What are the top 3 pages by number of views?
````sql
		select page_name, count(*) as visits
		from (
			select p.page_name, e.visit_id from events as e
			join event_identifier as i on e.event_type = i.event_Type
			join page_hierarchy as p on e.page_id=p.page_id
			where event_name = 'Page View') subquery
		group by page_name
		Order by visits
		limit 3;
````

| Page		|	visits
|---------------|---------------
| Black Truffle	|	1469
| Tuna		|	1515
| Abalone	|	1525


9. What is the number of views and cart adds for each product category?
````sql

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
````
			
| Category		|	Page_v	|	Add_to cart
|-----------------------|---------------|--------------------------
| Luxury		|	3032	|	1870
| Shellfish		|	6204	|	3792
| Fish			|	4633	|	2789


9 What are the top 3 products by purchases?
````sql			
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
````
		
| product_id		|	sales
|-----------------------|----------------------
| 7			|	754
| 9			|	726|
| 8			|	719


## 3. Product Funnel Analysis
1. Using a single SQL query - create a new output table which has the following details:
2. How many times was each product viewed?
3. How many times was each product added to cart?
4. How many times was each product added to a cart but not purchased (abandoned)?
5. How many times was each product purchased?

````sql  
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
````

					
				| product_id 		| views 	| added_to_cart		| purchased 	| abandoned
				|-----------------------|---------------|-----------------------|---------------|----------
				| 4			| 1563		| 946			| 697		| 249
				| 7			| 1547		| 968			| 754		| 214
				| 8			| 1564		| 949			| 719		| 230
				| 9			| 1568		| 943			| 726		| 217
				| 2			| 1559		| 920			| 707		| 213
				| 3			| 1515		| 931			| 697		| 234
				| 5			| 1469		| 924			| 707		| 217
				| 6			| 1525		| 932			| 699		| 233
				| 1			| 1559		| 938			| 711		| 227


Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

````sql
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
````						
				| Category		|	views 	|	added_to_cart	| 	purchased 	| 	abandoned
				|-----------------------|---------------|-----------------------|-----------------------|-------------------			
    				| Fish			| 	4633	|	2789		| 	2115		| 	674
				| Luxury		| 	3032	|	1870		| 	1404		| 	466
				| Shellfish		| 	6204	|	3792		| 	2898		| 	894


 Use your 2 new output tables - answer the following questions:
1. Which product had the most views, cart adds and purchases?

````sql
				SELECT product_id, 
					   views, 
					   added_to_cart, 
					   purchased, 
					   (views + added_to_cart + purchased) AS totals
				FROM product_metrics
				GROUP BY product_id, views, added_to_cart, purchased
				ORDER BY totals DESC
				LIMIT 1;
````						
				| product_id	| views		| cart_adds		| purchases		| totals
                		|---------------|---------------|-----------------------|-----------------------|--------------		
		  		| 7		| 1547		| 968			| 754			| 3269


2. Which product was most likely to be abandoned?

````sql
				SELECT product_id, 
					   abandoned, 
					   added_to_cart, 
					   (abandoned/added_to_cart) AS probability_of_aband
				FROM product_metrics
                		order by probability_of_aband desc
                		limit 1;
````						
				| product_id	| cart_adds 	| 	abandoned 	| 	probability_of_abandone
    				|--------------|----------------|---------------------|---------------
				| 4		| 249		|	946		|	0.2632


3. Which product had the highest view to purchase percentage?

````sql
				SELECT product_id, 
					   views, 
					   purchased, 
					   (purchased/views) AS probability_view_to_purchase
				FROM product_metrics
                		order by probability_view_to_purchase desc
                		limit 1;
````
					
				| product_id	| views		| 	purchased 	| 	probability_view_to_purchase
    				|---------------|---------------|-----------------------|----------------------------------
				| 4		| 1563		|	697		|	0.4874


4. What is the average conversion rate from view to cart add?
````sql
				SELECT product_id, 
					   views, 
					   added_to_cart, 
					   (added_to_cart/views) AS probability_view_to_added_to_cart
				FROM product_metrics
                		order by probability_view_to_added_to_cart desc
                		limit 1;
````						
				| product_id	| 	views	| 	added_to_cart 	| 	probability_view_to_added_to_cart
				|---------------|----------------|---------------------|------------------
    				| 5		|	1469	|	924		|	0.6290


5. What is the average conversion rate from cart add to purchase?
````sql
				SELECT avg(purchased) as puchased_avg, avg(added_to_cart) as cart_added_avg, avg(purchased/added_to_cart) AS conversion_purchase_added_to_cart
				FROM product_metrics;
   ````		             		
				| purchased	|	cart_added	| 	conversion
    				|--------------|-------------------------|----------------
                		| 713.00	|	939.00		|	0.759
				
                   
## 4. Campaigns Analysis
Generate a table that has 1 single row for every unique visit_id record and has the following columns:
	* user_id
	* visit_id
	* visit_start_time: the earliest event_time for each visit
	* page_views: count of page views for each visit
	* cart_adds: count of product cart add events for each visit
	* purchase: 1/0 flag if a purchase event exists for each visit
	* campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
	* impression: count of ad impressions for each visit
	* click: count of ad clicks for each visit
  
   ````sql 
				WITH campaigns AS (
				select visit_id, user_id, event_time, page_name, count(*) as visits 
				from events as e 
				join users as u on e.cookie_id=u.cookie_id
				join page_hierarchy p on e.page_id=p.page_id
				where sequence_number=1
				group by visit_id, user_id, event_time, page_name
				order by visits desc
				),
				cart_adds AS( 
				select visit_id, event_name, count(*) cart_adds from events as e
				join event_identifier i on e.event_type=i.event_type
				where e.event_type=2
				group by event_name, visit_id
				),
				page_visited AS(
				select visit_id, count(e.page_id) as page_visited 
				from events as e
				join event_identifier i on e.event_type=i.event_type
				join page_hierarchy p on e.page_id=p.page_id
				where e.event_type=1 and e.page_id > 2
				group by visit_id
				),
				purchases as (
				select visit_id, count(*) as purchases
				from events as e
				join event_identifier i on e.event_type=i.event_type
				join page_hierarchy p on e.page_id=p.page_id
				where i.event_type = 3
				group by visit_id
				order by purchases
				),
				campname as (
				SELECT
				v.visit_id,
				v.event_time,
				c.campaign_name
				FROM
				events as v
				LEFT JOIN
				campaign_identifier as c
				ON
				v.event_time BETWEEN c.start_date AND c.end_date
				where sequence_number=1
				), 
				clicks as(
				 select visit_id, count(*) as clicks from events as e
				join event_identifier i on e.event_type=i.event_type
				join page_hierarchy as p on e.page_id=p.page_id
				where page_name <> 'Home Page' and page_name <> 'All Products' and page_name <> 'Checkout'and event_name = 'Page View'
				group by visit_id
				)
				SELECT 
				c.visit_id, 
				c.user_id, 
				date(c.event_time) as event_time, 
				n.campaign_name, 
				MAX(CASE WHEN u.purchases IS NOT NULL THEN 1 ELSE 0 END) AS purchase,
				sum(CASE WHEN a.cart_adds is not null then a.cart_adds else 0 end) AS cart_adds, 
				SUM(CASE WHEN p.page_visited is not null then p.page_visited else 0 end) AS page_visited, 
				SUM(case when k.clicks is not null then k.clicks else 0 end) AS clicks
				FROM 
					campaigns AS c
				LEFT JOIN 
					cart_adds AS a ON c.visit_id = a.visit_id
				LEFT JOIN 
					page_visited AS p ON c.visit_id = p.visit_id
				LEFT JOIN 
					purchases AS u ON c.visit_id = u.visit_id
				LEFT JOIN 
					campname AS n ON c.visit_id = n.visit_id
				LEFT JOIN 
					clicks AS k ON c.visit_id = k.visit_id
				GROUP BY 
					c.visit_id, c.user_id, c.event_time, n.campaign_name;
````				
				| visit_id 	|	user_id	|	event_date 	|	Campaign				|	purchases 	|	cart_adds 	|	page_visited 	|	clicks
				|---------------|--------------|---------------------|-------------------------------------------------|------------------------|----------------------|-----------------------|-----------------			
    				| 0fc437	|	1	|	2020-02-04 	|	Half Off - Treat Your Shellf(ish)	|	1		|	6		|	9		|	8
				| ccf365	|	1	|	2020-02-04 	|	Half Off - Treat Your Shellf(ish)	|	1		|	3		|	5		|	4
				| c5c0ee	|	2	|	2020-01-18 	|	25% Off - Living The Lux Life		|	0		|	0		|	0		|	0
				| d58cbd	|	2	|	2020-01-18 	|	25% Off - Living The Lux Life		|	0		|	4		|	6		|	5
				| 25502e	|	3	|	2020-02-21  	|	Half Off - Treat Your Shellf(ish)	|	0		|	0		|	0		|	0
				| 9a2f24	|	3	|	2020-02-21 	|	Half Off - Treat Your Shellf(ish)	|	1		|	2		|	5		|	4

    

