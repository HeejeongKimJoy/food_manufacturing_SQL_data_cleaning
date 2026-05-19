-- ============================================================================================================================================
-- ============================================================================================================================================
--  Part 1. Production_log table 
-- Creating a staging table of Production_log to preserve raw data integrity
-- ============================================================================================================================================
-- ============================================================================================================================================

CREATE TABLE  production_log_staging AS
SELECT *
FROM production_log_raw;

SELECT *
FROM production_log_staging;

-- ============================================================================================================================================
-- Inspect invalid or missing values to maintain data accuracy and reporting reliability
-- ============================================================================================================================================

-- 1. Inspect null values
SELECT *
FROM production_log_staging
WHERE `date` IS NULL
   OR Line_number IS NULL
   OR Shift IS NULL
   OR Product_ID IS NULL
   OR Product_Name IS NULL
   OR Production_Volume IS NULL;

-- 2. Inspect zero values in numerical columns to ensure data accuracy and reporting reliability
-- Production volume directly impacts operational KPI reporting and efficiency analysis
-- Therefore, negative production values or 0 values are considered invalid operational records
SELECT *
FROM production_log_staging
WHERE Product_ID = 0
   OR Production_Volume = 0;

-- 3. Inspect negative production volume values
SELECT *
FROM production_log_staging
WHERE Production_Volume < 0;
-- No null or invalid production volume values were detected

-- ============================================================================================================================================
-- Standardize date format to ensure accurate analysis and reporting consistency
-- ============================================================================================================================================

-- 1. Preview date transformation results before applying updates to prevent unintended data corruption
SELECT `date`,
STR_TO_DATE(`date`, '%d/%m/%Y')
FROM production_log_staging;

-- 2. Convert DD/MM/YYYY to YYYY-MM-DD 
UPDATE production_log_staging
SET `date` = STR_TO_DATE(`date`, '%d/%m/%Y')
WHERE `date` LIKE '%/%' ;

-- 3. Validate that all duplicate rows have been removed, this query must return 0 rows
SELECT `date`
FROM production_log_staging
WHERE `date` LIKE '%/%';

-- 4. Conver column fotmat from TEXT to DATE for further analysis
ALTER TABLE production_log_staging
MODIFY COLUMN `date` DATE;

-- ============================================================================================================================================
-- Standardize all columns to eliminate inconsitent naming 
-- ============================================================================================================================================

-- [Line_number column]
-- 1. Identify inconsistent production line label
SELECT DISTINCT Line_number
FROM production_log_staging;
-- Result: 8 rows showed including (L1, L2, L3, L4)

-- However, SQL DISTINCT can hide case variations ('Line1' vs 'line1')
-- Therefore, I applied UPPER() and listed all structural variations to ensure 100% robust standardization
-- 2. Found inconsistent values; added a preview column to validate the standardization logic 
SELECT Line_number AS original_line,
CASE
	WHEN UPPER(TRIM(Line_number)) IN ('L1', 'LINE 1') THEN 'Line 1'
	WHEN UPPER(TRIM(Line_number)) IN ('L2', 'LINE 2') THEN 'Line 2'
	WHEN UPPER(TRIM(Line_number)) IN ('L3', 'LINE 3') THEN 'Line 3'
	WHEN UPPER(TRIM(Line_number)) IN ('L4', 'LINE 4') THEN 'Line 4'
    ELSE TRIM(Line_number)
END AS Preview_line
FROM production_log_staging;

-- 3. Updating the column 
UPDATE production_log_staging
SET Line_number = CASE
	WHEN UPPER(TRIM(Line_number)) IN ('L1', 'LINE 1') THEN 'Line 1'
	WHEN UPPER(TRIM(Line_number)) IN ('L2', 'LINE 2') THEN 'Line 2'
	WHEN UPPER(TRIM(Line_number)) IN ('L3', 'LINE 3') THEN 'Line 3'
	WHEN UPPER(TRIM(Line_number)) IN ('L4', 'LINE 4') THEN 'Line 4'
    ELSE TRIM(Line_number)
  END;

-- [Shift column]
-- 1. Checking the column 
SELECT DISTINCT shift
FROM production_log_staging;
-- Validated that all values are consistent (no issues found)

-- [Product_ID column]
-- 1. Checking the column 
SELECT DISTINCT Product_ID
FROM production_log_staging;
-- Validated that all values are consistent (no issues found)

-- [Product_name column]
-- 1. Checking the column
SELECT DISTINCT Product_name
FROM production_log_staging;
-- Validated that all values are consistent (no issues found)

-- ============================================================================================================================================
-- Detect and remove duplicate to improve reporting accuracy
-- ============================================================================================================================================

-- 1. Identify duplicates using a CTE to preview duplicate row before removal
WITH cte_production_log AS
( 
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY `date`, Line_number, Shift, Product_ID, Product_name, Production_Volume) AS row_num
FROM production_log_staging
)
SELECT *
FROM cte_production_log 
WHERE row_num > 1;
-- Identified 5 duplicate rows

-- 2. Create a secondary staging table to safely isolate duplicate removal logic without modifying the original staging dataset
CREATE TABLE `production_log_staging2` (
  `Date` text,
  `Line_Number` text,
  `Shift` text,
  `Product_ID` int DEFAULT NULL,
  `Product_Name` text,
  `Production_Volume` double DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. Populate the new table with row number to flag duplicate records
INSERT INTO production_log_staging2
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY `date`, line_Number, Shift, Product_ID, Product_name, Production_Volume) AS row_num
FROM production_log_staging;

-- 4. Retain only the first occurrence of duplicated records preserve unique operational entries
DELETE 
FROM production_log_staging2
WHERE row_num >1;

-- 5. Verify that all duplicate rows have been removed, this query must return 0 rows
SELECT *
FROM production_log_staging2
WHERE row_num > 1;

-- 6. Delete the messy table and rename the staging2 to restore the original name
DROP TABLE production_log_staging;
RENAME TABLE production_log_staging2 TO production_log_staging;

-- 7. Remove temporary supporting column(row_num) used for duplicate identification
ALTER TABLE production_log_staging
DROP COLUMN row_num;

-- ============================================================================================================================================
-- Production_log Summary
-- ============================================================================================================================================
-- No null values detected in Production_Volume 
-- Standardized 12 inconsistent line labels
-- Converted all dates to ISO format (YYYY-MM-DD)
-- Removed 5 duplicate rows
-- All remaining production records were validated for structural consistency
