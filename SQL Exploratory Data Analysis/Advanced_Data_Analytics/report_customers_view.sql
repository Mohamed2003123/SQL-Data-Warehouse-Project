-- -------------------------------------------------
-- Step 12: Reporting 
-- -------------------------------------------------
/*
		============================================================
		Customer Report
		============================================================

		Purpose:
		 - This report consolidates key customer metrics and behaviors

		Highlights:
		 1. Gathers essential fields such as names, ages, and transaction details.
		 2. Segments customers into categories (VIP, Regular, New) and age groups.
		 3. Aggregates customer-level metrics:
			- total orders
			- total sales
			- total quantity purchased
			- total products
			- lifespan (in months)
		 4. Calculates valuable KPIs:
			- recency (months since last order)
			- average order value
			- average monthly spend
		============================================================
*/
CREATE VIEW gold.report_customers AS
WITH base_query AS (
	SELECT
		f.order_number,
		f.product_key,
		f.order_date,
		f.sales_amount,
		f.quantity,
		c.customer_key,
		CONCAT(c.first_name, ' ' , c.last_name) AS full_name,
		DATEDIFF(YEAR, c.birthdate, GETDATE()) AS age
	FROM gold.fact_orders f
	LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
),
customer_aggregations AS(
	SELECT
		customer_key,
		full_name,
		age,
		COUNT(DISTINCT order_number) AS total_orders,
		SUM(sales_amount) AS total_spending,
		SUM(quantity) AS total_quantity,
		COUNT(DISTINCT product_key) AS total_products,
		MAX(order_date) AS last_order,
		DATEDIFF(MONTH, MIN(order_date),MAX(order_date)) AS life_span
	FROM base_query
	GROUP BY
		customer_key,
		full_name,
		age
)

SELECT
	customer_key,
	full_name,
	age,
	CASE WHEN age < 20 THEN 'Under 20'
		 WHEN age BETWEEN 20 AND 29 THEN '20 - 29'
		 WHEN age BETWEEN 30 AND 39 THEN '30 - 39'
		 WHEN age BETWEEN 40 AND 49 THEN '40 - 49'
		 ELSE '50 and Above'
	END AS age_segment,
	CASE WHEN life_span >= 12 AND total_spending > 5000 THEN 'VIP'
		 WHEN life_span >= 12 AND total_spending <= 5000 THEN 'Regular'
		 ELSE 'New'
	END AS customer_segment,
	last_order,
	DATEDIFF(MONTH, last_order, GETDATE()) AS recency,
	total_orders,
	total_spending,
	total_quantity,
	total_products,
	life_span,
	-- Compuate average order value (AVO)
	CASE WHEN total_orders = 0 THEN 0
		 ELSE total_spending / total_orders
	END AS avg_order_value,
	-- Compuate average monthly spend 
	CASE WHEN life_span = 0 THEN total_spending
		 ELSE total_spending / life_span
	END AS avg_monthly_spend
FROM customer_aggregations