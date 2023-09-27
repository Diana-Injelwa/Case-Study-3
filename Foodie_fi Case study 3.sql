CREATE DATABASE foodie_fi;
USE foodie_fi;

-- Creating plans table
CREATE TABLE plans(
plan_id INT,
plan_name VARCHAR(20),
price DECIMAL(5,2)
);

-- Populating plans table
INSERT INTO plans VALUES
(0, 'trial', 0),
(1, 'basic monthly', 9.90),
(2, 'pro monthly', 19.90),
(3, 'pro annual', 199),
(4, 'churn', null);

SELECT * FROM plans;

-- Creating subscriptions table
CREATE TABLE subscriptions(
customer_id INT,
plan_id INT,
start_date DATE
);

-- Populating subscriptions table
INSERT INTO subscriptions VALUES
(1, 0, '2020-08-01'),
(1, 1, '2020-08-08'),
(2, 0, '2020-09-20'),
(2, 3, '2020-09-27'),
(11, 0, '2020-11-19'),
(11, 4, '2020-11-26'),
(13, 0, '2020-12-15'),
(13, 1, '2020-12-22'),
(13, 2, '2021-03-29'),
(15, 0, '2020-03-17'),
(15, 2, '2020-03-24'),
(15, 4, '2020-04-29'),
(16, 0, '2020-05-31'),
(16, 1, '2020-06-07'),
(16, 3, '2020-10-21'),
(18, 0, '2020-07-06'),
(18, 2, '2020-07-13'),
(19, 0, '2020-06-22'),
(19, 2, '2020-06-29'),
(19, 3, '2020-08-29');

SELECT * FROM subscriptions;

-- PART A. Customer Journey
/* Based off the 8 sample customers provided in the sample
 from the subscriptions table, write a brief description 
 about each customer’s onboarding journey. */

 /* Joining plans and subscriptions table to obtain
 the customer_id, plan_name and start_date which are the
 columns we will need when writing the description */

SELECT customer_id, plan_name, start_date
FROM subscriptions s
JOIN plans p
ON s.plan_id = p.plan_id;

-- DESCRIPTION OF CUSTOMER'S ONBOARDING JOURNEY
/*
Customer ID 1:
Started with a "trial" plan on 8/1/2020.
Later downgraded to "basic monthly" plan on 8/8/2020.

Customer ID 2:
Began with a "trial" plan on 9/20/2020.
Later upgraded to "pro annual" plan on 9/27/2020.

Customer ID 11:
Began with a "trial" plan on 11/19/2020.
Cancelled their foodie_fi subscription on 11/26/2020.

Customer ID 13:
Started with a "trial" plan on 12/15/2020.
Downgraded to "basic monthly" plan on 12/22/2020.
Later upgraded to "pro monthly" plan on 3/29/2021.

Customer ID 15:
Began with a "trial" plan on 3/17/2020.
Automatically continued with "pro monthly" plan on 3/24/2020.
Later cancelled their subscription on 4/29/2020.

Customer ID 16:
Started with a "trial" plan on 5/31/2020.
Downgraded to "basic monthly" plan on 6/7/2020.
Later upgraded to "pro annual" plan on 10/21/2020.

Customer ID 18:
Began with a "trial" plan on 7/6/2020.
Automatically continued with "pro monthly" plan on 7/13/2020.

Customer ID 19:
Started with a "trial" plan on 6/22/2020.
Automatically continued with "pro monthly" plan on 6/29/2020.
Later on upgraded to "pro annual" plan on 8/29/2020.
*/

-- PART B. Data Analysis Questions
/* 1. How many customers has foodie_fi ever had? */
SELECT COUNT(DISTINCT customer_id) AS total_cutomers
FROM subscriptions;

/* 2. What is the monthly distribution of trial plan 
start_date values for our dataset - use the start of the
 month as the group by value? *? */
WITH monthly_dstr AS(
    SELECT 
        plan_name, 
        start_date, 
        MONTHNAME(start_date ) AS month
    FROM subscriptions s
    JOIN plans p
    ON s.plan_id = p.plan_id   
)
SELECT month,
    SUM(CASE WHEN plan_name = 'trial' THEN 1 ELSE 0 END) AS trial_plan_count
FROM monthly_dstr
GROUP BY month;

/* 3. What plan start_date values occur after the 
year 2020 for our dataset? Show the breakdown by count
 of events for each plan_name? */
WITH start_year AS(
    SELECT 
        plan_name,  
        Year(start_date ) AS year
    FROM subscriptions s
    JOIN plans p
    ON s.plan_id = p.plan_id
)
SELECT plan_name, COUNT(*) AS count
FROM start_year
WHERE year > '2020'
GROUP BY plan_name;

/* 4. What is the customer count and percentage 
of customers who have churned rounded to 1 decimal place? */
WITH customers AS(
        SELECT
            COUNT(DISTINCT customer_id) AS total_customers
        FROM subscriptions),
    churned AS(
        SELECT 
            COUNT(*) AS churned_customers
        FROM subscriptions s
        JOIN plans p
        On s.plan_id = p.plan_id
        WHERE plan_name = 'churn') 
SELECT
    churned_customers,
    ROUND((churned_customers / total_customers) * 100, 1) AS percent_of_churned
FROM churned, customers;

/* 5. How many customers have churned straight after their
initial free trial - what percentage is this rounded to the
nearest whole number? */
WITH churned_after_trial AS(
        SELECT count(*) AS churned_after_trial
        FROM(
            SELECT
                customer_id,
                plan_name,
                LEAD(plan_name) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan
            FROM subscriptions s
            JOIN plans p
            ON s.plan_id = p.plan_id   
        ) subquery
        WHERE plan_name = 'trial' AND next_plan = 'churn'),
    customers AS(
        SELECT
            COUNT(DISTINCT customer_id) AS total_customers
        FROM subscriptions)
SELECT
    churned_after_trial,
    ROUND((churned_after_trial / total_customers) * 100, 1) AS percent_churned_after_trial
FROM churned_after_trial, customers;

/* 6. What is the number and percentage of
customer plans after their initial free trial? */

/* 7. What is the customer count and percentage breakdown
of all 5 plan_name values at 2020-12-31? */
WITH customer_count AS(
        SELECT plan_name, COUNT(*) AS customer_count
        FROM subscriptions s
        JOIN plans p
        ON s.plan_id = p.plan_id
        WHERE start_date <= '2020-12-31'
        GROUP BY plan_name),
    total_customers AS(
        SELECT COUNT(*) AS total_customer_count
        FROM subscriptions s
        JOIN plans p
        ON s.plan_id = p.plan_id
        WHERE start_date <= '2020-12-31')
SELECT 
    plan_name,
    customer_count,
    ROUND((customer_count / total_customer_count) * 100, 2) AS percent_breakdown
FROM customer_count, total_customers;

/* 8. How many customers have upgraded to an annual plan in 
2020? */
SELECT COUNT(*) AS annual_plan_customers
FROM(
    SELECT customer_id, plan_name, YEAR(start_date) AS year
    FROM subscriptions s
    JOIN plans p
    ON s.plan_id = p.plan_id
)subquery
WHERE plan_name = 'pro annual' AND year = '2020';

/* 9. How many days on average does it take for a customer 
to an annual plan from the day they join Foodie-Fi? */
SELECT ROUND(AVG(days_to_annual), 0) AS avg_days
FROM(
    SELECT customer_id, 
        DATEDIFF(MAX(start_date), MIN(start_date)) AS days_to_annual
    FROM subscriptions s
    JOIN plans p
    ON s.plan_id = p.plan_id
    WHERE plan_name = 'trial' OR plan_name = 'pro annual'
    GROUP BY customer_id
    HAVING COUNT(DISTINCT plan_name) = 2
)subquery;

/* 10. Can you further breakdown this average value into 
30 day periods (i.e. 0-30 days, 31-60 days etc) */
SELECT
    CASE
        WHEN days_to_annual BETWEEN 0 AND 30 THEN '0-30 days'
        WHEN days_to_annual BETWEEN 31 AND 60 THEN '31-60 days'
        WHEN days_to_annual BETWEEN 61 AND 90 THEN '61-90 days'
        ELSE 'More then 90  days'
    END AS period,
    COUNT(*) AS number_of_customers
FROM(
    SELECT customer_id, 
        DATEDIFF(MAX(start_date), MIN(start_date)) AS days_to_annual
    FROM subscriptions s
    JOIN plans p
    ON s.plan_id = p.plan_id
    WHERE plan_name = 'trial' OR plan_name = 'pro annual'
    GROUP BY customer_id
    HAVING COUNT(DISTINCT plan_name) = 2
) subquery
GROUP BY period;

/* 11. How many customers downgraded from a pro monthly to
a basic monthly plan in 2020? */
SELECT COUNT(*) AS downgrades
FROM(
    SELECT
        customer_id, 
        plan_name, 
        YEAR(start_date) AS year,
        LEAD(plan_name) OVER(PARTITION BY customer_id ORDER BY YEAR(start_date)) AS next_plan
    FROM subscriptions s
    JOIN plans p
    ON s.plan_id = p.plan_id
) subquery
WHERE plan_name = 'trial' AND next_plan = 'basic monthly' AND year = '2020';
