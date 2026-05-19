-- ============================================================================================================================================
-- ============================================================================================================================================
--  Part 4. Complain_register
-- Creating a staging table of Production_log to preserve raw data integrity
-- ============================================================================================================================================
-- ============================================================================================================================================

CREATE TABLE complain_register_staging AS
SELECT *
FROM complain_register_raw;

SELECT *
FROM complain_register_staging;

-- ============================================================================================================================================
-- Standardize date format to ensure accurate analysis and reporting consistency
-- ============================================================================================================================================
SELECT complained_date
FROM complain_register_staging
WHERE STR_TO_DATE(complained_date, '%Y-%m-%d') IS NULL;

SELECT production_date
FROM complain_register_staging
WHERE STR_TO_DATE(production_date, '%Y-%m-%d') IS NULL;

SELECT complained_date, production_date
FROM complain_register_staging
WHERE complained_date LIKE '% %'
	OR production_date LIKE '% %';
-- Result: verified zero formatting errors, zero NULL values, and zero hidden spaces

ALTER TABLE complain_register_staging
MODIFY COLUMN production_date DATE;

ALTER TABLE complain_register_staging
MODIFY COLUMN complained_date DATE;


-- ============================================================================================================================================
-- Standardize all columns to eliminate inconsistency
-- ============================================================================================================================================
-- [Complained_date & Production_date]
-- Review these column for date relationship (Complained date cannot occur earlier than Production date)
SELECT *
FROM complain_register_staging
WHERE complained_date < production_date;
-- Result: 10 rows were identified where complained_date occurred earlier than production_date
-- As the correct dates could not be confidently determined, the original values were preserved

-- [Complain_ID]
-- This column should contain unique values to distinguish each complaint record
-- Standardizing Complain_ID format by Trim, Length and Upper to ensure data consistency before checking for duplicates
UPDATE complain_register_staging
SET complain_ID = UPPER(TRIM(complain_ID));

SELECT complain_ID
FROM complain_register_staging
WHERE LENGTH(complain_ID) != 6;

WITH cte_complainID AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY complain_ID) AS row_num
FROM complain_register_staging
)
SELECT *
FROM cte_complainID
WHERE row_num > 1;
-- Result: No duplicates found. Format standardized and uniqueness confirmed

-- [Complain_category]
-- 1. Review inconsistency
SELECT DISTINCT complain_category
FROM complain_register_staging;
-- No obvious formatting inconsistencies were identified. However, SQL DISTINCT can hide case variations 
-- Therefore, I applied UPPER() and listed all structural variations to ensure 100% robust standardization

-- 2. Proactively standardize text casing and trim to ensure formatting consistency
SELECT complain_category AS original,
CASE
	WHEN UPPER(TRIM(complain_category)) IN ('HIGH') THEN 'High'
    WHEN UPPER(TRIM(complain_category)) IN ('MID') THEN 'Mid'
    WHEN UPPER(TRIM(complain_category)) IN ('LOW') THEN 'Low'
	ELSE UPPER(TRIM(complain_category))
END AS Trimmed
FROM complain_register_staging;

-- 3. Update the column
UPDATE complain_register_staging
SET complain_category = CASE
	WHEN UPPER(TRIM(complain_category)) IN ('HIGH') THEN 'High'
    WHEN UPPER(TRIM(complain_category)) IN ('MID') THEN 'Mid'
    WHEN UPPER(TRIM(complain_category)) IN ('LOW') THEN 'Low'
	ELSE UPPER(TRIM(complain_category))
END;

-- [Product_ID]
-- -- To ensure relational integrity, Product_ID and Product_name consistency was validated using GROUP BY and HAVING
SELECT product_id, COUNT(DISTINCT product_name) AS count_prd
FROM complain_register_staging
GROUP BY product_ID
HAVING count_prd > 1;
-- Result: 0 rows were returned, indicating no consistency issues were identified

-- [Product_name]
-- 1. Review inconsistency using DISTINCT
SELECT DISTINCT product_name
FROM complain_register_staging;

-- 2. Proactively trim whitespace for formatting consistency
UPDATE complain_register_staging
SET product_name = TRIM(product_name);


-- [Line_number]
-- 1. Review inconsistency using DISTINCT
SELECT DISTINCT line_number
FROM complain_register_staging;

-- 2. Proactively standardize line numbers for the same reason as the 'complain_category' review
UPDATE complain_register_staging
SET line_number = CASE
	WHEN UPPER(TRIM(line_number)) IN ('LINE 1') THEN 'Line 1'
    WHEN UPPER(TRIM(line_number)) IN ('LINE 2') THEN 'Line 2'
    WHEN UPPER(TRIM(line_number)) IN ('LINE 3') THEN 'Line 3'
	WHEN UPPER(TRIM(line_number)) IN ('LINE 4') THEN 'Line 4'
	ELSE UPPER(TRIM(line_number)) 
END;

-- [Complain_reason]
-- 1. Review unique complaint reasons using DISTINCT
SELECT DISTINCT complain_reason
FROM complain_register_staging;

-- 2. No specific values found; applied TRIM to clean whitespace only
UPDATE complain_register_staging
SET complain_reason = TRIM(complain_reason);

-- ============================================================================================================================================
-- Complain_register Summary
-- ============================================================================================================================================
-- Verified that all date columns were successfully converted to DATE format
-- Complaint category, line number, and complaint reason values were standardized for consistency
-- Complain_ID values were standardized and validated for uniqueness
-- Product_ID and Product_name relationships were validated to ensure relational consistency
-- 10 rows showed invalid date chronology and were preserved due to uncertain source values
-- No duplicate records or unrecoverable data integrity issues were identified