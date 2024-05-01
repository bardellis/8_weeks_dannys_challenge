Use pizza_runner;

CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  runner_id INTEGER,
  registration_date DATE
);

INSERT INTO runners
  (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');
select * from runners;

DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);

INSERT INTO customer_orders
  (order_id, customer_id, pizza_id, exclusions, extras, order_time)
VALUES
  (1, 101, 1, NULL, NULL, '2020-01-01 18:05:02'),
  (2, 101, 1, NULL, NULL, '2020-01-01 19:00:52'),
  (3, 102, 1, NULL, NULL, '2020-01-02 23:51:23'),
  (3, 102, 2, NULL, 'NULL', '2020-01-02 23:51:23'),
  (4, 103, 1, '4', NULL, '2020-01-04 13:23:46'),
  (4, 103, 1, '4', NULL, '2020-01-04 13:23:46'),
  (4, 103, 2, '4', NULL, '2020-01-04 13:23:46'),
  (5, 104, 1, null, '1', '2020-01-08 21:00:29'),
  (6, 101, 2, null, NULL, '2020-01-08 21:03:13'),
  (7, 105, 2, null, '1', '2020-01-08 21:20:29'),
  (8, 102, 1, null, null, '2020-01-09 23:54:33'),
  (9, 103, 1, '4', '1', '2020-01-10 11:22:59'),
  (10, 104, 1, null, null, '2020-01-11 18:34:49'),
  (10, 104, 1, '2', '6', '2020-01-11 18:34:49');
select * from customer_orders;
delete from customer_orders;

DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO runner_orders
  (order_id, runner_id, pickup_time, distance, duration, cancellation)
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', null, null, null, 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', null),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', null),
  ('9', '2', null, null, null, 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', null);
select * from runner_orders;
delete from runner_orders;

DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  pizza_id INTEGER,
  pizza_name TEXT
);

INSERT INTO pizza_names
  (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');
select * from pizza_names;

DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings TEXT
);

INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES
  ('1', '1, 2, 3, 4, 5, 6, 8, 10'),
  ('2', '4, 6, 7, 9, 11, 12');
SELECT * FROM pizza_recipes;


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INTEGER,
  topping_name TEXT
);

INSERT INTO pizza_toppings
  (topping_id, topping_name)
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
SELECT * FROM pizza_toppings;

-- A. Pizza Metrics
-- How many pizzas were ordered?
select count(*)
from customer_orders;

-- How many unique customer orders were made?
select count(distinct(order_id)) as unique_order from customer_orders;

-- How many successful orders were delivered by each runner?
select count(*) 
from runner_orders
where pickup_time <> "";

-- How many of each type of pizza was delivered?
select count(*), pizza_name
from (
	select co.*, ro.pickup_time, pn.pizza_name 
	from customer_orders as co
	join runner_orders as ro on co.order_id=ro.order_id
	join pizza_names as pn on co.pizza_id=pn.pizza_id
	where ro.pickup_time <> ""
    ) as subquery
group by pizza_name;

-- How many Vegetarian and Meatlovers were ordered by each customer?
select count(*), pizza_name
from (
	select co.*, ro.pickup_time, pn.pizza_name 
	from customer_orders as co
	join runner_orders as ro on co.order_id=ro.order_id
	join pizza_names as pn on co.pizza_id=pn.pizza_id
    ) as subquery
group by pizza_name;

-- What was the maximum number of pizzas delivered in a single order?
select count(*) as orders, order_id
from customer_orders
group by order_id
order by orders desc
limit 1;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
    customer_id,
    count_changes,
    (total_count - count_changes) AS no_changes,
    total_count
FROM (
    SELECT 
        customer_id,
        SUM(changes) AS count_changes,
        COUNT(*) AS total_count
    FROM (
        SELECT 
            *,
            CASE 
                WHEN exclusions IS NOT NULL THEN 1
                WHEN extras IS NOT NULL THEN 1
                ELSE 0 
            END AS changes
        FROM 
            customer_orders
    ) as subquery1
    GROUP BY 
        customer_id
) as subquery2;

-- How many pizzas were delivered that had both exclusions and extras?
select additions, count(*) as additions_count
from (
	select co.*, ro.cancellation,
		case when co.exclusions is not null and co.extras is not null then "additionals"
		else "no additionals"
	end as additions
	from customer_orders as co
	left join runner_orders as ro on co.order_id = ro.order_id
	where ro.cancellation is null
    ) subquery
group by additions;

-- What was the total volume of pizzas ordered for each hour of the day?
select
	order_hour,
    count(order_id) as order_quant
    from(
    select 
		o.order_id,
		o.customer_id,
		date(o.order_time) as date,
		substring(time(o.order_time),1,2) as order_hour 
	from customer_orders as o) as subquery
group by 
	order_hour
order by 
	order_quant desc;

-- What was the volume of orders for each day of the week?
select 
	weekday_name,
    count(*) as count
from(
	select
		o.order_id,
		o.customer_id,
		dayofweek(date(o.order_time)) as weekday,
		case dayofweek(date(o.order_time)) 
			when 1 then 'sunday'
			when 2 then 'monday'
			when 3 then 'tuesday'
			when 4 then 'wednesday'
			when 5 then 'thursday'
			when 6 then 'friday'
			when 7 then 'saturday'
		end as weekday_name
		from customer_orders as o) as subquery
group by weekday_name;
        
-- B. Runner and Customer Experience
-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
    CASE 
        WHEN registration_date >= '2021-01-01' AND registration_date < '2021-01-08' THEN 'first week'
        -- Add more cases for subsequent weeks as needed
        ELSE 'Later'
    END AS registration_week,
    COUNT(*) AS num_runners
FROM 
    runners
GROUP BY 
    registration_week;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select 
runner_id, AVG(TIMESTAMPDIFF(MINUTE, order_time, pickup_time)) AS avg_pickup_delay_minutes
from (
	select co.*, ro.runner_id, ro.pickup_time
	from customer_orders as co
	join runner_orders as ro on co.order_id=ro.order_id
	where ro.pickup_time <> 'null') as subquery
GROUP BY ro.runner_id;


select co.*, ro.runner_id, ro.pickup_time, (TIMESTAMPDIFF(MINUTE, order_time, pickup_time)) AS pickup_delay_minutes
from customer_orders as co
join runner_orders as ro on co.order_id=ro.order_id
where ro.pickup_time <> 'null';

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
select * from customer_orders;
select * from runner_orders;

select order_id, avg(pickup_delay_minutes) as prep_time, count(*) as pizzas, (prep_time/pizzas) as TPP
from (
	select co.*, ro.runner_id, ro.pickup_time, (TIMESTAMPDIFF(MINUTE, order_time, pickup_time)) AS pickup_delay_minutes
	from customer_orders as co
	join runner_orders as ro on co.order_id=ro.order_id
	where ro.pickup_time <> 'null') subquery
group by order_id;

SELECT 
    order_id, 
    AVG(pickup_delay_minutes) AS prep_time, 
    COUNT(*) AS pizzas, 
    round ((AVG(pickup_delay_minutes) / COUNT(*)),2) AS TPP
FROM (
    SELECT 
        co.*, 
        ro.runner_id, 
        ro.pickup_time, 
        (TIMESTAMPDIFF(MINUTE, order_time, pickup_time)) AS pickup_delay_minutes
    FROM 
        customer_orders AS co
    JOIN 
        runner_orders AS ro ON co.order_id = ro.order_id
    WHERE 
        ro.pickup_time IS NOT NULL
) AS subquery
GROUP BY 
    order_id;

-- What was the average distance travelled for each customer?
select customer_id, round(avg(distance_km),2) as distance_kms from (
	select co.*,CAST(SUBSTRING_INDEX(ro.distance, ' ', 1) AS DECIMAL(10, 2)) AS distance_km
	from customer_orders as co
	join runner_orders as ro on co.order_id=ro.order_id) as subquery
WHERE distance_km IS NOT NULL and distance_km > 0
group by customer_id
order by distance_kms desc;

-- What was the difference between the longest and shortest delivery times for all orders?
select max(distance_kms) as longest, min(distance_kms) as shorterst, (max(distance_kms)-min(distance_kms)) as difference 
from (
	select customer_id, round(avg(distance_km),2) as distance_kms from (
		select co.*,CAST(SUBSTRING_INDEX(ro.distance, ' ', 1) AS DECIMAL(10, 2)) AS distance_km
		from customer_orders as co
		join runner_orders as ro on co.order_id=ro.order_id) as subquery
	WHERE distance_km IS NOT NULL and distance_km > 0
	group by customer_id
	order by distance_kms desc) as subquery2;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
select 
    runner_id,
    round(avg(distance_km),2) as distance_kms,
    round(avg(duration_min),2) as duration_min,
    ROUND(AVG(distance_km),2)/(ROUND(AVG(duration_min),2)) AS km_min 
from (
    select 
        co.*, 
        ro.runner_id,
        CAST(SUBSTRING_INDEX(ro.duration, ' ', 1) AS DECIMAL (10, 2)) AS duration_min,
        CAST(SUBSTRING_INDEX(ro.distance, ' ', 1) AS DECIMAL(10, 2)) AS distance_km 
    from 
        customer_orders as co
    join 
        runner_orders as ro on co.order_id=ro.order_id
) as subquery
WHERE distance_km IS NOT NULL and distance_km > 0
group by runner_id
order by km_min desc;

-- What is the successful delivery percentage for each runner?
select runner_id, sum(not_cancelled) as deliver, sum(cancelled) as cancel, sum(not_cancelled)/(sum(not_cancelled)+sum(cancelled)) as prc_deliver
from (
Select *, 
case when not_cancelled =1 then 0
Else 1
end as cancelled 
from(
	SELECT *,
	CASE 
    WHEN cancellation IS NULL or cancellation ="" THEN '1'
    ELSE '0' 
	END AS not_cancelled
	FROM runner_orders) subquery) subquery2
    group by runner_id;

-- C. Ingredient Optimisation
-- What are the standard ingredients for each pizza?
CREATE VIEW pizza_toppings_view AS
SELECT 
    subquery.pizza_ID, 
    pn.pizza_name,
    subquery.Topping_id, 
    pt.topping_name 
FROM 
    (SELECT
        pr.Pizza_ID, 
        CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(pr.Toppings, ',', n.n), ',', -1) AS UNSIGNED) AS Topping_id
    FROM
        pizza_recipes pr
    INNER JOIN
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8) AS n
        ON CHAR_LENGTH(pr.Toppings) - CHAR_LENGTH(REPLACE(pr.Toppings, ',', '')) >= n.n - 1
    ORDER BY
        pr.Pizza_ID, Topping_id) AS subquery
JOIN 
    pizza_toppings AS pt ON subquery.Topping_id = pt.Topping_id
JOIN 
    pizza_names AS pn ON subquery.pizza_ID = pn.pizza_ID
ORDER BY 
    pizza_name;

-- What was the most commonly added extra?
select extras, Topping, count(*) as cantidad
from(
select subquery.Pizza_ID, subquery.Topping as Topping, pt.topping_name as extras
from
(SELECT pr.Pizza_ID,CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(pr.Toppings, ',', n.n), ',', -1) AS UNSIGNED) AS Topping
FROM pizza_recipes pr INNER JOIN
    (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8) AS n
    ON CHAR_LENGTH(pr.Toppings) - CHAR_LENGTH(REPLACE(pr.Toppings, ',', '')) >= n.n - 1
ORDER BY pr.Pizza_ID, Topping) as subquery
join pizza_toppings as pt on subquery.Topping=pt.topping_id) as subquery2
group by extras, Topping
order by cantidad desc;

select extras, topping_name, count(*) as count 
from customer_orders as co
join pizza_toppings as pt on co.extras=pt.topping_id
where extras >=1 
group by extras,topping_name;

-- What was the most common exclusion?
select co.exclusions, pt.topping_name, count(*) as count  
from customer_orders as co
join pizza_toppings as pt on co.exclusions=pt.topping_id
where exclusions >=1
group by co.exclusions,pt.topping_name;

-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
SELECT co.*,
    CASE 
        WHEN pn.pizza_id = 1 AND co.exclusions = 3 THEN 'Meat Lovers without Beef'
        WHEN pn.pizza_id = 1 AND co.extras = 1 THEN 'Meat Lovers with Bacon'
        WHEN pn.pizza_id = 1 AND co.exclusions = 4 THEN 'Meat Lovers without Cheese'
        when pn.pizza_id = 1 and co.exclusions = 4 or co.exclusions = 1 or co.extras = 6 or co.extras = 9 then "Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers"
        WHEN pn.pizza_id = 1 THEN 'Meat Lovers'
        WHEN pn.pizza_id = 2 THEN 'Vegetarian'
    END AS order_item
FROM customer_orders AS co 
JOIN pizza_names AS pn ON co.pizza_id = pn.pizza_id;

-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
----- pizza_name as pizza, pt.topping_name as topping
----- count(*) as quantity  

select pizza, topping, sum(ingredient) as request
from (select order_id, exclusions, extras, pizza_name as pizza, pt.topping_id as topping_id, pt.topping_name as topping,
case 
when exclusions = pt.topping_id then "0"
when extras = pt.topping_id then "2"
else "1" 
end as ingredient  
from customer_orders as co
join pizza_toppings_view as pv on co.pizza_id=pv.pizza_ID
join pizza_toppings as pt on pv.Topping_id=pt.topping_id) as subquery
group by pizza, topping
order by request desc;


-- D. Pricing and Ratings
-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
-- What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
-- The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
-- Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas
-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
-- how much money does Pizza Runner have left over after these deliveries?


-- E. Bonus Questions
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen 
-- if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?