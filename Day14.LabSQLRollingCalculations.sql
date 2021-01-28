/*Lab | SQL Rolling calculations
In this lab, you will be using the Sakila database of movie rentals.

Instructions
Q1 Get number of monthly active customers.

Q2 Active users in the previous month.

Q3 Percentage change in the number of active customers.

Q4 Retained customers every month.

RESEARCH*/
USE sakila;

SELECT * FROM sakila.customer AS c
JOIN sakila.rental AS r
on r.customer_id = c.customer_id
WHERE c.active = 0;

#Using only rental table as customer "active" status was the last status and didnt
#repressent historcial rental activity.

## QUESTION 1
#Q1 Get number of monthly active customers.

-- Step 1: Get the account_id, date, year, month and month_number for
-- every transaction.
use sakila;
drop view if exists sakila_activity; 
create or replace view sakila_activity as
select customer_id, convert(rental_date, date) as Activity_date,
date_format(convert(rental_date,date), '%M') as Activity_Month,
date_format(convert(rental_date,date), '%m') as Activity_Month_number,
date_format(convert(rental_date,date), '%Y') as Activity_year
from sakila.rental;

-- Checking results
select * from sakila.sakila_activity;


-- Step 2:
-- Computing the total number of active users by Year and Month with group by
-- and sorting according to year and month NUMBER.
select Activity_year, Activity_Month, count(customer_id) as Active_users from sakila.sakila_activity
group by Activity_year, Activity_Month
order by Activity_year asc, Activity_Month_number asc;

-- Step 3:
-- Storing the results on a view for later use.
drop view sakila.monthly_sakila_activity; 
create view sakila.monthly_sakila_activity as
select Activity_year, Activity_Month, Activity_Month_number, count(customer_id) as Active_users 
from sakila.sakila_activity
group by Activity_year, Activity_Month
order by Activity_year asc, Activity_Month_number asc;

-- Sanity check
select * from sakila.monthly_sakila_activity;


## QUESTION 2
#Q2 Active users in the previous month.


/*
-- Final step:
Compute the difference of `active_users` between one month and the previous one
for each year
using the lag function with lag = 1 (as we want the lag from one previous record)
*/

select 
   Activity_year, 
   Activity_month,
   Active_users, 
   lag(Active_users,1) over (order by Activity_year, Activity_Month_number) as Last_month
from sakila.monthly_sakila_activity;

-- Refining: Getting the difference of monthly active_users month to month.
with cte_sakilaview as (select 
   Activity_year, 
   Activity_month,
   Active_users, 
   lag(Active_users,1) over (order by Activity_year, Activity_Month_number) as Last_month
from sakila.monthly_sakila_activity)
select Activity_year, Activity_month, Active_users, Last_month, (Active_users - Last_month) as Difference from cte_sakilaview;

SELECT * FROM cte_sakilaview;

## QUESTION 3
#Q3 Percentage change in the number of active customers.

with cte_sakilaview as (select 
   Activity_year, 
   Activity_month,
   Active_users, 
   lag(Active_users,1) over (order by Activity_year, Activity_Month_number) as Last_month
from sakila.monthly_sakila_activity)
select Activity_year, Activity_month, Active_users, Last_month, (Active_users - Last_month) as Difference, round((Active_users - Last_month)/Active_users*100,2) as DifferencePerc from cte_sakilaview;


## QUESTION 4
#Q4 Retained customers every month.
select distinct customer_id as Active_id, 
Activity_year, Activity_Month, Activity_month_number 
from sakila.sakila_activity;
drop view sakila.distinct_users;
create view sakila.distinct_customers as 
select distinct customer_id as Active_id, 
Activity_year, Activity_Month, Activity_month_number 
from sakila.sakila_activity;
select * from sakila.distinct_customers;

drop view if exists sakila.retained_customers;
create view sakila.retained_customers as 

select 
   a.Activity_year,
   a.Activity_month,
   a.Activity_month_number,
   count(distinct a.Active_id) as Retained_customers
   from sakila.distinct_customers as a
join sakila.distinct_customers as b
on a.Active_id = b.Active_id 
and b.Activity_month_number = a.Activity_month_number + 1 
group by a.Activity_year, a.Activity_month_number
order by a.Activity_year, a.Activity_month_number;

select * from sakila.retained_customers;
