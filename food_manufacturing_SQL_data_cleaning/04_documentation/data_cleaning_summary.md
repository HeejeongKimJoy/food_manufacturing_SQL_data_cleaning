## Data Cleaning Summary
This project focused on cleaning and validating datasets used for production, downtime, hold and complaint tracking.
The objective was to improve data consistency, preserve raw data integrity, and prepare analysis-ready for further EDA and Power BI reporting.



## Key Cleaning Tasks

**1. Data Standardization**
- Reviewed inconsistent date formats
- Standardized '/' and '-' formatting using 'STR_TO_DATE()' to handle mixed date formats
- Preserved unclear date values to avoid data corruption

## 2. Duplicate Validation
- Reviewed duplicate values using CTEs & Window Functions, 'ROW_NUMBER() OVER (PARTITION BY)' were used
- Confirmed that duplicated values represented different operational events
- Preserved records to avoid unnecessary data loss

## 3. Data integrity Validation
- Validated 'Product_ID' and 'Product_name' consistency
- Reviewed operational date relationships across datasets
- Identified records with unclear or potentially corrupted values

## 4. Text Standardization
- Applied 'TRIM()', 'UPPER()' and 'LENGTH()' functions
- Used 'CASE WHEN' to standardize inconsistent category values
- Standardized inconsistent names and text formatting
