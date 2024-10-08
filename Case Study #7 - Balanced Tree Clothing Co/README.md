# Case Study #7: Balanced Tree Clothing Co.

<img src="https://8weeksqlchallenge.com/images/case-study-designs/7.png" alt="Image" width="300" height="300">

## Introduction

Balanced Tree Clothing Company prides themselves on providing an optimised range of clothing and lifestyle wear for the modern adventurer!

Danny, the CEO of this trendy fashion company has asked you to assist the team’s merchandising teams analyse their sales performance and generate a basic financial report to share with the wider business.

## Data
### Relationship diagram
For this case study there is a total of 4 datasets for this case study - however you will only need to utilise 2 main tables to solve all of the regular questions, and the additional 2 tables are used only for the bonus challenge question!

![image](https://user-images.githubusercontent.com/101379141/199987521-b92c9ea7-3aa3-499f-9480-f05b31de9b58.png)

![image](https://user-images.githubusercontent.com/101379141/199987654-65cb6974-93c2-4c17-83ba-78f0ca7af532.png)

![image](https://user-images.githubusercontent.com/101379141/199987769-fb0a7363-d025-4d15-951e-6e779b733df6.png)

![image](https://user-images.githubusercontent.com/101379141/199987882-85b57005-baa6-4dfc-8199-5b5d45c4ccc0.png)

![image](https://user-images.githubusercontent.com/101379141/199987928-3da7a54c-a7e7-4a0d-8483-4c865d7acb85.png)

### Source data
[Click here](https://8weeksqlchallenge.com/case-study-7/).

## Task Questions

### A. High Level Sales Analysis

1. What was the total quantity sold for all products?
2. What is the total generated revenue for all products before discounts?
3. What was the total discount amount for all products?

***

### B. Transaction Analysis

1. How many unique transactions were there?
2. What is the average unique products purchased in each transaction?
3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
4. What is the average discount value per transaction?
5. What is the percentage split of all transactions for members vs non-members?
6. What is the average revenue for member transactions and non-member transactions?
***

### C. Product Analysis

1. What are the top 3 products by total revenue before discount?
2. What is the total quantity, revenue and discount for each segment?
3. What is the top selling product for each segment?
4. What is the total quantity, revenue and discount for each category?
5. What is the top selling product for each category?
6. What is the percentage split of revenue by product for each segment?
7. What is the percentage split of revenue by segment for each category?
8. What is the percentage split of total revenue by category?
9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
  

***
### D. Reporting Challenge
Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.

Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.

He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).

Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)

***
### E. Bonus Challenge

Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

Hint: you may want to consider using a recursive CTE to solve this problem!

***
### Conclusion
Sales, transactions and product exposure is always going to be a main objective for many data analysts and data scientists when working within a company that sells some type of product - Spoiler alert: nearly all companies will sell products!

Being able to navigate your way around a product hierarchy and understand the different levels of the structures as well as being able to join these details to sales related datasets will be super valuable for anyone wanting to work within a financial, customer or exploratory analytics capacity.

Hopefully these questions helped provide some exposure to the type of analysis we perform daily in these sorts of roles!

***
### Solution
[Click here](https://github.com/bardellis/8_weeks_dannys_challenge/blob/main/Case%20Study%20%237%20-%20Balanced%20Tree%20Clothing%20Co/solution.md)
