SHOW PROCEDURE STATUS WHERE Name = 'monthly_reporting';

DROP PROCEDURE IF EXISTS monthly_reporting;

DELIMITER //
CREATE PROCEDURE monthly_reporting()
BEGIN
    
    DECLARE in_year INT DEFAULT '2021';       -- Año para el mes que deseas analizar
    DECLARE in_month INT DEFAULT '01';         -- Mes para el período que deseas analizar (por ejemplo, julio)
    DECLARE start_date DATE;
    DECLARE end_date DATE;
    DECLARE prev_month DATE;
    
    SET prev_month = DATE(CONCAT(in_year, '-', LPAD(in_month, 2, '0'), '-01'));
    SET start_date = '2021-01-01'; -- DATE_FORMAT(DATE_SUB(prev_month, INTERVAL 1 MONTH), '%Y-%m-01'); -- Primer día del mes anterior
    SET end_date = '2021-01-31'; -- LAST_DAY(DATE_SUB(prev_month, INTERVAL 1 MONTH)); -- Último día del mes anterior
        
	-- What was the total quantity sold for all products?
    select 
    'Total Quantity Sold' AS metric_name,
    sum(qty) as quantity from sales
    WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date;

	-- What is the total generated revenue for all products before discounts?
	select sum(qty*price) as revenue from sales
	WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date; 
        
	-- What was the total discount amount for all products?
	select 
    'Total Discount Amount' AS metric_name,
    sum((qty*price)*discount/100) as discount from sales
	WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date;
        
	-- Transaction Analysis
	-- How many unique transactions were there?
	select 
    'Unique Transactions' AS metric_name,
    count(distinct(txn_id)) as transactions from sales
    WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date; 

	-- What is the average unique products purchased in each transaction?
	select 
    'Average Unique Products Purchased' AS metric_name,
    avg(unique_products) as avg_unique_prod 
	from (
		select txn_id as transaction, count(distinct(prod_id)) as unique_products
		from sales
        WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date 
		group by txn_id
		) subquery;
        
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
            WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
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
		'25th, 50th and 75th percentile values for the revenue per transaction' AS metric_name,
		MIN(CASE WHEN ranking >= CEIL(0.25 * @total_rows) THEN total_revenue END) AS p25,
		MIN(CASE WHEN ranking >= CEIL(0.50 * @total_rows) THEN total_revenue END) AS p50,
		MIN(CASE WHEN ranking >= CEIL(0.75 * @total_rows) THEN total_revenue END) AS p75
	FROM RankedRevenue; 

	-- What is the average discount value per transaction?
		select 
        'average discount value per transaction' AS metric_name,
        round(avg(total_discount),2) as avg_descount
		from(
			select txn_id, sum(discount) as total_discount 
			from(
				SELECT
					txn_id,
					prod_id,
					round(sum((qty*price)*((discount)/100)),2) AS discount 
				from sales
                WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
				group by txn_id, prod_id
				order by txn_id asc
			) as discount_per_product
			group by txn_id
		) as discounts_per_transation; 

		-- What is the percentage split of all transactions for members vs non-members?
		select 
			'percentage split of all transactions' AS metric_name,
            case when members=1 then 'member' else 'non-member' end as client_type,
			qty_member,
			qty_total, 
            round((qty_member/qty_total),2) as pct 
		from (select 
				members,
				count(*) as qty_member,
					(select count(*) from sales) as qty_total
					from sales
                    WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
					group by members) subquery; 

		-- What is the average revenue for member transactions and non-member transactions?
		select 
			'average revenue for transactions' AS metric_name,
            case when members=1 then 'member' else 'non-member' end as client_type,
            round(avg(revenue),2) as avg_revenue 
		from(
			SELECT
            members,
			txn_id,
            prod_id,
			round(sum((qty*price)*((100-discount)/100)),2) AS revenue
			FROM sales
            WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
			GROUP BY members, txn_id, prod_id
			order by txn_id, prod_id)
		subquery
        group by client_type;

		-- Product Analysis
		-- What are the top 3 products by total revenue before discount?
		select
			'3 products by total revenue' AS metric_name,
			s.prod_id,
			p.product_name,
			round(sum((s.qty)*(s.price)),2) as rev_bef_desc 
		from sales as s
			join product_details as p on s.prod_id=p.product_id
            WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
			group by prod_id, product_name
			order by rev_bef_desc desc
			limit 3;

		-- What is the total quantity, revenue and discount for each segment?
		select
			'totals for each segment' AS metric_name,
			p.segment_name as segment,
			sum(qty) AS quantity,
            round(sum((qty*s.price)*((100-discount)/100)),2) AS revenue,
            round(sum((qty*s.price)*((discount)/100)),2) AS discount
		from sales as s
			join product_details as p on s.prod_id=p.product_id
            WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
			group by segment;

		-- What is the top selling product for each segment?
		select
			'top selling product for segment' AS metric_name,
			p.product_id as product_id,
            p.product_name as product,
			sum(qty) AS sales
		from sales as s
			join product_details as p on s.prod_id=p.product_id
            WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
			group by product, product_id
            order by sales desc
            limit 1; 

		-- What is the total quantity, revenue and discount for each category?
		select 
			'totals for category' AS metric_name,
            p.category_name as category,
			sum(qty) AS quantity,
            round(sum((qty*s.price)*((100-discount)/100)),2) AS revenue,
            round(sum((qty*s.price)*((discount)/100)),2) AS discount
		from sales as s
			join product_details as p on s.prod_id=p.product_id
            WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
			group by category;

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
                WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
				GROUP BY p.product_name, p.category_name
		)
		SELECT 
			'top selling product for category' AS metric_name,
            product,
			category,
            total_sales
		FROM RankedProducts
		WHERE ranking = 1;

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
            WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
			GROUP BY segment_id, segment, product, prod_id
		),
		segment_revenue AS (
			SELECT 
				p.segment_id,
				p.segment_name AS segment,
				ROUND(SUM((qty * s.price) * ((100 - discount) / 100)), 2) AS segment_revenue
			FROM sales AS s
			JOIN product_details AS p ON s.prod_id = p.product_id
            WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
			GROUP BY segment_id, segment
		)
		SELECT 
			'percentage by product for segment' AS metric_name,
            p.segment,
			p.prod_id,
			p.product,
			p.revenue,
			round((p.revenue/s.segment_revenue),2) as segment_prc
		FROM product_revenue AS p
		JOIN segment_revenue AS s ON p.segment_id = s.segment_id
		order by segment, segment_prc desc;

		-- What is the percentage split of revenue by segment for each category?
		WITH segment_revenue AS (
			SELECT 
				p.segment_id as segment_id,
                p.segment_name AS segment,
                p.category_id as category_id,
				ROUND(SUM((qty * s.price) * ((100 - discount) / 100)), 2) AS segment_revenue
			FROM sales AS s
			JOIN product_details AS p ON s.prod_id = p.product_id
            WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
			GROUP BY segment_id, segment, category_id
		),
		category_revenue AS (
			SELECT 
				p.category_id as category_id,
				p.category_name AS category,
				ROUND(SUM((qty * s.price) * ((100 - discount) / 100)), 2) AS category_revenue
			FROM sales AS s
			JOIN product_details AS p ON s.prod_id = p.product_id
            WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
			GROUP BY category_id, category
		)
		SELECT 
			'percentage by segment for category' AS metric_name,
            c.category,
            s.segment,
			s.segment_revenue,
            round((s.segment_revenue/c.category_revenue),2) as category_prc
		FROM segment_revenue AS s
		JOIN category_revenue AS c ON s.category_id = c.category_id
		order by segment, category_prc desc;

-- What is the percentage split of total revenue by category?
			select 
            'percentage split of total revenue by category' AS metric_name,
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
                WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
				GROUP BY category_id, category) 
			subquery;

		-- What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
		SELECT
			'penetration for each product' AS metric_name,
            s.prod_id,
			p.product_name AS product,
			COUNT(DISTINCT s.txn_id) AS txn_count,
			ROUND(COUNT(DISTINCT s.txn_id) * 1.0 / (SELECT COUNT(DISTINCT txn_id) FROM sales), 2) AS penetration
		FROM sales AS s
		JOIN product_details AS p ON s.prod_id = p.product_id
        WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
		GROUP BY s.prod_id, p.product_name
		ORDER BY penetration DESC;

		-- What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
		WITH RelevantTransactions AS (
			SELECT txn_id
			FROM sales
            WHERE date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
			GROUP BY txn_id
			HAVING COUNT(DISTINCT prod_id) >= 3)
		, ProductCombinations AS (SELECT a.txn_id, a.prod_id AS prod1, b.prod_id AS prod2, c.prod_id AS prod3
			FROM sales a
			JOIN sales b ON a.txn_id = b.txn_id AND a.prod_id < b.prod_id
			JOIN sales c ON a.txn_id = c.txn_id AND b.prod_id < c.prod_id
			WHERE a.txn_id IN (SELECT txn_id FROM RelevantTransactions) AND date(start_txn_time) >= start_date AND date(start_txn_time) <= end_date
		)
		SELECT 'most common combination' AS metric_name, prod1, prod2, prod3, COUNT(*) AS occurrence_count
		FROM ProductCombinations
		GROUP BY prod1, prod2, prod3
		ORDER BY occurrence_count DESC
		LIMIT 1;
        
END //
DELIMITER ;

CALL monthly_reporting();

select * from sales;