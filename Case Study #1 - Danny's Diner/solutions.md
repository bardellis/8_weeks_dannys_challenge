-- 1. What is the total amount each customer spent at the restaurant?
````sql
select sales.customer_id, sum(price) as total_amount
from sales
join menu on sales.product_id=menu.product_id
group by sales.customer_id;
````
-- 2. How many days has each customer visited the restaurant?
SELECT sales.customer_id, count(distinct sales.order_date) AS count_days
FROM sales
GROUP BY sales.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT ranked_sales.*, menu.product_name
from(
	select *,
		row_number() over (partition by sales.customer_id order by sales.order_date) as row_num 
	from sales
) as ranked_sales
join menu on menu.product_id=ranked_sales.product_id
where row_num = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT menu.product_name, COUNT(*) AS total_purchases
FROM sales
JOIN menu ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY total_purchases DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
select customer_id, product_name, total_purchases, ranked
from (
	select sales.customer_id, menu.product_name,
		count(*) as total_purchases,
		row_number() over(partition by sales.customer_id order by count(*) desc) as ranked
	from sales 
	JOIN menu ON sales.product_id = menu.product_id
	group by sales.customer_id, menu.product_name
) as ranked_sales
where ranked = 1;

-- 6. Which item was purchased first by the customer after they became a member?
select *
from(
	select *,
	row_number() over(partition by sales.customer_id order by order_date asc) as ranked
	from(
		select sales.*,members.join_date,menu.product_name,
			case
				when sales.order_date > members.join_date then "after"
				else 'not after'
			end as date_comparison
		from sales
		join menu on sales.product_id=menu.product_id
		join members on sales.customer_id=members.customer_id
		order by customer_id, order_date
	) as subquery_alias
	where date_comparison = 'after'
) as subquery_final
where ranked = 1;

-- 7. Which item was purchased just before the customer became a member?
select * 
from (
	select *,
		row_number() over (partition by customer_id order by order_date) as ranked 
		from (
			select sales.customer_id, sales.order_date, menu.product_name, members.join_date,
				case 
					when sales.order_date < members.join_date then 'before'
					else 'not before' 
				end as comparison_date
			from sales
			join menu on sales.product_id=menu.product_id
			join members on sales.customer_id=members.customer_id
		order by sales.customer_id,sales.order_date) as subquery_inicial
		where comparison_date = 'before'
	) as suquery_final
where ranked =1;

-- 8. What is the total items and amount spent for each member before they became a member?
select subquery_inicial.customer_id, count(*) as total_items, sum(subquery_inicial.price) as price
from (
	select sales.customer_id, sales.order_date, menu.price, members.join_date,
			case 
				when sales.order_date < members.join_date then 'before'
				else 'not before' 
			end as comparison_date
		from sales
		join menu on sales.product_id=menu.product_id
		join members on sales.customer_id=members.customer_id) as subquery_inicial
where subquery_inicial.comparison_date = 'before'
group by subquery_inicial.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select subquery_final.customer_id, sum(subquery_final.points) as total_points
from(
	select subquery_inicial.*,
			case
				when subquery_inicial.product_name = 'sushi' then subquery_inicial.price * 20
				else subquery_inicial.price * 10
			end as points
		from (
			select sales.*,menu.product_name, menu.price
			from sales
			join menu on sales.product_id=menu.product_id
		) as subquery_inicial) as subquery_final
group by subquery_final.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select subquery_inicial.customer_id, sum(subquery_inicial.points) as total_points
from(
	select sales.customer_id, sales.order_date, menu.price, members.join_date,
		case 
			when sales.order_date > members.join_date and sales.order_date <= (members.join_date)+7 then menu.price * 20
			else menu.price * 10
		end as points
	from sales
	join menu on sales.product_id=menu.product_id
	join members on sales.customer_id=members.customer_id) as subquery_inicial
group by customer_id;
