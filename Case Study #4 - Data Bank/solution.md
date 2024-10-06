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
select sum(conditions) as customers
from(
SELECT 
    customer,
    months,
    CASE 
        WHEN deposits >= 1 AND purchase >= 1 THEN 1
        WHEN deposits >= 1 AND withdrawal >= 1 THEN 1
        ELSE 0
    END AS conditions
FROM (
    SELECT 
        customer_id AS customer,
        MONTH(txn_date) AS months,
        SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposits,
        SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal
    FROM 
        customer_transactions
    GROUP BY 
        customer_id, MONTH(txn_date)
) subquery
GROUP BY 
    customer, months) subquery2;


-- What is the closing balance for each customer at the end of the month?
CREATE VIEW customer_balance AS 
select customer_id as customer,
    MAX(CASE WHEN rolling_total_1 = 0 THEN 0 ELSE rolling_total_1 END) AS rolling_total_m1,
	MAX(CASE WHEN rolling_total_2 <> 0 THEN rolling_total_2 ELSE CASE WHEN rolling_total_1 = 0 THEN 0 ELSE rolling_total_1 END END) AS rolling_total_m2,
    MAX(CASE WHEN rolling_total_3 <> 0 THEN rolling_total_3 ELSE CASE WHEN rolling_total_2 <> 0 THEN rolling_total_2 ELSE CASE WHEN rolling_total_1 = 0 THEN 0 ELSE rolling_total_1 END END END) AS rolling_total_m3,
    MAX(CASE WHEN rolling_total_4 <> 0 THEN rolling_total_4 ELSE CASE WHEN rolling_total_3 <> 0 THEN rolling_total_3 ELSE CASE WHEN rolling_total_2 <> 0 THEN rolling_total_2 ELSE CASE WHEN rolling_total_1 = 0 THEN 0 ELSE rolling_total_1 END END END END) AS rolling_total_m4
FROM(
	SELECT 
    customer_id,
    MAX(CASE WHEN months = 1 THEN rolling_total ELSE 0 END) AS rolling_total_1,
    MAX(CASE WHEN months = 2 THEN rolling_total ELSE 0 END) AS rolling_total_2,
    MAX(CASE WHEN months = 3 THEN rolling_total ELSE 0 END) AS rolling_total_3,
    MAX(CASE WHEN months = 4 THEN rolling_total ELSE 0 END) AS rolling_total_4
	FROM (
		SELECT 
			customer_id,
            MONTH(txn_date) AS months, 
            SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END) AS deposits,
            SUM(CASE WHEN txn_type = 'purchase' THEN txn_amount ELSE 0 END) AS purchases,
            SUM(CASE WHEN txn_type = 'withdrawal' THEN txn_amount ELSE 0 END) AS withdrawals,
            SUM(txn_amount) AS month_balance,
            SUM(SUM(txn_amount)) OVER (PARTITION BY customer_id ORDER BY MONTH(txn_date)) AS rolling_total
            FROM customer_transactions
            GROUP BY customer_id, MONTH(txn_date))subquery
            GROUP BY customer_id) subquery2
            GROUP BY customer_id;

-- What is the percentage of customers who increase their closing balance by more than 5%?
WITH classified_customers AS (
    SELECT *, 
           ROUND((rolling_total_m1 / rolling_total_m4) * 100, 2) AS increase_percentage,
           CASE 
               WHEN (rolling_total_m1 / rolling_total_m4) * 100 > 5 
               THEN '>5%' 
               ELSE '<=5%' 
           END AS increase
    FROM customer_balance
)
SELECT 
    increase,
    COUNT(*) AS customer_count,
    (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM classified_customers)) AS percentage
FROM classified_customers
GROUP BY increase;


-- C. Data Allocation Challenge
-- To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:
-- Option 1: data is allocated based off the amount of money at the end of the previous month
-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
-- Option 3: data is updated real-time
-- For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
-- running customer balance column that includes the impact each transaction

SELECT 
    customer_id, 
    txn_date, 
    txn_type, 
    txn_amount,
    SUM(
        CASE 
            WHEN txn_type = 'deposit' THEN txn_amount 
            WHEN txn_type = 'withdrawal' THEN -txn_amount
            ELSE 0 
        END
    ) OVER (PARTITION BY customer_id ORDER BY txn_date) AS running_balance
FROM 
    customer_transactions
ORDER BY 
    customer_id, txn_date;

-- customer balance at the end of each month
SELECT 
    customer_id,
    LAST_DAY(txn_date) AS month_end_date,
    running_balance
FROM (
    SELECT 
        customer_id, 
        txn_date, 
        txn_type, 
        txn_amount,
        SUM(
            CASE 
                WHEN txn_type = 'deposit' THEN txn_amount 
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0 
            END
        ) OVER (PARTITION BY customer_id ORDER BY txn_date) AS running_balance
    FROM 
        customer_transactions
) AS DailyBalances
WHERE txn_date = LAST_DAY(txn_date)
ORDER BY customer_id, month_end_date;

-- minimum, average and maximum values of the running balance for each customer
SELECT 
    customer_id,
    MIN(running_balance) AS min_balance,
    round(AVG(running_balance),0) AS avg_balance,
    MAX(running_balance) AS max_balance
FROM (
    SELECT 
        customer_id, 
        txn_date, 
        txn_type, 
        txn_amount,
        @bal := CASE 
            WHEN @cust = customer_id THEN @bal + CASE txn_type 
                WHEN 'deposit' THEN txn_amount
                WHEN 'withdrawal' THEN -txn_amount
                ELSE 0
            END
            ELSE txn_amount
        END AS running_balance,
        @cust := customer_id
    FROM 
        customer_transactions,
        (SELECT @bal := 0, @cust := NULL) AS vars
    ORDER BY 
        customer_id, txn_date
) AS RunningBalances
GROUP BY 
    customer_id;

-- Using all of the data available - how much data would have been required for each option on a monthly basis?
SELECT
    MONTH(txn_date) AS months,
    COUNT(txn_amount) AS count
FROM
    customer_transactions
WHERE
    txn_type = 'deposit' OR txn_type = 'withdrawal'
GROUP BY
    months;

-- D. Extra Challenge
-- Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, 
-- just like in a traditional savings account you might have with a bank.
-- If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, 
-- how much data would be required for this option on a monthly basis?

-- Special notes:
-- Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!
-- Assuming an initial data allocation of 100 units for simplicity
WITH DataAllocations AS (
    SELECT 
        customer_id,
        100 AS initial_allocation -- Assuming initial allocation is 100 units, modify as necessary
    FROM 
        customer_transactions
    GROUP BY
        customer_id
),
InterestCalculation AS (
    SELECT
        customer_id,
        initial_allocation,
        initial_allocation + (initial_allocation * 0.06 / 365 * 30) AS allocation_after_one_month
    FROM 
        DataAllocations
)
SELECT 
    customer_id,
    initial_allocation,
    allocation_after_one_month
FROM 
    InterestCalculation;

-- Assuming an initial data allocation of 100 units for simplicity
WITH DataAllocations AS (
    SELECT 
        customer_id,
        100 AS initial_allocation -- Assuming initial allocation is 100 units, modify as necessary
    FROM 
        customer_transactions
    GROUP BY
        customer_id
),
CompoundingInterestCalculation AS (
    SELECT
        customer_id,
        initial_allocation,
        initial_allocation * POWER(1 + (0.06 / 365), 30) AS allocation_after_one_month
    FROM 
        DataAllocations
)
SELECT 
    customer_id,
    initial_allocation,
    round(allocation_after_one_month,2) as allocation_after_one_month
FROM 
    CompoundingInterestCalculation;

-- Extension Request
-- The Data Bank team wants you to use the outputs generated from the above sections to create a quick Powerpoint presentation which will be used as marketing materials for both external investors who might want to buy Data Bank shares and new prospective customers who might want to bank with Data Bank.
-- Using the outputs generated from the customer node questions, generate a few headline insights which Data Bank might use to market it’s world-leading security features to potential investors and customers.
-- With the transaction analysis - prepare a 1 page presentation slide which contains all the relevant information about the various options for the data provisioning so the Data Bank management team can make an informed decision.
