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
select node_id, round(avg(days),2) as days_realloc from(
SELECT customer_id, node_id, c.region_id, end_date, start_date, DATEDIFF(end_date, start_date) AS days 
FROM customer_nodes as c
join regions  as r on c.region_id=r.region_id
) subquery group by node_id;

UPDATE customer_nodes
SET customer_nodes.end_date = '2020-12-31'
WHERE customer_nodes.end_date = '9999-12-31';

select count(*), end_date from (select c.region_id, end_date, node_id, start_date FROM customer_nodes as c
join regions  as r on c.region_id=r.region_id
order by end_date desc) subquery
Group by end_date order by end_date desc;

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

-- B. Customer Transactions
-- What is the unique count and total amount for each transaction type?
-- What is the average total historical deposit counts and amounts for all customers?
-- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
-- What is the closing balance for each customer at the end of the month?
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