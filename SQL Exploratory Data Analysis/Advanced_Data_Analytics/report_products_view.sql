/*
============================================================
Product Report
============================================================

Purpose:
 - This report consolidates key product metrics and behaviors.

Highlights:
 1. Gathers essential fields such as product name, category, subcategory, and cost.
 2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
 3. Aggregates product-level metrics:
    - total orders
    - total sales
    - total quantity sold
    - total customers (unique)
    - lifespan (in months)
 4. Calculates valuable KPIs:
    - recency (months since last sale)
    - average order revenue (AOR)
    - average monthly revenue
============================================================
*/ 
CREATE VIEW gold.report_products AS
WITH base_query AS (
	SELECT
		f.order_number,
		f.customer_key,
		f.order_date,
		f.sales_amount,
		f.quantity,
		p.product_key,
		p.category,
		p.subcategory,
		p.product_name,
		p.cost
	FROM gold.fact_orders f
	LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
),
product_aggregations AS(
	SELECT
		category,
		subcategory,
		product_name,
		cost,
		COUNT(DISTINCT order_number) AS total_orders,
		SUM(sales_amount) AS total_sales,
		SUM(quantity) AS total_quantity,
		COUNT(DISTINCT customer_key) AS total_customers,
		MAX(order_date) AS last_sale_order,
		DATEDIFF(MONTH, MIN(order_date),MAX(order_date)) AS life_span,
		ROUND(AVG(CAST( sales_amount AS FLOAT) / NULLIF(quantity,0)),1) AS avg_selling_price	
	FROM base_query
	GROUP BY
		category,
		subcategory,
		product_name,
		cost
)

SELECT
	category,
	subcategory,
	product_name,
	cost,
	last_sale_order,
	DATEDIFF(MONTH, last_sale_order, GETDATE()) AS recency,
	life_span,
	CASE WHEN total_sales > 50000 THEN 'High-Performer'
		 WHEN total_sales > 50000 THEN 'Mid-Range'
		 ELSE 'Low-Performer'
	END AS product_segment,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Compuate average order value (AVO)
	CASE WHEN total_orders = 0 THEN 0
		 ELSE total_sales / total_orders
	END AS avg_order_value,
	-- Compuate average monthly spend 
	CASE WHEN life_span = 0 THEN total_sales
		 ELSE total_sales / life_span
	END AS avg_monthly_spend
FROM product_aggregations