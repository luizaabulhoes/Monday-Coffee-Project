-- Monday Coffee - Data Analysis

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
   city_name
  ,ROUND((population * 0.25)/100000,2) AS coffee_consumers
  ,city_rank
FROM `monday_coffe_db.city` 
ORDER BY 2


-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
  ct.city_id
  ,ct.city_name
  ,SUM(sl.total) AS total_revenue
FROM `monday_coffe_db.sales` AS sl
LEFT JOIN `monday_coffe_db.customers` AS cm
  ON sl.customer_id = cm.customer_id
LEFT JOIN `monday_coffe_db.city` AS ct
  ON cm.city_id = ct.city_id
WHERE sl.sale_date BETWEEN "2023-10-01" AND "2023-12-31"
GROUP BY 1, 2
ORDER BY 1

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
   pd.product_name
  ,COUNT(sl.sale_id) AS total_orders
FROM `monday_coffe_db.sales` AS sl
LEFT JOIN `monday_coffe_db.products` as pd
  ON sl.product_id = pd.product_id
GROUP BY sl.product_id, pd.product_name
ORDER BY 2 DESC

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT 
  ct.city_name
  ,SUM(sl.total) AS total_revenue
  ,COUNT(DISTINCT sl.customer_id) as total_cx
  ,ROUND(SUM(sl.total)/COUNT(DISTINCT sl.customer_id),2) AS avg_sale_pr_cx
FROM `monday_coffe_db.sales` AS sl
LEFT JOIN `monday_coffe_db.customers` AS cm
  ON sl.customer_id = cm.customer_id
LEFT JOIN `monday_coffe_db.city` AS ct
  ON cm.city_id = ct.city_id
GROUP BY ct.city_name
ORDER BY 4 DESC

-- -- Q5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table AS
 (SELECT 
   city_name
  ,ROUND((population * 0.25)/1000000, 2) AS estimated_coffee_consumers
FROM `monday_coffe_db.city` )

,customers_table AS
( SELECT
  ct.city_name  
  ,COUNT(DISTINCT cm.customer_id) AS unique_cx
FROM `monday_coffe_db.sales` AS sl
JOIN `monday_coffe_db.customers` AS cm
  ON sl.customer_id = cm.customer_id
JOIN `monday_coffe_db.city` AS ct
  ON ct.city_id = cm.city_id
GROUP BY 1
ORDER BY 2 DESC)

SELECT
  cty.city_name
  ,cty.estimated_coffee_consumers AS coffee_consumer_in_millions
  ,cmt.unique_cx
FROM city_table AS  cty
JOIN customers_table AS cmt
  ON cmt.city_name = cty.city_name



-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

WITH ranked_sales AS (
  SELECT 
     ct.city_name
    ,pd.product_name
    ,COUNT(sl.sale_id) AS total_orders
    ,DENSE_RANK() OVER(PARTITION BY ct.city_name ORDER BY COUNT(sl.sale_id) DESC) AS rank_pd
  FROM `monday_coffe_db.sales` AS sl
  LEFT JOIN `monday_coffe_db.products` AS pd
    ON sl.product_id = pd.product_id
  LEFT JOIN `monday_coffe_db.customers` AS cm
    ON sl.customer_id = cm.customer_id
  LEFT JOIN `monday_coffe_db.city` AS ct
    ON cm.city_id = ct.city_id
  GROUP BY sl.product_id, pd.product_name, ct.city_name
)

SELECT *
FROM ranked_sales
WHERE rank_pd <= 3
ORDER BY city_name, rank_pd, total_orders DESC


-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
   cm.city_id
  ,ct.city_name
  ,COUNT(DISTINCT cm.customer_id) AS customers
FROM `monday_coffe_db.sales` AS sl
LEFT JOIN `monday_coffe_db.customers` AS cm
  ON sl.customer_id = cm.customer_id
LEFT JOIN `monday_coffe_db.city` AS ct
  ON cm.city_id = ct.city_id
GROUP BY cm.city_id, ct.city_name
ORDER BY customers DESC


-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH city_table AS 
(SELECT
  ct.city_name
  ,SUM(sl.total) AS total_revenue
  ,COUNT(DISTINCT sl.customer_id) AS total_cx
  ,ct.estimated_rent
FROM `monday_coffe_db.sales` AS sl
JOIN `monday_coffe_db.customers` AS cm
  ON sl.customer_id = cm.customer_id
JOIN `monday_coffe_db.city` AS ct
  ON cm.city_id = ct.city_id  
GROUP BY 1,4
)

SELECT 
city_name
,ROUND(SAFE_DIVIDE(total_revenue, total_cx), 2) AS avg_sale_cx
,ROUND(SAFE_DIVIDE(estimated_rent, city_table.total_cx),2) AS avg_rent_cx
FROM city_table
ORDER BY 2 DESC

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sales AS (
SELECT ct.city_name
  ,EXTRACT(MONTH FROM sale_date) AS month_sales
  ,EXTRACT(YEAR FROM sale_date) AS year_sales
  ,SUM(sl.total) as amount_sales
FROM `monday_coffe_db.sales` sl
LEFT JOIN `monday_coffe_db.customers` cm
  ON sl.customer_id = cm.customer_id
LEFT JOIN `monday_coffe_db.city` ct
  ON cm.city_id = ct.city_id
GROUP BY 
ct.city_name
,month_sales
,year_sales
ORDER BY 
ct.city_name
,month_sales
,year_sales)

SELECT
  city_name
  ,month_sales
  ,year_sales
  ,LAG (amount_sales) OVER(PARTITION BY city_name ORDER BY year_sales, month_sales ) AS previous_month_sales
  ,ROUND(SAFE_DIVIDE(amount_sales - LAG(amount_sales) OVER (PARTITION BY city_name  ORDER BY year_sales, month_sales) 
  ,LAG(amount_sales) OVER (PARTITION BY city_name ORDER BY year_sales, month_sales)) * 100,2) AS monthly_growth_percent
FROM monthly_sales
ORDER BY 
  city_name
  ,year_sales
  ,month_sales

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

SELECT
  ct.city_name
  ,SUM(sl.total) AS total_sale
  ,ct.estimated_rent AS total_rent
  ,COUNT(DISTINCT cm.customer_id) AS total_customers
  ,ROUND((ct.population * 0.25)/1000000, 3) AS estimated_coffee_consumer_in_millions
  ,ROUND(SUM(sl.total) / COUNT(DISTINCT cm.customer_id), 2) AS avg_sale_per_customer
  ,ROUND(ct.estimated_rent / COUNT(DISTINCT cm.customer_id), 2) AS avg_rent_per_customer
FROM `monday_coffe_db.sales` AS sl
JOIN `monday_coffe_db.customers` AS cm
  ON sl.customer_id = cm.customer_id
JOIN `monday_coffe_db.city` AS ct
  ON cm.city_id = ct.city_id
GROUP BY ct.city_name, ct.estimated_rent, ct.population
ORDER BY total_sale DESC


/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.