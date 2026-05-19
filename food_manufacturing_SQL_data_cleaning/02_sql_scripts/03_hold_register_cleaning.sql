-- ============================================================================================================================================
-- ============================================================================================================================================
--  Part 3. Hold_register
-- Creating a staging table of Production_log to preserve raw data integrity
-- ============================================================================================================================================
-- ============================================================================================================================================

CREATE TABLE hold_register_staging AS
SELECT *
FROM hold_register_raw;

SELECT *
FROM hold_register_staging;

-- ============================================================================================================================================
-- Inspect invalid or missing values to maintain data accuracy and reporting reliability
-- ============================================================================================================================================

-- 1. Inspect null values
-- Validation will focus on critical columns required for operational analysis and table relationships
-- 'Hold_ID' : Unique values that can track each hold event
-- 'Product_ID': Essential values for establishing relationship with the 'production_log' table
-- 'Hold_date': Essential values for Lead time analysis and fiscal period grouping
-- 'Hold_qty': Essential values for calculating the impact volume for KPI report 
SELECT *
FROM hold_register_staging
WHERE Hold_ID IS NULL
	OR Product_ID IS NULL
    OR Hold_date IS NULL
    OR Hold_qty IS NULL;

-- 2. Inspect zero values in numerical columns to ensure data accuracy and reporting reliability
SELECT *
FROM hold_register_staging
WHERE Product_ID = 0
	OR Hold_qty = 0
    OR Hold_duration_days = 0;

-- 3. Inspect negative production volume values
SELECT *
FROM hold_register_staging
WHERE Hold_qty < 0;

-- No null or invalid production volume values were detected

-- ============================================================================================================================================
-- Standardize date format to ensure accurate analysis and reporting consistency
-- ============================================================================================================================================

-- [Hold_date Column]
-- 1. Preview date transformation results before applying updates to prevent unintended data corruption
SELECT hold_date
FROM hold_register_staging
WHERE hold_date LIKE '%/%';
-- Result: Identified 20 rows with inconsistent format

-- 2. Convert '/' format to '-'
UPDATE hold_register_staging
SET hold_date = REPLACE(hold_date, '/', '-')
WHERE hold_date LIKE '%/%'; 

-- 3. Review 
SELECT Hold_date
FROM hold_register_staging
ORDER BY hold_date ASC;

SELECT *
FROM hold_register_staging
WHERE hold_date NOT LIKE '____-%';
-- Result: 12 rows were identified with inconsistent formats
-- These rows could not be clearly identified as either 'DD-MM-YYYY' or 'MM-DD-YYYY'
-- Cross-validation against 'hold close date' and 'hold duration days' values did not provide sufficient confidence for accurate conversion
-- To prevent unintended date corruption, the original values were preserved
-- A separate validation status column will be created to flag these unclear data for downstream reporting and Power BI filtering

-- 4. Create a secondary staging table with validation flag columns
CREATE TABLE `hold_register_staging2` (
  `Hold_ID` text,
  `Hold_category` int DEFAULT NULL,
  `Name` text,
  `Hold_date` text,
  `Production_date` text,
  `Product_ID` int DEFAULT NULL,
  `Product_name` text,
  `Hold_qty` double DEFAULT NULL,
  `Hold_reason` text,
  `Hold_close_date` text,
  `Hold_duration_days` int DEFAULT NULL,
  `Hold_date_validation` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO hold_register_staging2
SELECT *,
CASE
    WHEN STR_TO_DATE(Hold_date, '%Y-%m-%d') IS NOT NULL THEN 'Valid'
    ELSE 'Unclear'
END AS Hold_date_validation
FROM hold_register_staging;

SELECT *
FROM hold_register_staging2
ORDER BY Hold_date_validation ASC;
-- Result: Total 12 rows marked 'Unclear'
-- Hold_date was intentionally preserved as TEXT as 12 rows contained unclear date formats
-- Forceful conversion could introduce inaccurate reporting and time-based analysis errors

-- [Production_date column]
SELECT Production_date
FROM hold_register_staging2
WHERE STR_TO_DATE(Production_date, '%Y-%m-%d') IS NULL;
-- Verified that all Production_date values can be successfully converted to DATE format (YYYY-MM-DD)

ALTER TABLE hold_register_staging2
MODIFY COLUMN production_date DATE;

-- [Hold_close_date column]
SELECT Hold_close_date
FROM hold_register_staging2
WHERE STR_TO_DATE(Hold_close_date, '%Y-%m-%d') IS NULL;
-- Verified that all Production_date values follow valid date format (YYYY-MM-DD)

ALTER TABLE hold_register_staging2
MODIFY COLUMN Hold_close_date DATE;

-- ============================================================================================================================================
-- Standardize all columns to eliminate inconsistent naming 
-- ============================================================================================================================================

-- [Hold_ID column]
-- 1. TRIM & UPPER
-- Hold_ID is used as an operational tracking identifier for hold events
-- Therefore, standardizing the values is required to ensure duplicate validation for traceability and reporting reliability
UPDATE hold_register_staging2
SET Hold_id = UPPER(TRIM(Hold_id));

-- 2. Duplicate validation
WITH cte_dup AS
(
SELECT *, 
ROW_NUMBER () OVER (
PARTITION BY Hold_id) AS Row_num
FROM hold_register_staging2
)
SELECT *
FROM cte_dup
WHERE Row_num > 1;
-- Result: 3 Rows were identified as duplicates

-- 3. Review duplicated Hold_ID records
SELECT *
FROM hold_register_staging2
WHERE Hold_id = 'H2078A';

SELECT *
FROM hold_register_staging2
WHERE Hold_id = 'H7693B';

SELECT *
FROM hold_register_staging2
WHERE Hold_id = 'H8834X';
-- Result: 3 duplicated Hold_ID values were identified (H2078A, H7693B, H8834X)
-- However, these records contain different operational details and are not true duplicate records
-- Since Hold_ID is not used as a relational join key, the records were preserved to avoid unnecessary data loss

-- [Hold_category column]
SELECT DISTINCT hold_category
FROM hold_register_staging2;
-- Validated that all category values are structurally consistent

-- [Name column]
-- 1. Review name
SELECT DISTINCT `Name`
FROM hold_register_staging2
ORDER BY `Name`;
-- Result: 'Sara Kim' and 'Sarah Kim' were identified as potential inconsistencies

-- 2. Investigate inconsistent name records
SELECT *
FROM hold_register_staging2
WHERE `name` LIKE 'Sara%'
ORDER BY `name`;
-- The majority of records use 'Sarah Kim'
-- Therefore, 'Sara Kim' was standardized to 'Sarah Kim'

-- 3. Standardize inconsistent name values
UPDATE hold_register_staging2
SET `Name` = 'Sarah Kim'
WHERE `Name` = 'Sara Kim';
-- Result: 10 rows were updated

-- [Product_ID column]
-- This column has already been validated for invalid or missing values
-- Therefore, Validation for Product_ID and Product_name consistency is required
-- Each Product_ID is expected to represent a single product name
-- GROUP BY and COUNT(DISTINCT) were used to identify potential inconsistencies
SELECT Product_ID, COUNT(DISTINCT Product_name)
FROM hold_register_staging2
GROUP BY Product_ID
HAVING COUNT(DISTINCT Product_name) > 1;
-- Result: 0 rows were returned, indicating no consistency issues were identified

-- [Product_name column]
SELECT DISTINCT product_name
FROM hold_register_staging2;

UPDATE hold_register_staging2
SET Product_name = TRIM(product_name);
-- Validated that all values are consistent (no issues found)

-- [Hold_qty column] 
-- This column has already been validated for invalid or missing values

-- [Hold_reason column]
-- 1. Review distinct hold reasons
SELECT DISTINCT Hold_reason
FROM hold_register_staging2
ORDER BY Hold_reason;
-- Validated that all values are consistent (no issues found)

-- 2. Standardize formatting
UPDATE hold_register_staging2
SET Hold_reason = TRIM(Hold_reason);
-- Validated that all values are consistent (no issues found)

-- [Hold_duration_days column]
-- Value 0 is possible in this column due to sameday hold
-- Therefore, NULL and negative values will be reviewed
-- 1. NULL or Negative values review
SELECT *
FROM hold_register_staging2
WHERE hold_duration_days IS NULL
	OR hold_duration_days < 0;
-- No issue found

-- 2. Duration calculation Review 
WITH cte_calculation AS 
(
SELECT Hold_id, Hold_date, Hold_close_date, Hold_duration_days,
DATEDIFF(Hold_close_date, STR_TO_DATE(Hold_date, '%Y-%m-%d')) AS calculated_duration
FROM hold_register_staging2
)
SELECT *
FROM cte_calculation
WHERE calculated_duration != Hold_duration_days
	OR calculated_duration IS NULL;
-- Result: Identified 8 rows with incorrect duration days and 12 rows marked as unclear 
-- (12 rows due to incorrect date format that we reviewed earlier)

-- 8 incorrect duration rows: 
-- Found that all 'hold_date' for these 8 rows were '2025-01-05'
-- These rows were originally formatted with '//' and later converted to'--'
-- This indicates that these values were potentially corrupted in the raw data table
-- Therefore, I will mark these values as 'unclear' instead of replacing the duration days 
-- to preserve data integrity and exclude them from further analysis

UPDATE hold_register_staging2
SET Hold_date_validation = 'Unclear'
WHERE Hold_date_validation = 'Valid'
	AND DATEDIFF(Hold_close_date, STR_TO_DATE(Hold_date, '%Y-%m-%d')) != Hold_duration_days;
-- Result: 8 rows have been updated to mark as 'Unclear'
-- STR_TO_DATE() was used because Hold_date remains stored as TEXT due to previously identified unclear date formats

-- 3. Review
WITH cte_calculation AS 
(
SELECT Hold_id, Hold_date, Hold_close_date, Hold_duration_days,
DATEDIFF(Hold_close_date, STR_TO_DATE(Hold_date, '%Y-%m-%d')) AS calculated_duration
FROM hold_register_staging2
WHERE Hold_date_validation = 'Valid'
)
SELECT *
FROM cte_calculation
WHERE calculated_duration != Hold_duration_days
	OR calculated_duration IS NULL;
-- Revalidated all rows marked as 'Valid'

SELECT *
FROM hold_register_staging2
WHERE Hold_date_validation = 'Unclear';
-- Result: 20 rows were returned
-- Confirmed that all remaining duration values correctly match the calculated date difference

-- ============================================================================================================================================
-- Hold_register Summary
-- ============================================================================================================================================
-- No null, zero, or negative quantity issues were identified
-- 20 rows with potentially corrupted or inconsistent Hold_date format were flagged as 'Unclear'
-- Hold_date was intentionally preserved as TEXT to avoid unintended date corruption
-- Product, name, and hold reason values were standardized for consistency
-- Duplicate Hold_ID values appeared to be simple typing errors as all related operational details were different
-- Therefore, the records were preserved to avoid unnecessary data loss
-- All remaining rows marked as 'Valid' successfully passed duration validation checks
