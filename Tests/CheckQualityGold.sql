/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency, 
    and accuracy of the Gold Layer. These checks ensure:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical purposes.

Usage Notes:
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

----------------------------------------
-- Check Duplicated In: silver.crm_cust_info
----------------------------------------
SELECT cst_key,
COUNT(*)
FROM(
	SELECT
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_material_status,
		ci.cst_gndr,
		ci.cst_create_date,
		ca.bdate,
		ca.gen,
		cl.cntry
	FROM silver.crm_cust_info AS ci
	LEFT JOIN silver.erp_cust_az12 ca 
	ON ci.cst_key = ca.cid
	LEFT JOIN silver.erp_loc_a101 cl
	ON ci.cst_key = cl.cid
)t
GROUP BY cst_key
HAVING COUNT(*) >1

----------------------------------------
-- Check Duplicated In: silver.crm_prd_info
----------------------------------------

SELECT prd_key,
COUNT(*)
FROM(
	SELECT 
		pn.prd_id,
		pn.prd_key,
		pn.cat_id,
		pn.prd_nm,
		pn.prd_cost,
		pn.prd_line,
		pn.prd_start_dt,
		ca.cat,
		ca.subcat,
		ca.maintenance
	FROM silver.crm_prd_info pn
	LEFT JOIN silver.erp_px_cat_g1v2 ca
	ON pn.cat_id = ca.id
	WHERE pn.prd_end_dt IS NULL -- Filtering Out-all Historical Data	
)t
GROUP BY prd_key
HAVING COUNT(*) >1


----------------------------------------
--Customer Gender Consistency Check Between CRM and ERP Systems In: silver.crm_cust_info
----------------------------------------

SELECT DISTINCT
	ci.cst_gndr,
	ca.gen,
	CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr -- CRM is The Master for Gender Info
		 ELSE ISNULL(ca.gen, 'N/A')
	END gender
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 ca 
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 cl
ON ci.cst_key = cl.cid
ORDER BY 1,2

----------------------------------------
--Foreign Key Integrity (Dimensions)
----------------------------------------

SELECT 
	*
FROM gold.fact_orders f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
WHERE c.customer_key IS NULL OR p.product_key IS NULL