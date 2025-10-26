--1. What is the total amount each customer spent at the restaurant?

select
s.customer_id as Customer_ID, 
SUM(m.price) as Total_amount
from sales s
inner join menu m
on s.product_id=m.product_id
group by s.customer_id

--2. How many days has each customer visited the restaurant? 

select
customer_id,
COUNT(distinct order_date) as Days_Count
from sales
group by customer_id;

--3. What was the first item from the menu purchased by each customer? 

with Orders_Rank as 
(
select
s.customer_id as Customer_ID,
m.product_name as Product_Name,
ROW_NUMBER() over(partition by s.customer_id order by s.order_date) as rn
from sales s
inner join menu m
on s.product_id = m.product_id
)
select Customer_ID,
Product_Name
from Orders_Rank
where rn = 1;

--4. What is the most purchased item on the menu and how many times was it been purchased by all customers?

with Counte as
(
select
m.product_name as Product_Name ,
s.product_id as Product_ID,
COUNT(s.product_id) as Product_Num,
ROW_NUMBER() over(order by COUNT(s.product_id) desc) as rn
from sales s
inner join menu m
on s.product_id = m.product_id
group by m.product_name,s.product_id
),
 counte_1 as (

select
m.Product_Name,
s.customer_id,
count(s.Product_ID) as co
from menu m
inner join sales s
on m.product_id=s.product_id
group by m.Product_Name,s.customer_id
)

select
c.Product_Name as the_MOST_Perchesed_Item,
c.Product_Num as MUM_OF_the_MOST_Perchesed_Item,
c1.customer_id,
c1.co as NUM_By_each_Customer
from Counte c
inner join counte_1 c1
on c.Product_Name=c1.Product_Name
where c.rn=1


--5. Which item was the most popular for each customer?

with Ranking as (
select
s.customer_id as Customer_ID,
m.product_name as Product_Name,
COUNT(s.product_id) as NUMBER,
rank() over(partition by s.customer_id  order by COUNT(s.product_id) desc) as rn
from sales s
inner join menu m
on s.product_id = m.product_id
group by s.customer_id,m.product_name
)
select
Customer_ID,
Product_Name,
NUMBER
from Ranking
where rn =1


--6. Which item was purchased first by the customer after they became a member? 

WITH post_join_orders AS (
  SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    mem.join_date,
    ROW_NUMBER() OVER (
      PARTITION BY s.customer_id
      ORDER BY s.order_date
    ) AS rn
  FROM sales AS s
  JOIN menu AS m
    ON s.product_id = m.product_id
  JOIN members AS mem
    ON s.customer_id = mem.customer_id
  WHERE s.order_date > mem.join_date
)

SELECT
  customer_id,
  product_name AS first_item_after_join,
  order_date
FROM post_join_orders
WHERE rn = 1;


--7. Which item was purchased just before the customer became a member? 

WITH post_join_orders AS (
  SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    mem.join_date,
    rank() OVER (
      PARTITION BY s.customer_id
      ORDER BY s.order_date desc
    ) AS rn
  FROM sales AS s
  JOIN menu AS m
    ON s.product_id = m.product_id
  JOIN members AS mem
    ON s.customer_id = mem.customer_id
  WHERE s.order_date <  mem.join_date
)

SELECT
  customer_id,
  product_name AS last_item_before_join,
  order_date
FROM post_join_orders
WHERE rn = 1;

--8. What is the total items and amount spent on each member before they became a member?

select
mem.customer_id,
count(s.product_id) Total_items,
SUM(m.price) Total_amount
from sales s
inner join members mem
on s.customer_id = mem.customer_id
inner join menu m
on s.product_id = m.product_id
where mem.join_date > s.order_date
group by mem.customer_id 

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? 

SELECT
  s.customer_id,
  SUM(
    CASE
      WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
      ELSE m.price * 10
    END
  ) AS total_points
FROM sales AS s
inner JOIN menu AS m
  ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? 

SELECT
  s.customer_id,
  SUM(
    CASE
      WHEN s.order_date BETWEEN m.join_date AND DATEADD(DAY, 6, m.join_date)
        THEN me.price * 10 * 2
      WHEN me.product_name = 'sushi'
        THEN me.price * 10 * 2
      ELSE me.price * 10
    END
  ) AS total_points
FROM sales AS s
inner JOIN menu AS me
  ON s.product_id = me.product_id
inner JOIN members AS m
  ON s.customer_id = m.customer_id
WHERE s.order_date <= '2021-01-31'
  AND s.customer_id IN  (select customer_id from members)
GROUP BY s.customer_id;

--11 - Total

select
count(distinct s.customer_id) as Customers_Number,
sum(m.price) as Total_Sales,
AVG(m.price) as Averge_Sales,
count(distinct s.order_date) as Days_Number
from sales s
inner join menu m 
on s.product_id = m.product_id


-------------------------------------------------------------------------------------------------

-- Bonus Questions


-- Join All the Things 

select
s.customer_id as Customrs_id,
s.order_date as Order_date,
m.product_name as Product_name,
m.price as Price,
case
	when mem.join_date is not null and s.order_date >= mem.join_date then 'Y'
	else 'N'
	end as member
from sales s
inner join menu m
on s.product_id = m.product_id
left join members mem
on s.customer_id = mem.customer_id


--Rank All the Things 

WITH joined AS (
  SELECT
    s.customer_id as Customer_id ,
    s.order_date as Order_date,
    m.product_name as Product_name,
    m.price as Price,
    CASE 
      WHEN mem.join_date IS NOT NULL AND s.order_date >= mem.join_date THEN 'Y'
      ELSE 'N'
    END AS member
  FROM sales s
  JOIN menu m ON s.product_id = m.product_id
  LEFT JOIN members mem ON s.customer_id = mem.customer_id
),
ranked AS (
  SELECT distinct Customer_id,
		 Order_date ,
         Product_name,
		 Price,
		CASE 
           WHEN member = 'Y' THEN RANK() OVER (
             PARTITION BY customer_id
             ORDER BY order_date
           )
		   else null
         END AS ranking
  FROM joined
   WHEre member = 'Y'
)
SELECT j.customer_id, j.order_date, j.product_name, j.price, j.member, r.ranking
FROM joined j
left join ranked r
on j.Customer_id = r.Customer_id
and j.Order_date = r.Order_date
ORDER BY customer_id, order_date;


