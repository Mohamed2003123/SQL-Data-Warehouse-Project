-- =================================================
-- Advanced_Data_Analytics
-- =================================================

-- -------------------------------------------------
-- Step 7: Changes Over Time Analysis
-- -------------------------------------------------

SELECT 
	DATETRUNC(MONTH, order_date) AS Order_Date,
	SUM(sales_amount) AS Total_Sales,
	SUM(quantity) AS Total_Quantity,
	COUNT(DISTINCT customer_key) AS Total_Customers
FROM gold.fact_orders
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY DATETRUNC(MONTH, order_date)

SELECT 
	FORMAT(order_date, 'yyyy-MMM') AS Order_Date,
	SUM(sales_amount) AS Total_Sales,
	SUM(quantity) AS Total_Quantity,
	COUNT(DISTINCT customer_key) AS Total_Customers
FROM gold.fact_orders
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM')

-- -------------------------------------------------
-- Step 8: Cumulative Analysis
-- -------------------------------------------------
/*
	Aggregate the data progressively over time.

	Helps to understand whether our business is growing or declining

*/

-- Calculate the Total Sales per Month
-- and The Running Total of Sales Over Time

SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER(PARTITION BY YEAR(order_date) ORDER BY order_date) AS running_total,
	AVG(Avg_price) OVER(PARTITION BY YEAR(order_date) ORDER BY order_date) AS moving_average_price
FROM(
	SELECT 
		DATETRUNC(MONTH,order_date) AS order_date,
		SUM(sales_amount) AS total_sales,
		AVG(price) AS Avg_price
	FROM gold.fact_orders
	GROUP BY DATETRUNC(MONTH,order_date)
)t


-- -------------------------------------------------
-- Step 9: Performance Analysis
-- -------------------------------------------------
/*
	Comparing the current value to a target value]

	Helps measure success and compare performance

*/

WITH yearly_product_sales AS (
	SELECT 
		YEAR(o.order_date) AS order_year,
		p.product_name,
		SUM(o.sales_amount) AS current_sales
	FROM gold.fact_orders o
	LEFT JOIN gold.dim_products p
	ON o.product_key = p.product_key
	GROUP BY YEAR(o.order_date),p.product_name
)
SELECT
	order_year,
	product_name,
	current_sales,
	AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
	current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS diff_avg,
	CASE
		WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Avg'
		WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Avg'
		ELSE 'Avg'
	END avg_change,
	LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS py_sales,
	current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_py_sales,
	CASE
		WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
		WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
		ELSE 'No Change'
	END py_change
FROM yearly_product_sales;


-- -------------------------------------------------
-- Step 10: Part-To-Whole Analysis
-- -------------------------------------------------
/*
	Analyze how an individual part is performing compared to the overall,
	allowing us to understand which category has the greatest impact on the business
*/

WITH category_sales AS(
	SELECT
		p.category,
		p.subcategory,
		SUM(f.sales_amount) AS total_sales
	FROM gold.fact_orders f
	LEFT JOIN gold.dim_products p 
	ON f.product_key = p.product_key
	GROUP BY p.category ,p.subcategory
)

SELECT
	category,
	subcategory,
	total_sales,
	SUM(total_sales) OVER(PARTITION BY category) AS overall_sales,
	CONCAT(ROUND(CAST(total_sales AS FLOAT) / SUM(total_sales) OVER(PARTITION BY category) * 100,2), '%') AS per_sales
FROM category_sales;

-- -------------------------------------------------
-- Step 11: Data Segmentation
-- -------------------------------------------------
/*
	Group the data based on a specific range.
	
	Helps understand the correlation between two measures
*/
WITH customer_spending AS(
	SELECT 
		c.customer_key,
		SUM(sales_amount) AS total_spending,
		MIN(order_date) AS first_order,
		MAX(order_date) AS last_order,
		DATEDIFF(MONTH, MIN(order_date),MAX(order_date)) AS life_span
	FROM gold.fact_orders f
	LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
	GROUP BY c.customer_key
)

SELECT
	customer_segment,
	COUNT(*) AS total_customers
FROM (
	SELECT
		customer_key,
		total_spending,
		life_span,
		CASE WHEN life_span >= 12 AND total_spending > 5000 THEN 'VIP'
			 WHEN life_span >= 12 AND total_spending <= 5000 THEN 'Regular'
			 ELSE 'New'
		END AS customer_segment
	FROM customer_spending
)t
GROUP BY customer_segment