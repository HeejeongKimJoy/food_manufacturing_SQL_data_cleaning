-- ============================================================================================================================================
-- ============================================================================================================================================
--  Part 2. Downtime_register
-- Creating a staging table of Production_log to preserve raw data integrity
-- ============================================================================================================================================
-- ============================================================================================================================================

CREATE TABLE  downtime_register_staging AS
SELECT *
FROM downtime_register_raw;

SELECT *
FROM downtime_register_staging;

-- ============================================================================================================================================
-- Inspect invalid or missing values to maintain data accuracy and reporting reliability
-- ============================================================================================================================================

-- 1. Inspect null values
SELECT *
FROM downtime_register_staging
WHERE `date` IS NULL
	OR Downtime_ID IS NULL
    OR Line_number IS NULL
    OR Shift IS NULL
    OR Reason IS NULL
    OR Duration_minutes IS NULL;

-- 2. Inspect zero values in numerical columns to ensure data accuracy and reporting reliability
SELECT *
FROM downtime_register_staging
WHERE Duration_minutes = 0;

-- 3. Inspect negative production volume values
SELECT *
FROM downtime_register_staging
WHERE Duration_minutes < 0;
-- Result: 10 rows were identified

SELECT AVG(Duration_minutes)
FROM downtime_register_staging;
-- The overall average duration is 118 minutes, whereas all negative values are above -40 
-- Imputing these rows with the average would distort the data accuracy
-- Deleting these 10 rows would result in unnecessary data loss
-- Therefore, these negative values are treated as simple human data-entry mistakes
-- The negative signs will be removed using the ABS() function to preserve operational records while correcting obvious data-entry errors

UPDATE downtime_register_staging
SET Duration_minutes = ABS(Duration_minutes)
WHERE Duration_minutes < 0;

-- ============================================================================================================================================
-- Standardize date format to ensure accurate analysis and reporting consistency
-- ============================================================================================================================================

-- 1. Validate that all values can be successfully converted to DATE format
SELECT DISTINCT `date`
FROM downtime_register_staging
WHERE STR_TO_DATE(`date`, '%Y-%m-%d') IS NULL;
-- Verified that all date values follow the 'YYYY-MM-DD' format

-- 2. Convert `date` format from TEXT to DATE for further analysis 
ALTER TABLE downtime_register_staging
MODIFY COLUMN `date` DATE;

-- ============================================================================================================================================
-- Standardize all columns to eliminate inconsitent naming 
-- ============================================================================================================================================

-- [Downtime_ID] 
-- This column contains unique system identifiers 
-- no business value or meaningful insights for further analysis
-- Therefore, this column is intentionally left untouched and skipped from the cleaning process except checking duplicates

WITH cte_downtime_id AS
(
SELECT *,
ROW_NUMBER () OVER(
PARTITION BY Downtime_ID) AS row_num
FROM downtime_register_staging
)
SELECT *
FROM cte_downtime_id
WHERE row_num > 1 ;
-- Result: 3 rows have been identified

SELECT *
FROM downtime_register_staging
WHERE Downtime_ID = 'D12071';

SELECT *
FROM downtime_register_staging
WHERE Downtime_ID = 'D74436';

SELECT *
FROM downtime_register_staging
WHERE Downtime_ID = 'D91785';
-- Confirmed that these records occurred on completely different dates with different values
-- This indicates that these rows are not actual duplicates
-- No rows will be removed, as doing so would cause critical data loss for those distinct dates
-- Instead, this column will not be used for further analysis

-- [Line_number column]
-- 1. Identify inconsistent production line label
SELECT DISTINCT Line_number
FROM downtime_register_staging;
-- Result: 8 rows showed including (L1, Line1)
-- However, SQL DISTINCT can hide case variations ('Line1' vs 'line1')
-- Therefore, I applied UPPER() and listed all structural variations to ensure 100% robust standardization

-- 2. Found inconsistent values; added a preview column to validate the standardization 
SELECT Line_number AS original_line,
CASE 
	WHEN UPPER(TRIM(Line_number)) IN ('L1', 'LINE1', 'LINE 1') THEN 'Line 1'
    WHEN UPPER(TRIM(Line_number)) IN ('LINE 2') THEN 'Line 2'
	WHEN UPPER(TRIM(Line_number)) IN ('LINE 3') THEN 'Line 3'
	WHEN UPPER(TRIM(Line_number)) IN ('LINE 4') THEN 'Line 4'
    ELSE TRIM(Line_number)
END AS preview_line
FROM downtime_register_staging;

-- 3. Update the inconsistent values to standardized format
UPDATE downtime_register_staging
SET Line_number = CASE 
	WHEN UPPER(TRIM(Line_number)) IN ('L1', 'Line1', 'LINE 1') THEN 'Line 1'
    WHEN UPPER(TRIM(Line_number)) IN ('LINE 2') THEN 'Line 2'
	WHEN UPPER(TRIM(Line_number)) IN ('LINE 3') THEN 'Line 3'
	WHEN UPPER(TRIM(Line_number)) IN ('LINE 4') THEN 'Line 4'
    ELSE TRIM(Line_number)
END ;

-- [Shift column]
SELECT DISTINCT Shift
FROM downtime_register_staging;
-- Validated that all values are consistent (no issues found)

-- [Reason column]
SELECT DISTINCT Reason 
FROM downtime_register_staging;
-- Validated that all values are consistent (no issues found)

-- [Duration_minutes column]
-- This column was previously checked for negative values
-- Therefore, the MAX and MIN values will now be audited for quality control
SELECT MAX(Duration_minutes), MIN(Duration_minutes)
FROM downtime_register_staging;
-- Result: Max(240), Min(5)
-- The values align perfectly with expected manufacturing downtime boundaries
-- Since the data shows no unrealistic values, it is accepted as reliable

-- ============================================================================================================================================
-- Detect and remove duplicate to improve reporting accuracy
-- ============================================================================================================================================

WITH cte_downtime AS
(
SELECT *,
ROW_NUMBER () OVER(
PARTITION BY `date`, Downtime_ID, Line_number, Shift, Reason, Duration_minutes) AS row_num
FROM downtime_register_staging
)
SELECT *
FROM cte_downtime
WHERE row_num > 1 ;
-- Result: no duplicates were identified

-- ============================================================================================================================================
-- Downtime_register Summary
-- ============================================================================================================================================
-- Detected and corrected 10 negative duration values caused by data-entry errors
-- Identified 3 duplicated Downtime_ID records; however, these were confirmed as valid operational records with different dates and durations
-- No duplicate rows were removed to avoid unnecessary data loss
-- Converted all dates to ISO format (YYYY-MM-DD)
-- Standardized inconsistent Line_number labels
