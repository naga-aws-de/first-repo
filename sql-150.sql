use zero_analyst;
# 01 Write the SQL query to find the second highest salary
# Find the department-wise top 2 highest salaries  
# Find employees earning more than the average salary of their department 
#SELECT * FROM employees01(name, department, salary)

# 01-solution
select name,department,salary from (
select name,department,salary,dense_rank() over(order by salary desc) as salary_rank
from employees01) as sub_query
where salary_rank=2;

# department wise salary
select name,department,salary from (
select name,department,salary,dense_rank() over(partition by department order by salary desc) as salary_rank
from employees01) as sub_query
where salary_rank=2;

# more than avg salary
select e.name,e.department,e.salary from employees01 e where e.salary > (select avg(f.salary) from employees01 f where e.department=f.department);

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------
# 02 write an SQL query to calculate the total  numbers of returned orders for each month 
# Find the return rate (%) per month
# Find the top 3 highest value returned orders
# Find customers (if added later) who returned more than 1 order in a month
-- select * from orders02;(OrderID, OrderDate, TotalAmount) 
-- select * from returns02;(ReturnID, OrderID)

-- 02 write an SQL query to calculate the total  numbers of returned orders for each month
select date_format(o.orderdate,"%Y-%m") as month,
	   count(r.returnid) as total_returns_per_month
from returns02 r left join orders02 o on r.orderid=o.orderid
group by date_format(o.orderdate,"%Y-%m")
order by date_format(o.orderdate,"%Y-%m") desc;

-- Find the return rate (%) per month
select
date_format(orderdate,"%Y-%m") as month,
count(r.returnid),
count(o.orderid),
count(r.returnid)/count(o.orderid) as return_rate_per_month
from returns02 r right join orders02 o  on r.orderid=o.orderid
group by date_format(orderdate,"%Y-%m");


# Find the top 3 highest value returned orders

select r.returnid,o.orderid,o.orderdate,o.totalamount
from returns02 r left join orders02 o on r.orderid=o.orderid
order by o.totalamount desc limit 3

-- --------------------------------------------------------------------------------------------------------------------------------------------
# 03 Write SQL query to find the top-selling products in each category
# Find the total quantity sold and average quantity sold per category
# Find products that sold more than the category average   
-- SELECT * FROm products03;(product_id, product_name, category, quantity_sold)

# 03 Write SQL query to find the top-selling products in each category

select category,product_name from (
select product_name,category,
dense_rank() over(partition by category order by quantity_sold) as top_product_by_category
from products03) as sub_table
where top_product_by_category=1;

# Find the total quantity sold and average quantity sold per category
select 
	category,
	sum(quantity_sold) as total_quantity_sold,
	avg(quantity_sold) as avg_quantity_sold
from products03
group by 1;

# Find products that sold more than the category average 

with avg_sold_by_category as 
(
select 
	category,
	sum(quantity_sold) as total_quantity_sold,
	avg(quantity_sold) as avg_quantity_sold
from products03
group by 1
)
select 
p.product_name,
p.category 
from products03 p join avg_sold_by_category a
on p.category=a.category
where a.total_quantity_sold > a.avg_quantity_sold;

-- -----------------------------------------------------------------------------------------------------------------------------------------

# 04 Find the top 2 products in the top 2 categories based on spend amount? SELECT * FROM orders04;
# Find the monthly highest spending product per category
# Find the users who contributed the most spend to each of the top 3 products overall
# SELECT * FROM orders04;(category,product,user_id,spend,transaction_date)

# Find the top 2 products in the top 2 categories based on spend amount? SELECT * FROM orders04;

with top_categories as 
(
select 
category,
sum(spend) as spend_by_category,
dense_rank() over(order by sum(spend) desc) as category_rank
from orders04 
group by category
),
top_2_categories as 
(
select category from top_categories where category_rank <=2
),
top_products as 
(
select category,product,
dense_rank() over(partition by category order by sum(spend) desc) as product_rank
from orders04
group by category,product
)
select tp.category,tp.product
from top_products tp
inner join top_2_categories tc
on tp.category=tc.category
where tp.product_rank <=2;


# Find the monthly highest spending product per category orders04;(category,product,user_id,spend,transaction_date)
select * from (
select 
date_format(transaction_date,"%Y-%m") as month,
category,
product,
sum(spend) as total_spend,
dense_rank() over(partition by date_format(transaction_date,"%Y-%m"),category order by sum(spend) desc) as drnk_product_per_category
from orders04
group by date_format(transaction_date,"%Y-%m") ,
category,
product) as sub_query
where drnk_product_per_category <=1;


# Find the users who contributed the most spend to each of the top 3 products overall
-- (category,product,user_id,spend,transaction_date)


WITH product_totals AS (
    SELECT 
        product,
        SUM(spend) AS total_spend,
        dense_rank() OVER (ORDER BY SUM(spend) DESC) AS prod_rank
    FROM orders04
    GROUP BY product
),
top_products AS (
    SELECT product
    FROM product_totals
    WHERE prod_rank <= 3
),
user_rank as (
select 
o.product,
o.user_id,
sum(spend) as user_spend,
dense_rank() over(partition by o.product order by sum(spend) desc ) as user_ranks
from orders04 o
where o.product in (select product from top_products)
group by o.product,o.user_id
)
SELECT product, user_id, user_spend
FROM user_rank
WHERE user_ranks = 1
ORDER BY product;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------

# 06 who has not done purchase in last month (orders) 

select distinct c.customer_id,c.name,c.email,o.*
from customers06 c
left join orders06 o
on c.customer_id=o.customer_id
and order_date > date_sub(current_date(),interval 1 month) where o.order_id is null;

# List loyal customers who made a purchase in every month for the last 3 months

with recent_orders as (
select 
customer_id,
date_format(order_date,"%Y-%m") as month
from orders06
where order_date >= date_sub(current_date(),interval 3 month)
group by 1,2
),
customer_count_month as 
(select 
customer_id,count(distinct month) as month_purchased
from recent_orders
group by customer_id
)
select c.*  from customers06 c left join 
customer_count_month ccm on c.customer_id=ccm.customer_id
where ccm.month_purchased=3;

# Find customers who spent above the average customer spend in the last 30 days

with customer_spend as
(select 
customer_id,
sum(amount) as total_spend
from orders06
where order_date >= date_sub(current_date(),interval 35 day)
group by customer_id
),
avg_spend as (
select avg(total_spend) as avg_spend
from customer_spend
)
select c.* from customers06 c
join customer_spend cs on c.customer_id=cs.customer_id 
join avg_spend  ase on cs.total_spend > ase.avg_spend;



# SELECT * FROM customers06;(customer_id, name, email)
# SELECT * FROM orders06;(order_id, customer_id, order_date, amount)




















