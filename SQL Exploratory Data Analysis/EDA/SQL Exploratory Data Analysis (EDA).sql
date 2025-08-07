-- =================================================
-- SQL Exploratory Data Analysis (EDA)
-- =================================================

-- -------------------------------------------------
-- Step 1: Database Exploration
-- -------------------------------------------------


-- Explore All Objects in The Database
SELECT * FROM INFORMATION_SCHEMA.TABLES

-- Explore All Columns in Gold Schema
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'



-- -------------------------------------------------
-- Step 2: Dimensions Exploration
-- -------------------------------------------------
/*
	Identifying the unique values (or categories) in each dimension

	Recognizing how data might be grouped or segmented,
	which is useful for later analysis

*/

SELECT DISTINCT country FROM gold.dim_customers

SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products
ORDER BY 1,2,3

SELECT DISTINCT subcategory FROM gold.dim_products


-- -------------------------------------------------
-- Step 3: Data Exploration
-- -------------------------------------------------
/*
	Identifying the earliest and latest dates (boundaries)

	Understand the scope of data and the timespan.

*/

SELECT 
	MIN(order_date) AS first_order,
	MAX(order_date) AS last_order,
	DATEDIFF(YEAR,MIN(order_date),MAX(order_date)) AS order_range_year
FROM gold.fact_orders

SELECT
	MIN(birthdate) AS oldest_birhtdate,
	DATEDIFF(YEAR,MIN(birthdate),GETDATE()) AS oldest_age,
	MAX(birthdate) AS youngest_birthdate,
	DATEDIFF(YEAR,MAX(birthdate),GETDATE()) AS youngest_age
FROM gold.dim_customers

-- -------------------------------------------------
-- Step 4: Measures Exploration
-- -------------------------------------------------
/*
	Calculate the key metric of the business (Big Numbers)

	Highest Level of Aggregation | Lowest Level of Details
*/
SELECT SUM(sales_amount) AS Total_Sales FROM gold.fact_orders

SELECT SUM(quantity) AS Total_Items_Sold FROM gold.fact_orders

SELECT AVG(price) AS Avg_Price FROM gold.fact_orders

SELECT COUNT(DISTINCT order_number) AS Total_Orders FROM gold.fact_orders

SELECT COUNT(product_key) AS Total_Products FROM gold.dim_products

SELECT COUNT(customer_key) AS Total_Customers FROM gold.dim_customers

SELECT COUNT(DISTINCT customer_key) AS Total_Customers_Placed_Order FROM gold.fact_orders 

-- -------------------------------------------------
-- Generate a report that shows all key matrics of the business 
-- -------------------------------------------------

SELECT 'Total_Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_orders
UNION ALL
SELECT 'Total_Items_Sold' AS measure_name, SUM(quantity) AS measure_value FROM gold.fact_orders
UNION ALL
SELECT 'Avg_Price' AS measure_name, AVG(price) AS measure_value FROM gold.fact_orders
UNION ALL
SELECT 'Total_Orders' AS measure_name, COUNT(DISTINCT order_number) AS measure_value FROM gold.fact_orders
UNION ALL
SELECT 'Total_Products' AS measure_name, COUNT(product_key) AS measure_value FROM gold.dim_products
UNION ALL
SELECT 'Total_Customers' AS measure_name, COUNT(customer_key) AS measure_value FROM gold.dim_customers
UNION ALL
SELECT 'Total_Customers_Placed_Order' AS measure_name, COUNT(DISTINCT customer_key) AS measure_value FROM gold.fact_orders

-- -------------------------------------------------
-- Step 5: Magnitude Analysis
-- -------------------------------------------------
/*
	Comper the mueasure values by categories

	It helps us understand the importance of different categories
*/

-- Total Customers by Country
SELECT country, COUNT(customer_key) AS Total_Customers FROM gold.dim_customers 
GROUP BY country ORDER BY Total_Customers DESC
-- Total Customers by Gender
SELECT gender, COUNT(customer_key) AS Total_Customers FROM gold.dim_customers 
GROUP BY gender ORDER BY Total_Customers DESC

-- Total Products by Categories
SELECT category, COUNT(product_key) AS Total_Products FROM gold.dim_products 
GROUP BY category ORDER BY Total_Products DESC

-- Average Consts in Each Category
SELECT category, AVG(cost) AS Avg_Cost FROM gold.dim_products 
GROUP BY category ORDER BY Avg_Cost DESC

-- Total Revenue for Each Category
SELECT p.category, SUM(f.sales_amount) AS Total_Revenue FROM gold.fact_orders f
LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY category ORDER BY Total_Revenue DESC

-- Total Revenue for Each Customer
SELECT TOP 10 c.first_name + ' ' + c.last_name AS full_name, SUM(f.sales_amount) AS Total_Revenue FROM gold.fact_orders f
LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.first_name + ' ' + c.last_name ORDER BY Total_Revenue DESC

-- Distribution of Sold Itmes Across Countries
SELECT c.country , SUM(f.quantity) AS Total_Sold_Items FROM gold.fact_orders f
LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.country ORDER BY Total_Sold_Items DESC

-- -------------------------------------------------
-- Step 6: Ranking Analysis
-- -------------------------------------------------
/*
	Order the values od dimensions by measure

	TOP N Performers | BOTTOM N Performers
*/

-- Top 5 Products generate the highest revenue
SELECT TOP 5 p.product_name, SUM(f.sales_amount) AS Total_Revenue FROM gold.fact_orders f
LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY product_name ORDER BY Total_Revenue DESC

SELECT * 
FROM (
	SELECT p.product_name, SUM(f.sales_amount) AS Total_Revenue,
	ROW_NUMBER() OVER(ORDER BY SUM(f.sales_amount) DESC) AS Rank_Product
	FROM gold.fact_orders f
	LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
	GROUP BY product_name
)t
WHERE Rank_Product <= 5;

-- 5 worst-performing products in revenue
SELECT TOP 5 p.product_name, SUM(f.sales_amount) AS Total_Revenue FROM gold.fact_orders f
LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY product_name ORDER BY Total_Revenue ASC


-- Top 3 Customers with The Highest Orders Placed
SELECT TOP 3 c.first_name + ' ' + c.last_name AS full_name, COUNT(DISTINCT f.order_number) AS Total_Orders FROM gold.fact_orders f
LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.first_name + ' ' + c.last_name ORDER BY Total_Orders DESC