/*
 ===============================================================================
 Quality Checks
 ===============================================================================
 Script Purpose:
 This script performs various quality checks for data consistency, accuracy, 
 and standardization across the 'silver' layer. It includes checks for:
 - Null or duplicate primary keys.
 - Unwanted spaces in string fields.
 - Data standardization and consistency.
 - Invalid date ranges and orders.
 - Data consistency between related fields.
 
 Usage Notes:
 - Run these checks after data loading Silver Layer.
 - Investigate and resolve any discrepancies found during the checks.
 ===============================================================================
 */


-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Result

SELECT cst_id,
	COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1
	OR cst_id IS NULL 


-- Check for Unwanted Spaces
-- Expectation: No Results

SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname) 


-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info
SELECT DISTINCT cst_material_status
FROM bronze.crm_cust_info 

-- Check for NULLs or Negative Numbers
-- Expectaions: No Results

SELECT *
FROM bronze.crm_prd_info
WHERE prd_cost IS NULL
	OR prd_cost <= 0 
	
-- Check the Integrity

SELECT *
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (
		SELECT prd_key
		FROM silver.crm_prd_info
	) 
	
-- Check for Invalid Dates

SELECT sls_ord_num,
	sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0
	OR LEN(sls_order_dt) != 8
	OR sls_order_dt > 20251231
	OR sls_order_dt < 19000101


-- Check Data Consistency: Between Sales, Quantity and Price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero or negative

SELECT DISTINCT sls_sales,
	sls_quantity,
	sls_price
FROM bronze.crm_sales_details
WHERE sls_price != sls_quantity * sls_price
	OR sls_sales IS NULL
	OR sls_quantity IS NULL
	OR sls_price IS NULL
	OR sls_sales <= 0
	OR sls_quantity <= 0
	OR sls_price <= 0


-- Identify Out-of Range Dates

SELECT DISTINCT bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1930-01-01'
	OR bdate > GETDATE()