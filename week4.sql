Use data_bank;

-- Case Study Questions
-- The following case study questions include some general data exploration analysis for the nodes and transactions before diving right into the core business questions and finishes with a challenging final request!
-- A. Customer Nodes Exploration
-- How many unique nodes are there on the Data Bank system?
select count(distinct(node_id)) as nodes 
from customer_nodes;

select 
IFNULL(node_id, 'Total') AS nodes,
count(*) as clients
from customer_nodes 
group by node_id
WITH ROLLUP;

-- What is the number of nodes per region?
select 
IFNULL(region_id, 'Total') AS regions,
count(*) as nodes
from customer_nodes 
group by region_id
WITH ROLLUP;

SELECT 
    ifnull(region_name, 'Total') as Region,
    SUM(CASE WHEN node_id = 1 THEN 1 ELSE 0 END) AS node1,
    SUM(CASE WHEN node_id = 2 THEN 1 ELSE 0 END) AS node2,
    SUM(CASE WHEN node_id = 3 THEN 1 ELSE 0 END) AS node3,
    SUM(CASE WHEN node_id = 4 THEN 1 ELSE 0 END) AS node4,
    SUM(CASE WHEN node_id = 5 THEN 1 ELSE 0 END) AS node5,
    COUNT(*) AS Total
FROM 
    customer_nodes as c
join regions as r on c.region_id=r.region_id
GROUP BY 
    region_name
WITH ROLLUP;

-- How many customers are allocated to each region?
SELECT 
    ifnull(region_name, 'Total') as Region,
    COUNT(*) AS Total
FROM 
    customer_nodes as c
join regions as r on c.region_id=r.region_id
GROUP BY 
    region_name
WITH ROLLUP;

-- How many days on average are customers reallocated to a different node?
# there was an error in one of the dates that must to be solved
# UPDATE customer_nodes
# SET customer_nodes.end_date = '2020-12-31'
# WHERE customer_nodes.end_date = '9999-12-31';

select node_id, round(avg(days),2) as days_realloc from(
SELECT customer_id, node_id, c.region_id, end_date, start_date, DATEDIFF(end_date, start_date) AS days 
FROM customer_nodes as c
join regions  as r on c.region_id=r.region_id
) subquery group by node_id;

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH RankedRows AS (
    SELECT
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY days_realloc) AS row_num,
        customer_id,
        region,
        days_realloc
    FROM (
        SELECT customer_id, region, ROUND(AVG(days), 0) AS days_realloc 
        FROM (
            SELECT customer_id, region_name AS region, node_id, c.region_id, end_date, start_date, DATEDIFF(end_date, start_date) AS days 
            FROM customer_nodes AS c
            JOIN regions AS r ON c.region_id = r.region_id
        ) subquery 
        GROUP BY customer_id, region
    ) subquery2
),
MedianRowNum AS (
    SELECT region, ROUND(MAX(row_num) / 2.0, 0) AS median_row_num
    FROM RankedRows
    GROUP BY region
)
SELECT r.customer_id, r.region, r.days_realloc, r.row_num as row_num_median
FROM RankedRows r
JOIN MedianRowNum m
ON r.region = m.region AND r.row_num = m.median_row_num;

WITH RankedRows AS (
    SELECT
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY days_realloc) AS row_num,
        customer_id,
        region,
        days_realloc
    FROM (
        SELECT customer_id, region, ROUND(AVG(days), 0) AS days_realloc 
        FROM (
            SELECT customer_id, region_name AS region, node_id, c.region_id, end_date, start_date, DATEDIFF(end_date, start_date) AS days 
            FROM customer_nodes AS c
            JOIN regions AS r ON c.region_id = r.region_id
        ) subquery 
        GROUP BY customer_id, region
    ) subquery2
),
MedianRowNum AS (
    SELECT region, ROUND(MAX(row_num) *0.8, 0) AS median_row_num
    FROM RankedRows
    GROUP BY region
)
SELECT r.customer_id, r.region, r.days_realloc, r.row_num as 'row_num_80th'
FROM RankedRows r
JOIN MedianRowNum m
ON r.region = m.region AND r.row_num = m.median_row_num;

WITH RankedRows AS (
    SELECT
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY days_realloc) AS row_num,
        customer_id,
        region,
        days_realloc
    FROM (
        SELECT customer_id, region, ROUND(AVG(days), 0) AS days_realloc 
        FROM (
            SELECT customer_id, region_name AS region, node_id, c.region_id, end_date, start_date, DATEDIFF(end_date, start_date) AS days 
            FROM customer_nodes AS c
            JOIN regions AS r ON c.region_id = r.region_id
        ) subquery 
        GROUP BY customer_id, region
    ) subquery2
),
MedianRowNum AS (
    SELECT region, ROUND(MAX(row_num) *0.95, 0) AS median_row_num
    FROM RankedRows
    GROUP BY region
)
SELECT r.customer_id, r.region, r.days_realloc, r.row_num as 'row_num_95th'
FROM RankedRows r
JOIN MedianRowNum m
ON r.region = m.region AND r.row_num = m.median_row_num;


-- B. Customer Transactions
-- What is the unique count and total amount for each transaction type?
select txn_type, count(*) as deposits, sum(txn_amount) as amounts
FROM customer_transactions
group by txn_type;

-- What is the average total historical deposit counts and amounts for all customers?
select count(customer_id) as deposits, avg(txn_amount) as avg_amount
FROM customer_transactions
where txn_type = 'deposit';

-- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
select customer_id,
    MAX(CASE WHEN rolling_total_1 = 0 THEN 0 ELSE rolling_total_1 END) AS rolling_total_1,
    MAX(CASE WHEN rolling_total_2 = 0 THEN rolling_total_1 ELSE rolling_total_1+rolling_total_2 END) AS rolling_total_2,
    MAX(CASE WHEN rolling_total_3 = 0 THEN rolling_total_1+rolling_total_2 ELSE rolling_total_1+rolling_total_2+rolling_total_3 END) AS rolling_total_3,
    MAX(CASE WHEN rolling_total_4 = 0  THEN rolling_total_1+rolling_total_2+rolling_total_3 ELSE rolling_total_1+rolling_total_2+rolling_total_3+rolling_total_4 END) AS rolling_total_4
from (WITH rolling_totals AS (
    SELECT 
        customer_id,
        MONTH(txn_date) AS months, 
        SUM(deposits) AS deposits, 
        SUM(purchases) AS purchases, 
        SUM(withdrawals) AS withdrawals,
        SUM(deposits + purchases + withdrawals) AS month_balance,
        SUM(SUM(deposits + purchases + withdrawals)) OVER (PARTITION BY customer_id ORDER BY MONTH(txn_date)) AS rolling_total
    FROM (
        SELECT *,
            CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END AS deposits,
            CASE WHEN txn_type = 'purchase' THEN txn_amount ELSE 0 END AS purchases,
            CASE WHEN txn_type = 'withdrawal' THEN txn_amount ELSE 0 END AS withdrawals
        FROM customer_transactions
    ) subquery
    GROUP BY customer_id, MONTH(txn_date)
),
cumulative_totals AS (
    SELECT
        customer_id,
        months,
        rolling_total,
        SUM(rolling_total) OVER (PARTITION BY customer_id ORDER BY months ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_total
    FROM rolling_totals
)
SELECT 
    customer_id,
    MAX(CASE WHEN months = 1 THEN cumulative_total ELSE 0 END) AS rolling_total_1,
    MAX(CASE WHEN months = 2 THEN cumulative_total ELSE 0 END) AS rolling_total_2,
    MAX(CASE WHEN months = 3 THEN cumulative_total ELSE 0 END) AS rolling_total_3,
    MAX(CASE WHEN months = 4 THEN cumulative_total ELSE 0 END) AS rolling_total_4
FROM cumulative_totals
GROUP BY customer_id) subquery
group by customer_id;

-- What is the percentage of customers who increase their closing balance by more than 5%?

-- C. Data Allocation Challenge
-- To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

-- Option 1: data is allocated based off the amount of money at the end of the previous month
-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
-- Option 3: data is updated real-time
-- For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
-- running customer balance column that includes the impact each transaction
-- customer balance at the end of each month
-- minimum, average and maximum values of the running balance for each customer
-- Using all of the data available - how much data would have been required for each option on a monthly basis?

-- D. Extra Challenge
-- Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.
-- If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data wo-- uld be required for this option on a monthly basis?

-- Special notes:
-- Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!
-- Extension Request
-- The Data Bank team wants you to use the outputs generated from the above sections to create a quick Powerpoint presentation which will be used as marketing materials for both external investors who might want to buy Data Bank shares and new prospective customers who might want to bank with Data Bank.
-- Using the outputs generated from the customer node questions, generate a few headline insights which Data Bank might use to market it’s world-leading security features to potential investors and customers.
-- With the transaction analysis - prepare a 1 page presentation slide which contains all the relevant information about the various options for the data provisioning so the Data Bank management team can make an informed decision.