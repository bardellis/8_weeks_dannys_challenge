-- Case Study Questions
-- This case study is split into an initial data understanding question before diving straight into data analysis questions before finishing with 1 single extension challenge.
-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
select *, 
case when s.plan_id=0 then 1
else 0 end as trial,
case when s.plan_id=1 then 1
else 0 end as basic_monthly,
case when s.plan_id=2 then 1
else 0 end as pro_monthly,
case when s.plan_id=3 then 1
else 0 end as pro_annual,
case when s.plan_id=4 then 1
else 0 end as churn
from subscriptions as s
join plans as p on s.plan_id=p.plan_id;


-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
SELECT 
    subquery.plan_name,
    subquery.price,
    COUNT(subquery.customer_id) as customers,
    SUM(subquery.trial) AS trials,
    SUM(subquery.basic_monthly) AS basics,
    SUM(subquery.pro_monthly) AS monthly,
    SUM(subquery.pro_annual) AS annual,
    SUM(subquery.churn) AS churn
FROM (
	select customer_id, s.plan_id, plan_name, price, 
	case when s.plan_id=0 then 1 else 0 end as trial,
	case when s.plan_id=1 then 1 else 0 end as basic_monthly,
	case when s.plan_id=2 then 1 else 0 end as pro_monthly,
	case when s.plan_id=3 then 1 else 0 end as pro_annual,
	case when s.plan_id=4 then 1 else 0 end as churn
	from subscriptions as s
	join plans as p on s.plan_id=p.plan_id) AS subquery
group by subquery.plan_name,subquery.price;

select plan_name from plans;

-- B. Data Analysis Questions
-- How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS customers
FROM subscriptions;

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT DATE_FORMAT(start_date, '%Y-%m-01') AS month_start,
       COUNT(*) AS trial_count
FROM subscriptions
GROUP BY DATE_FORMAT(start_date, '%Y-%m-01')
ORDER BY trial_count desc;

Use foodie_fi;

-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select p.plan_name as plans, count(p.plan_id) as events
from subscriptions as s
join plans as p on s.plan_id=p.plan_id
where start_date >= 2021-01-01
group by plans;

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
-- select sum(churn) as churn,count(s.plan_id) as totals, plan_name 
-- from(
SELECT
    COUNT(CASE WHEN churn = 1 THEN 1 END) AS churned_customers_count,
    ROUND(COUNT(CASE WHEN churn = 1 THEN 1 END) * 100.0 / COUNT(*), 1) AS churned_customers_percentage
FROM (
    SELECT p.plan_id AS plan_id,
           p.plan_name AS plan_name,
           CASE WHEN p.plan_name = 'churn' THEN 1 ELSE 0 END AS churn
    FROM subscriptions AS s
    JOIN plans AS p ON s.plan_id = p.plan_id
) AS subquery;

-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

select 
sum(churned) as churned, 
count(*) as all_customers, 
round(sum(churned)/count(*),2)*100 as percentage
from
(select 
customer_id, 
trial_date, 
basic_monthly_date, 
pro_monthly_date,
pro_annual_date,  
churn_date,
case when churn_date <> 0 and pro_monthly_date=0 and pro_annual_date=0 and basic_monthly_date=0 then 1 else 0 end as churned
from
(select 
customer_id, 
max(trial_date) as trial_date, 
max(basic_monthly_date) as basic_monthly_date, 
max(pro_monthly_date) as pro_monthly_date,
max(pro_annual_date) as pro_annual_date,  
max(churn_date) as churn_date
	from (select customer_id,
		case when s.plan_id=0 then start_date else 0 end as trial_date,
		case when s.plan_id=1 then start_date else 0 end as basic_monthly_date,
		case when s.plan_id=2 then start_date else 0 end as pro_monthly_date,
		case when s.plan_id=3 then start_date else 0 end as pro_annual_date,
		case when s.plan_id=4 then start_date else 0 end as churn_date
		FROM subscriptions AS s
		JOIN plans AS p ON s.plan_id = p.plan_id) as subquery
		-- where churn_date > 0
	group by customer_id) as subquery2) as subquery3;

-- What is the number and percentage of customer plans after their initial free trial?
SELECT 
    SUM(plan_after_trial) AS plan_after_trial, 
    COUNT(*) AS all_customers, 
    ROUND(SUM(plan_after_trial) / COUNT(*), 2) * 100 AS percentage
FROM
    (select 
customer_id, 
trial_date, 
basic_monthly_date, 
pro_monthly_date,
pro_annual_date,  
churn_date,
case when basic_monthly_date<>0 or pro_monthly_date<>0 or pro_annual_date<>0 then 1 else 0 end as plan_after_trial
from (select 
customer_id, 
max(trial_date) as trial_date, 
max(basic_monthly_date) as basic_monthly_date, 
max(pro_monthly_date) as pro_monthly_date,
max(pro_annual_date) as pro_annual_date,  
max(churn_date) as churn_date
	from (select customer_id,
		case when s.plan_id=0 then start_date else 0 end as trial_date,
		case when s.plan_id=1 then start_date else 0 end as basic_monthly_date,
		case when s.plan_id=2 then start_date else 0 end as pro_monthly_date,
		case when s.plan_id=3 then start_date else 0 end as pro_annual_date,
		case when s.plan_id=4 then start_date else 0 end as churn_date
		FROM subscriptions AS s
		JOIN plans AS p ON s.plan_id = p.plan_id) as subquery
		-- where churn_date > 0
	group by customer_id) as subquery2) as subquery3;

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
select plan_name, count(*) 
from(
	select start_date, plan_name, s.plan_id 
	fROM subscriptions AS s
	JOIN plans AS p ON s.plan_id = p.plan_id
	where start_date <= '2020-12-31'
order by start_date desc) as subquery
group by plan_name;

-- How many customers have upgraded to an annual plan in 2020?
select count(*) as pro_annual_2020 from (select plan_name, start_date, customer_id
fROM subscriptions AS s
JOIN plans AS p ON s.plan_id = p.plan_id
where start_date >= '2020-01-01' and start_date <'2021-01-01' and plan_name = 'pro annual') subquery;


-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
select round(avg(days_to_annual),2) as average_days_to_annual
from( 
	select customer_id, trial, annual, DATEDIFF(annual, trial) AS days_to_annual from
	(select customer_id, max(trial_date) as trial, max(basic_monthly_date) as monthly, max(pro_monthly_date) as monthly_pro, max(pro_annual_date) as annual, max(churn_date) as churn
		from (select customer_id,
		case when s.plan_id=0 then start_date else 0 end as trial_date,
		case when s.plan_id=1 then start_date else 0 end as basic_monthly_date,
		case when s.plan_id=2 then start_date else 0 end as pro_monthly_date,
		case when s.plan_id=3 then start_date else 0 end as pro_annual_date,
		case when s.plan_id=4 then start_date else 0 end as churn_date
		FROM subscriptions AS s
		JOIN plans AS p ON s.plan_id = p.plan_id) as subquery 
	group by customer_id) subquery2
where annual <> 0) subquery3;

-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
select days_to_annual, count(*) as customers from (SELECT customer_id,
CASE 
WHEN days_to_annual <= 30 THEN '0-30 days' 
WHEN days_to_annual > 30 AND days_to_annual <= 60 THEN '31-60 days' 
WHEN days_to_annual > 60 AND days_to_annual <= 120 THEN '61-120 days' 
ELSE '> 120 days' 
END AS days_to_annual
from (select customer_id, trial, annual, DATEDIFF(annual, trial) AS days_to_annual  from (select customer_id, max(trial_date) as trial, max(basic_monthly_date) as monthly, max(pro_monthly_date) as monthly_pro, max(pro_annual_date) as annual, max(churn_date) as churn
		from (select customer_id,
		case when s.plan_id=0 then start_date else 0 end as trial_date,
		case when s.plan_id=1 then start_date else 0 end as basic_monthly_date,
		case when s.plan_id=2 then start_date else 0 end as pro_monthly_date,
		case when s.plan_id=3 then start_date else 0 end as pro_annual_date,
		case when s.plan_id=4 then start_date else 0 end as churn_date
		FROM subscriptions AS s
		JOIN plans AS p ON s.plan_id = p.plan_id) as subquery 
	group by customer_id) as subquery2
    where annual <> 0) as subquery3) as subquery4
    group by days_to_annual;

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
select count(*) as downgrades
from (select customer_id, basic_monthly_date, pro_monthly_date, DATEDIFF(pro_monthly_date, basic_monthly_date) AS days_basic_pro  
from (select customer_id, max(basic_monthly_date) as basic_monthly_date, max(pro_monthly_date) as pro_monthly_date
		from (select customer_id,
		case when s.plan_id=0 then start_date else 0 end as trial_date,
		case when s.plan_id=1 then start_date else 0 end as basic_monthly_date,
		case when s.plan_id=2 then start_date else 0 end as pro_monthly_date,
		case when s.plan_id=3 then start_date else 0 end as pro_annual_date,
		case when s.plan_id=4 then start_date else 0 end as churn_date
		FROM subscriptions AS s
		JOIN plans AS p ON s.plan_id = p.plan_id) as subquery 
	group by customer_id) as subquery2
    where basic_monthly_date <> 0 and pro_monthly_date <> 0
    order by days_basic_pro) as subquery3
    where days_basic_pro <0;

Use foodie_fi;
-- C. Challenge Payment Question
-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
-- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
-- once a customer churns they will no longer make payments

-- cREATE VIEW customer_trial_plan AS
-- QUERY X TRIAL PLAN 
SELECT 
    subquery_since_trial.customer_id,
    subquery_since_trial.plan_id,
    subquery_since_trial.since, 
    subquery_since_trial.to_date, 
    pl.price
FROM (
    SELECT 
        customer_id, 
        CASE 
            WHEN trial_date IS NOT NULL THEN 0 
            ELSE '' 
        END AS plan_id,
        CASE 
            WHEN trial_date IS NOT NULL THEN trial_date 
            ELSE '' 
        END AS since,
        CASE 
            WHEN basic_monthly_date <> 0 THEN basic_monthly_date
            ELSE CASE 
                WHEN pro_monthly_date <> 0 THEN pro_monthly_date 
                ELSE CASE 
                    WHEN pro_annual_date <> 0 THEN pro_annual_date 
                    ELSE CASE 
                        WHEN churn_date <> 0 THEN churn_date 
                        ELSE 0 
                    END 
                END 
            END 
        END AS to_date
    FROM (
        SELECT 
            customer_id,
            MAX(trial_date) AS trial_date,
            MAX(basic_monthly_date) AS basic_monthly_date,
            MAX(pro_monthly_date) AS pro_monthly_date,
            MAX(pro_annual_date) AS pro_annual_date,
            MAX(churn_date) AS churn_date
        FROM (
            SELECT
                customer_id,
                start_date,
                plan_id,
                CASE 
                    WHEN plan_id = 0 THEN start_date 
                    ELSE 0 
                END AS trial_date,
                CASE 
                    WHEN plan_id = 1 THEN start_date 
                    ELSE 0 
                END AS basic_monthly_date,
                CASE 
                    WHEN plan_id = 2 THEN start_date 
                    ELSE 0 
                END AS pro_monthly_date,
                CASE 
                    WHEN plan_id = 3 THEN start_date 
                    ELSE 0 
                END AS pro_annual_date,
                CASE 
                    WHEN plan_id = 4 THEN start_date 
                    ELSE 0 
                END AS churn_date
            FROM subscriptions
            WHERE start_date <= '2020-12-31'
        ) AS subquery
        GROUP BY customer_id
    ) AS subquery_trial
) AS subquery_since_trial
JOIN plans AS pl ON subquery_since_trial.plan_id = pl.plan_id;

-- cREATE VIEW customer_basic_monthly_plan AS
-- QUERY X BASIC MONTH
SELECT 
    subquery_since_basic.customer_id,
    subquery_since_basic.plan_id,
    subquery_since_basic.since, 
    subquery_since_basic.to_date, 
    pl.price
FROM (
    SELECT 
        customer_id, 
        CASE 
            WHEN basic_monthly_date IS NOT NULL THEN 1 
            ELSE '' 
        END AS plan_id,
        CASE 
            WHEN basic_monthly_date IS NOT NULL THEN basic_monthly_date 
            ELSE '' 
        END AS since,
        CASE 
            WHEN pro_monthly_date <> 0 AND pro_monthly_date > basic_monthly_date THEN pro_monthly_date 
            ELSE CASE 
                WHEN pro_annual_date <> 0 AND pro_annual_date > basic_monthly_date THEN pro_annual_date 
                ELSE CASE 
                    WHEN churn_date <> 0 THEN churn_date 
                    ELSE '2020-12-31' 
                END 
            END 
        END AS to_date
    FROM (
        SELECT 
            customer_id,
            MAX(basic_monthly_date) AS basic_monthly_date,
            MAX(pro_monthly_date) AS pro_monthly_date,
            MAX(pro_annual_date) AS pro_annual_date,
            MAX(churn_date) AS churn_date
        FROM (
            SELECT
                customer_id,
                start_date,
                plan_id,
                CASE 
                    WHEN plan_id = 1 THEN start_date 
                    ELSE 0 
                END AS basic_monthly_date,
                CASE 
                    WHEN plan_id = 2 THEN start_date 
                    ELSE 0 
                END AS pro_monthly_date,
                CASE 
                    WHEN plan_id = 3 THEN start_date 
                    ELSE 0 
                END AS pro_annual_date,
                CASE 
                    WHEN plan_id = 4 THEN start_date 
                    ELSE 0 
                END AS churn_date
            FROM subscriptions
            WHERE start_date <= '2020-12-31'
        ) AS subquery
        GROUP BY customer_id
    ) AS subquery_basic
) AS subquery_since_basic
JOIN plans AS pl ON subquery_since_basic.plan_id = pl.plan_id
WHERE since <> '';


-- CREATE VIEW customer_pro_monthly_plan AS
-- QUERY X PRO MONTH
SELECT 
    subquery_since_pro.customer_id,
    subquery_since_pro.plan_id,
    subquery_since_pro.since, 
    subquery_since_pro.to_date, 
    pl.price
FROM (
    SELECT 
        customer_id, 
        CASE 
            WHEN pro_monthly_date IS NOT NULL THEN 2 
            ELSE '' 
        END AS plan_id,
        CASE 
            WHEN pro_monthly_date IS NOT NULL THEN pro_monthly_date 
            ELSE '' 
        END AS since,
        CASE 
            WHEN basic_monthly_date <> 0 AND basic_monthly_date > pro_monthly_date THEN basic_monthly_date
            ELSE CASE 
                WHEN pro_annual_date <> 0 AND pro_annual_date > pro_monthly_date THEN pro_annual_date 
                ELSE CASE 
                    WHEN churn_date <> 0 THEN churn_date 
                    ELSE '2020-12-31' 
                END 
            END 
        END AS to_date
    FROM (
        SELECT 
            customer_id,
            MAX(basic_monthly_date) AS basic_monthly_date,
            MAX(pro_monthly_date) AS pro_monthly_date,
            MAX(pro_annual_date) AS pro_annual_date,
            MAX(churn_date) AS churn_date
        FROM (
            SELECT
                customer_id,
                start_date,
                plan_id,
                CASE 
                    WHEN plan_id = 1 THEN start_date 
                    ELSE 0 
                END AS basic_monthly_date,
                CASE 
                    WHEN plan_id = 2 THEN start_date 
                    ELSE 0 
                END AS pro_monthly_date,
                CASE 
                    WHEN plan_id = 3 THEN start_date 
                    ELSE 0 
                END AS pro_annual_date,
                CASE 
                    WHEN plan_id = 4 THEN start_date 
                    ELSE 0 
                END AS churn_date
            FROM subscriptions
            WHERE start_date <= '2020-12-31'
        ) AS subquery
        GROUP BY customer_id
    ) AS subquery_pro
) AS subquery_since_pro
JOIN plans AS pl ON subquery_since_pro.plan_id = pl.plan_id
WHERE since <> '';


-- CREATE VIEW customer_pro_annual_plan AS
-- QUERY X PRO ANNUAL
SELECT 
    subquery_since_proa.customer_id,
    subquery_since_proa.plan_id,
    subquery_since_proa.since, 
    subquery_since_proa.to_date, 
    pl.price
FROM (
    SELECT 
        customer_id, 
        CASE 
            WHEN pro_annual_date IS NOT NULL THEN 3 
            ELSE '' 
        END AS plan_id,
        CASE 
            WHEN pro_annual_date IS NOT NULL THEN pro_annual_date 
            ELSE '' 
        END AS since,
        CASE 
            WHEN basic_monthly_date <> 0 AND basic_monthly_date > pro_annual_date THEN basic_monthly_date
            ELSE CASE 
                WHEN pro_monthly_date <> 0 AND pro_monthly_date > pro_annual_date THEN pro_monthly_date 
                ELSE CASE 
                    WHEN churn_date <> 0 THEN churn_date 
                    ELSE '2020-12-31' 
                END 
            END 
        END AS to_date
    FROM (
        SELECT 
            customer_id,
            MAX(basic_monthly_date) AS basic_monthly_date,
            MAX(pro_monthly_date) AS pro_monthly_date,
            MAX(pro_annual_date) AS pro_annual_date,
            MAX(churn_date) AS churn_date
        FROM (
            SELECT
                customer_id,
                start_date,
                plan_id,
                CASE 
                    WHEN plan_id = 1 THEN start_date 
                    ELSE 0 
                END AS basic_monthly_date,
                CASE 
                    WHEN plan_id = 2 THEN start_date 
                    ELSE 0 
                END AS pro_monthly_date,
                CASE 
                    WHEN plan_id = 3 THEN start_date 
                    ELSE 0 
                END AS pro_annual_date,
                CASE 
                    WHEN plan_id = 4 THEN start_date 
                    ELSE 0 
                END AS churn_date
            FROM subscriptions
            WHERE start_date <= '2020-12-31'
        ) AS subquery
        GROUP BY customer_id
    ) AS subquery_proa
) AS subquery_since_proa
JOIN plans AS pl ON subquery_since_proa.plan_id = pl.plan_id
WHERE since <> '';

-- select * from customer_churn;
-- CREATE VIEW customer_churn AS
-- QUERY X CHURN
SELECT 
    subquery_since_proa.customer_id,
    subquery_since_proa.plan_id,
    subquery_since_proa.since, 
    subquery_since_proa.to_date, 
    pl.price
FROM (
    SELECT 
        customer_id, 
        CASE 
            WHEN churn_date IS NOT NULL THEN 4 
            ELSE '' 
        END AS plan_id,
        CASE 
            WHEN churn_date IS NOT NULL THEN churn_date 
            ELSE '' 
        END AS since,
        CASE 
            WHEN basic_monthly_date > churn_date THEN basic_monthly_date
            ELSE CASE 
                WHEN pro_monthly_date > churn_date THEN pro_monthly_date 
                ELSE CASE 
                    WHEN pro_annual_date > churn_date THEN pro_annual_date 
                    ELSE '2020-12-31' 
                END 
            END 
        END AS to_date
    FROM (
        SELECT 
            customer_id,
            MAX(basic_monthly_date) AS basic_monthly_date,
            MAX(pro_monthly_date) AS pro_monthly_date,
            MAX(pro_annual_date) AS pro_annual_date,
            MAX(churn_date) AS churn_date
        FROM (
            SELECT
                customer_id,
                start_date,
                plan_id,
                CASE 
                    WHEN plan_id = 1 THEN start_date 
                    ELSE 0 
                END AS basic_monthly_date,
                CASE 
                    WHEN plan_id = 2 THEN start_date 
                    ELSE 0 
                END AS pro_monthly_date,
                CASE 
                    WHEN plan_id = 3 THEN start_date 
                    ELSE 0 
                END AS pro_annual_date,
                CASE 
                    WHEN plan_id = 4 THEN start_date 
                    ELSE 0 
                END AS churn_date
            FROM subscriptions
            WHERE start_date <= '2020-12-31'
        ) AS subquery
        GROUP BY customer_id
    ) AS subquery_proa
) AS subquery_since_proa
JOIN plans AS pl ON subquery_since_proa.plan_id = pl.plan_id
WHERE since <> '';


CREATE VIEW customer_periods AS;
SELECT * FROM customer_churn
UNION
SELECT * FROM customer_pro_monthly_plan
UNION
SELECT * FROM customer_pro_annual_plan
UNION
SELECT * FROM customer_basic_monthly_plan
UNION
SELECT * FROM customer_trial_plan;

-- ALL TOGETHER
SELECT 
    CASE 
        WHEN grouping(subquery3.plan) = 1 THEN 'Total' 
        ELSE subquery3.plan 
    END AS plan_name,
    COUNT(customer) AS customer,
    ROUND(AVG(price),2) AS price,
    ROUND(SUM(periods),2) AS periods,
    ROUND(SUM(payments),2) AS paid
FROM (
    SELECT subquery2.*,
           ROUND((price*periods),2) AS payments
    FROM (
        SELECT 
            subquery.*,
            CASE 
                WHEN subquery.plan = 0 THEN 
                    (DATE_FORMAT(to_date, '%m')-DATE_FORMAT(since,'%m'))
                ELSE 
                    ((DATE_FORMAT(to_date, '%m')-DATE_FORMAT(since,'%m'))-1) 
            END AS periods
        FROM (
            SELECT 
                s.customer_id AS customer,
                s.plan_id AS plan,
                since, 
                to_date, 
                price
            FROM subscriptions AS s
            JOIN customer_periods AS ct ON s.plan_id = ct.plan_id AND s.customer_id = ct.customer_id
            WHERE s.start_date <= '2020-12-31'
        ) AS subquery
    ) AS subquery2
) AS subquery3 
-- WHERE plan <> 0 AND plan <> 4
GROUP BY plan
-- ORDER BY plan ASC
WITH ROLLUP;


select * FROM subscriptions AS s
JOIN plans AS p ON s.plan_id = p.plan_id
WHERE s.start_date <= '2020-12-31' AND s.plan_id = 3;

-- D. Outside The Box Questions
-- The following are open ended questions which might be asked during a technical interview for this case study - there are no right or wrong answers, but answers that make sense from both a technical and a business perspective make an amazing impression!

-- How would you calculate the rate of growth for Foodie-Fi?
SELECT 
    CASE 
        WHEN grouping(subquery3.n_month) = 1 THEN 'Total' 
        ELSE subquery3.n_month 
    END AS n_month,
    COUNT(customer) AS customer,
    ROUND(AVG(price), 2) AS price,
    ROUND(SUM(periods), 2) AS periods,
    ROUND(SUM(payments), 2) AS paid
FROM (
    SELECT 
        subquery2.*,
        ROUND((price * periods), 2) AS payments
    FROM (
        SELECT 
            subquery.*,
            CASE 
                WHEN subquery.plan = 0 THEN 
                    (DATE_FORMAT(to_date, '%m') - DATE_FORMAT(since, '%m'))
                ELSE 
                    ((DATE_FORMAT(to_date, '%m') - DATE_FORMAT(since, '%m')) - 1) 
            END AS periods
        FROM (
            SELECT 
                s.customer_id AS customer,
                s.plan_id AS plan,
                since, 
                to_date, 
                DATE_FORMAT(since, '%m') AS n_month,
                price
            FROM subscriptions AS s
            JOIN customer_periods AS ct ON s.plan_id = ct.plan_id AND s.customer_id = ct.customer_id
            WHERE s.start_date <= '2020-12-31'
        ) AS subquery
    ) AS subquery2
) AS subquery3 
GROUP BY n_month WITH ROLLUP;


-- What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
-- churn/trial mes a mes sobre el resto 

SELECT
    subquery4.*,
    (trials + churns + paid_subscriptions) AS Totals,
    ROUND((trials / (trials + churns + paid_subscriptions) * 100), 2) AS 'trials/totals',
    ROUND((churns / (trials + churns + paid_subscriptions) * 100), 2) AS 'churns/totals',
    ROUND((paid_subscriptions / (trials + churns + paid_subscriptions) * 100), 2) AS 'paid_subs/totals'
FROM (
    SELECT 
        CASE 
            WHEN grouping(subquery3.n_month) = 1 THEN 'Total' 
            ELSE subquery3.n_month 
        END AS n_month,
        COUNT(customer) AS customer,
        SUM(trial) AS trials,
        SUM(churn) AS churns,
        SUM(paid_subscr) AS paid_subscriptions
    FROM (
        SELECT subquery2.*
        FROM (
            SELECT 
                subquery.*,
                CASE 
                    WHEN subquery.plan = 0 THEN 1 
                    ELSE 0 
                END AS trial,
                CASE 
                    WHEN subquery.plan = 4 THEN 1 
                    ELSE 0 
                END AS churn,
                CASE 
                    WHEN subquery.plan > 0 AND subquery.plan < 4 THEN 1 
                    ELSE 0 
                END AS paid_subscr
            FROM (
                SELECT 
                    s.customer_id AS customer,
                    s.plan_id AS plan,
                    since, 
                    to_date, 
                    DATE_FORMAT(since, '%m') AS n_month,
                    price
                FROM subscriptions AS s
                JOIN customer_periods AS ct ON s.plan_id = ct.plan_id AND s.customer_id = ct.customer_id
                WHERE s.start_date <= '2020-12-31'
            ) AS subquery
        ) AS subquery2
    ) AS subquery3
    GROUP BY n_month WITH ROLLUP
) AS subquery4;


-- What are some key customer journeys or experiences that you would analyse further to improve customer retention?
-- Answer: churn should be taken into consideration

-- If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
-- Answer: the Foodie team should ask the customers if they are happy with the present subscrition

-- What business levers could the Foodie-Fi team use to reduce the customer churn rate? 
-- Enhance Customer Experience
-- Offer Incentives and Discounts
-- Improve Food Quality and Variety
-- Streamline Order and Delivery Process
-- Collect and Act on Customer Feedback

-- How would you validate the effectiveness of your ideas?
-- A/B Testing: Implement changes or improvements to the platform in different user segments and compare the churn rates between the control group (no changes) and the test group (with changes).

-- Conclusion
-- This case study should reflect realistic questions we usually focus on for all product related analytics requests in a wide variety of industries, especially in the digital space!
