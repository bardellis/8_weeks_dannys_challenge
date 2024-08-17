# Case Study #4: Data Bank
<img src="https://user-images.githubusercontent.com/81607668/130343294-a8dcceb7-b6c3-4006-8ad2-fab2f6905258.png" alt="Image" width="500" height="520">

## Introduction
Danny launched a new initiative, Data Bank which runs **banking activities** and also acts as the world’s most secure distributed **data storage platform**!

Customers are allocated cloud data storage limits which are directly linked to how much money they have in their accounts. 

The management team at Data Bank want to increase their total customer base - but also need some help tracking just how much data storage their customers will need.

This case study is all about calculating metrics, growth and helping the business analyse their data in a smart way to better forecast and plan for their future developments!

## Data
### Source data
[Click here](https://8weeksqlchallenge.com/case-study-4/)

#### Table 1: Regions
This regions table contains the region_id and their respective region_name values.

![image](https://github.com/DooPhiLong/8-Week-SQL-Challenge/assets/120476961/0cd95f52-bdd8-4d31-a30f-5c80935367f5)

#### Table 2: Customer
This table just show the unique customer's id 

![image](https://github.com/DooPhiLong/8-Week-SQL-Challenge/assets/120476961/9f53b9b7-ef81-421e-b777-8c0c47b6efc0)

#### Table 3 : Customer Nodes
Customers are randomly distributed across the nodes according to their region. This random distribution changes frequently to reduce the risk of hackers getting into Data Bank’s system and stealing customer’s money and data!

![image](https://github.com/DooPhiLong/8-Week-SQL-Challenge/assets/120476961/0ea5df7f-f19c-4930-a35c-c2ba06cf9cb1)

#### Table 4 : Customer Transactions
This table stores all customer deposits, withdrawals and purchases made using their Data Bank debit card.

![image](https://github.com/DooPhiLong/8-Week-SQL-Challenge/assets/120476961/c5a8f89b-eb70-4a15-9503-a788a39aeee1)

##  Task Questions

### A. Customer Nodes Exploration
1. How many unique nodes are there on the Data Bank system?
2. What is the number of nodes per region?
3. How many customers are allocated to each region?
4. How many days on average are customers reallocated to a different node?
5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

### B. Customer Transactions
1. What is the unique count and total amount for each transaction type?
2. What is the average total historical deposit counts and amounts for all customers?
3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
4. What is the closing balance for each customer at the end of the month?
5. What is the percentage of customers who increase their closing balance by more than 5%?

### C. Data Allocation Challenge
To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

- Option 1: data is allocated based off the amount of money at the end of the previous month
- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
- Option 3: data is updated real-time
For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

- running customer balance column that includes the impact each transaction
- customer balance at the end of each month
- minimum, average and maximum values of the running balance for each customer
Using all of the data available - how much data would have been required for each option on a monthly basis?

### D. Extra Challenge
Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.

If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?

Special notes:

- Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!

### Extension Request
The Data Bank team wants you to use the outputs generated from the above sections to create a quick Powerpoint presentation which will be used as marketing materials for both external investors who might want to buy Data Bank shares and new prospective customers who might want to bank with Data Bank.

1. Using the outputs generated from the customer node questions, generate a few headline insights which Data Bank might use to market it’s world-leading security features to potential investors and customers.

2. With the transaction analysis - prepare a 1 page presentation slide which contains all the relevant information about the various options for the data provisioning so the Data Bank management team can make an informed decision.

### Conclusion
This case study aims to mimic traditional banking style transactions data but with a twist - hopefully it can give you some insight into the types of datasets you might encounter in a customer banking scenario.

Ready for the next 8 Week SQL challenge case study? Click on the banner below to get started with case study #5!
