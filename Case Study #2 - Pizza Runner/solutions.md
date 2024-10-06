### A. Pizza Metrics
### 1. How many pizzas were ordered?

````sql
select count(*)
from customer_orders;
````

###  2. How many unique customer orders were made?
````sql
select count(distinct(order_id)) as unique_order from customer_orders;
````
###  3. How many successful orders were delivered by each runner?
````sql
select count(*) 
from runner_orders
where pickup_time <> "";
````
### 4. How many of each type of pizza was delivered?
````sql
select count(*), pizza_name
from (
	select co.*, ro.pickup_time, pn.pizza_name 
	from customer_orders as co
	join runner_orders as ro on co.order_id=ro.order_id
	join pizza_names as pn on co.pizza_id=pn.pizza_id
	where ro.pickup_time <> ""
    ) as subquery
group by pizza_name;
````
###  5. How many Vegetarian and Meatlovers were ordered by each customer?
````sql
select count(*), pizza_name
from (
	select co.*, ro.pickup_time, pn.pizza_name 
	from customer_orders as co
	join runner_orders as ro on co.order_id=ro.order_id
	join pizza_names as pn on co.pizza_id=pn.pizza_id
    ) as subquery
group by pizza_name;
````
### 6. What was the maximum number of pizzas delivered in a single order?
````sql
select count(*) as orders, order_id
from customer_orders
group by order_id
order by orders desc
limit 1;
````
### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
````sql
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
````
## 8. How many pizzas were delivered that had both exclusions and extras?
````sql
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
````
### 9. What was the total volume of pizzas ordered for each hour of the day?
````sql
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
````
###  10. What was the volume of orders for each day of the week?
````sql
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
````
        
###  B. Runner and Customer Experience
###  1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
````sql
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
````

###  2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
````sql
select 
runner_id, AVG(TIMESTAMPDIFF(MINUTE, order_time, pickup_time)) AS avg_pickup_delay_minutes
from (
	select co.*, ro.runner_id, ro.pickup_time
	from customer_orders as co
	join runner_orders as ro on co.order_id=ro.order_id
	where ro.pickup_time <> 'null') as subquery
GROUP BY ro.runner_id;
````

````sql
select co.*, ro.runner_id, ro.pickup_time, (TIMESTAMPDIFF(MINUTE, order_time, pickup_time)) AS pickup_delay_minutes
from customer_orders as co
join runner_orders as ro on co.order_id=ro.order_id
where ro.pickup_time <> 'null';
````

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
````sql
select * from customer_orders;
````

````sql
select * from runner_orders;
````

````sql
select order_id, avg(pickup_delay_minutes) as prep_time, count(*) as pizzas, (prep_time/pizzas) as TPP
from (
	select co.*, ro.runner_id, ro.pickup_time, (TIMESTAMPDIFF(MINUTE, order_time, pickup_time)) AS pickup_delay_minutes
	from customer_orders as co
	join runner_orders as ro on co.order_id=ro.order_id
	where ro.pickup_time <> 'null') subquery
group by order_id;
````

````sql
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
````

### 4. What was the average distance travelled for each customer?
````sql
select customer_id, round(avg(distance_km),2) as distance_kms from (
	select co.*,CAST(SUBSTRING_INDEX(ro.distance, ' ', 1) AS DECIMAL(10, 2)) AS distance_km
	from customer_orders as co
	join runner_orders as ro on co.order_id=ro.order_id) as subquery
WHERE distance_km IS NOT NULL and distance_km > 0
group by customer_id
order by distance_kms desc;
````

### 5. What was the difference between the longest and shortest delivery times for all orders?
````sql
select max(distance_kms) as longest, min(distance_kms) as shorterst, (max(distance_kms)-min(distance_kms)) as difference 
from (
	select customer_id, round(avg(distance_km),2) as distance_kms from (
		select co.*,CAST(SUBSTRING_INDEX(ro.distance, ' ', 1) AS DECIMAL(10, 2)) AS distance_km
		from customer_orders as co
		join runner_orders as ro on co.order_id=ro.order_id) as subquery
	WHERE distance_km IS NOT NULL and distance_km > 0
	group by customer_id
	order by distance_kms desc) as subquery2;
````

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
````sql
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
````

###  7. What is the successful delivery percentage for each runner?
````sql
select
runner_id,
sum(not_cancelled) as deliver,
sum(cancelled) as cancel,
sum(not_cancelled)/(sum(not_cancelled)+sum(cancelled)) as prc_deliver
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
````

###  C. Ingredient Optimisation
###  1. What are the standard ingredients for each pizza?
````sql
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
        (SELECT 1 AS n
		UNION ALL SELECT 2
		UNION ALL SELECT 3
		UNION ALL SELECT 4
		UNION ALL SELECT 5
		UNION ALL SELECT 6
		UNION ALL SELECT 7
		UNION ALL SELECT 8) AS n
        ON CHAR_LENGTH(pr.Toppings) - CHAR_LENGTH(REPLACE(pr.Toppings, ',', '')) >= n.n - 1
    ORDER BY
        pr.Pizza_ID, Topping_id) AS subquery
JOIN 
    pizza_toppings AS pt ON subquery.Topping_id = pt.Topping_id
JOIN 
    pizza_names AS pn ON subquery.pizza_ID = pn.pizza_ID
ORDER BY 
    pizza_name;
````

###  2. What was the most commonly added extra?
````sql
select extras, Topping, count(*) as cantidad
from(
select subquery.Pizza_ID, subquery.Topping as Topping, pt.topping_name as extras
from
(SELECT pr.Pizza_ID,CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(pr.Toppings, ',', n.n), ',', -1) AS UNSIGNED) AS Topping
FROM pizza_recipes pr INNER JOIN
    (SELECT 1 AS n UNION ALL SELECT 2
		UNION ALL SELECT 3
		UNION ALL SELECT 4
		UNION ALL SELECT 5
		UNION ALL SELECT 6
		UNION ALL SELECT 7
		UNION ALL SELECT 8) AS n
    ON CHAR_LENGTH(pr.Toppings) - CHAR_LENGTH(REPLACE(pr.Toppings, ',', '')) >= n.n - 1
ORDER BY pr.Pizza_ID, Topping) as subquery
join pizza_toppings as pt on subquery.Topping=pt.topping_id) as subquery2
group by extras, Topping
order by cantidad desc;
````

````sql
select extras, topping_name, count(*) as count 
from customer_orders as co
join pizza_toppings as pt on co.extras=pt.topping_id
where extras >=1 
group by extras,topping_name;
````

###  3. What was the most common exclusion?
````sql
select co.exclusions, pt.topping_name, count(*) as count  
from customer_orders as co
join pizza_toppings as pt on co.exclusions=pt.topping_id
where exclusions >=1
group by co.exclusions,pt.topping_name;
````

### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
* Meat Lovers
* Meat Lovers - Exclude Beef
* Meat Lovers - Extra Bacon
* Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

````sql
SELECT co.*,
    CASE 
        WHEN pn.pizza_id = 1 AND co.exclusions = 3 THEN 'Meat Lovers without Beef'
        WHEN pn.pizza_id = 1 AND co.extras = 1 THEN 'Meat Lovers with Bacon'
        WHEN pn.pizza_id = 1 AND co.exclusions = 4 THEN 'Meat Lovers without Cheese'
        when pn.pizza_id = 1 and co.exclusions = 4 or co.exclusions = 1 or co.extras = 6 or co.extras = 9
		then "Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers"
        WHEN pn.pizza_id = 1 THEN 'Meat Lovers'
        WHEN pn.pizza_id = 2 THEN 'Vegetarian'
    END AS order_item
FROM customer_orders AS co 
JOIN pizza_names AS pn ON co.pizza_id = pn.pizza_id;
````

### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
* For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

````sql
SELECT 
    pizza,
    topping,
    SUM(ingredient) AS request
FROM (
    SELECT 
        co.order_id, 
        co.exclusions, 
        co.extras, 
        pv.pizza_name AS pizza, 
        pt.topping_id AS topping_id, 
        pt.topping_name AS topping,
        CASE 
            WHEN FIND_IN_SET(pt.topping_id, co.exclusions) THEN 0
            WHEN FIND_IN_SET(pt.topping_id, co.extras) THEN 2
            ELSE 1 
        END AS ingredient  
    FROM 
        customer_orders AS co
    JOIN 
        pizza_toppings_view AS pv ON co.pizza_id = pv.pizza_id
    JOIN 
        pizza_toppings AS pt ON pv.topping_id = pt.topping_id
) AS subquery
GROUP BY 
    pizza, topping
ORDER BY 
    request DESC;
````

###  D. Pricing and Ratings
###  1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
````sql
SELECT 
    pizza_name, 
    SUM(price) AS total_price
FROM 
    (SELECT 
        co.order_id,
        pn.pizza_name, 
        CASE 
            WHEN co.pizza_id = 1 THEN 12
            WHEN co.pizza_id = 2 THEN 10
        END AS price 
    FROM 
        customer_orders AS co
    JOIN 
        runner_orders AS ro ON co.order_id = ro.order_id
    JOIN 
        pizza_names AS pn ON co.pizza_id = pn.pizza_id) AS subquery
GROUP BY 
    pizza_name;
````

## 2. What if there was an additional $1 charge for any pizza extras?
* Add cheese is $1 extra

````sql
SELECT 
    pizza_name, 
    SUM(price) AS total_price,
    sum(charge) as extra_charge,
    sum(charge+price) as total
FROM 
    (SELECT 
        co.order_id,
        pn.pizza_name, 
        CASE 
            WHEN co.pizza_id = 1 THEN 12
            WHEN co.pizza_id = 2 THEN 10
        END AS price,
        case
            when co.extras is not null then 1
			else 0
        end as charge
    FROM 
        customer_orders AS co
    JOIN 
        runner_orders AS ro ON co.order_id = ro.order_id
    JOIN 
        pizza_names AS pn ON co.pizza_id = pn.pizza_id) AS subquery
GROUP BY 
    pizza_name;
````

````sql
select * from pizza_toppings;
````

-- Add cheese is $1 extra
````sql
SELECT 
    pizza_name, 
    SUM(price) AS total_price,
    sum(extras) as extra_charge,
    sum(extras+price) as total
FROM 
    (SELECT 
        co.order_id,
        pn.pizza_name, 
        CASE 
            WHEN co.pizza_id = 1 THEN 12
            WHEN co.pizza_id = 2 THEN 10
        END AS price,
        case
            when co.extras = 1 then 1
			else 0
        end as extras
    FROM 
        customer_orders AS co
    JOIN 
        runner_orders AS ro ON co.order_id = ro.order_id
    JOIN 
        pizza_names AS pn ON co.pizza_id = pn.pizza_id) AS subquery
GROUP BY 
    pizza_name;
````

###  3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

````sql
ALTER TABLE runner_orders
ADD INDEX idx_order_id (order_id);
````

````sql
CREATE TABLE runner_ratings (
    rating_id INT,
    order_id INT,
    customer_rating INT,
    FOREIGN KEY (order_id) REFERENCES runner_orders(order_id)
);
````

````sql
INSERT INTO runner_ratings (rating_id, order_id, customer_rating) VALUES
(1, 1, 5),
(2, 2, 4),
(3, 3, 3),
(4, 4, 5),
(5, 5, 2),
(6, 6, 4),
(7, 7, 5),
(8, 8, 3),
(9, 9, 5),
(10, 10, 4);
````
````sql
select * from runner_ratings;
````
### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
* Customer_id
* Order_id
* Runner_id
* Rating
* Order_time
* Pickup_time
* Time between order and pickup
* Delivery duration
* Average speed
* Total number of pizzas

````sql
SELECT 
    co.customer_id,
    co.order_id, 
    ro.runner_id, 
    rr.customer_rating, 
    co.order_time, 
    ro.pickup_time, 
    CAST(SUBSTRING_INDEX(ro.distance, ' ', 1) AS DECIMAL(10, 2)) AS distance,
    CAST(SUBSTRING_INDEX(ro.duration, ' ', 1) AS DECIMAL(10, 2)) AS duration,
    CAST((CAST(SUBSTRING_INDEX(ro.distance, ' ', 1) AS DECIMAL(10, 2)) / 
          CAST(SUBSTRING_INDEX(ro.duration, ' ', 1) AS DECIMAL(10, 2)) * 60) AS DECIMAL(10, 2)) AS speed_kmh,
    COUNT(*) AS quantity
FROM 
    customer_orders AS co
JOIN 
    runner_ratings AS rr ON co.order_id = rr.order_id
JOIN 
    runner_orders AS ro ON co.order_id = ro.order_id
WHERE 
    ro.pickup_time IS NOT NULL
GROUP BY 
    co.customer_id, 
    co.order_id, 
    ro.runner_id, 
    rr.customer_rating, 
    co.order_time, 
    ro.pickup_time, 
    distance, 
    duration;
````

````sql
**SELECT 
AVG(speed_kmh) AS avg_speed_kmh,
SUM(quantity) AS total_quantity
FROM (
    SELECT 
    co.customer_id,
    co.order_id, 
    ro.runner_id, 
    rr.customer_rating, 
    co.order_time, 
    ro.pickup_time, 
    CAST(SUBSTRING_INDEX(ro.distance, ' ', 1) AS DECIMAL(10, 2)) AS distance,
    CAST(SUBSTRING_INDEX(ro.duration, ' ', 1) AS DECIMAL(10, 2)) AS duration,
    CAST((distance/duration*60) AS DECIMAL(10, 2)) AS speed_kmh,
    COUNT(*) AS quantity 
    FROM 
    customer_orders AS co
    JOIN 
    runner_ratings AS rr ON co.order_id = rr.order_id
    JOIN 
    runner_orders AS ro ON co.order_id = ro.order_id
    WHERE 
    ro.pickup_time IS NOT NULL
    GROUP BY 
    co.customer_id, 
    co.order_id, 
    ro.runner_id, 
    rr.customer_rating, 
    co.order_time, 
    ro.pickup_time, 
    ro.duration, 
    distance
) AS subquery;
````
### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

````sql
select sum(price) as price, sum(delivery) as delivery, sum(price+delivery) as total
from (
	select co.*, 
	case when pizza_id=1 then 12
	else 10
	end as price,
	case when pickup_time is not null then 0.30
	else 0.00
	end as delivery 
	from customer_orders as co
	join runner_orders as ro on co.order_id=ro.order_id
    ) as subquery;
````

###  E. Bonus Questions
###  If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

````sql
INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (3, '1, 2, 3, 4, 5, 6, 8, 10, 7, 9, 11, 12');

insert into pizza_names
	(pizza_id, pizza_name)
VALUES
	(3, 'Supreme');
````

````sql
CREATE VIEW pizza_toppings_view_supreme AS
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
        (SELECT 1 AS n
		UNION ALL SELECT 2
		UNION ALL SELECT 3
		UNION ALL SELECT 4
		UNION ALL SELECT 5
		UNION ALL SELECT 6
		UNION ALL SELECT 7
		UNION ALL SELECT 8
		UNION ALL SELECT 9
		UNION ALL SELECT 10
		UNION ALL SELECT 11
		UNION ALL SELECT 12) AS n
        ON CHAR_LENGTH(pr.Toppings) - CHAR_LENGTH(REPLACE(pr.Toppings, ',', '')) >= n.n - 1
    ORDER BY
        pr.Pizza_ID, Topping_id) AS subquery
JOIN 
    pizza_toppings AS pt ON subquery.Topping_id = pt.Topping_id
JOIN 
    pizza_names AS pn ON subquery.pizza_ID = pn.pizza_ID
ORDER BY 
    pizza_name;
````

````sql
SELECT * FROM pizza_toppings_view_supreme;
````
