# Food Manufacturing Data Quality & Cleaning Project

## Project Overview
- This project focuses on cleaning and standardizing food manufacturing operational datasets based on **my practical manufacturing experience**.
- The datasets include Production logs, Downtime records, Warehouse holds, and Customer complaints.
- Rather than using perfectly structured sample data, the project was built around handling inconsistent and unreliable operational records that commonly found in real manufacturing environments.
<br><br>

## Why This Became a Data Cleaning Project?
- Initially, the goal of this project was to perform Exploratory Data Analysis (EDA) and generate operational insights.
- However, I identified a major consistency issue between production logs and downtime register after datasets cleaning.
- The Downtime dataset recorded a **Line 1** was stopped on January 2nd, while the Production dataset showed that only **Line 3** was operating on the same date.
- Because the datasets did not maintain reliable relational consistency, I decided not to force EDA on potentially unreliable data.
- Therefore, the project shifted toward data cleaning, validation, and operational quality review to preserve data integrity before analysis.
<br><br>

## Repository Structure
- `datasets/raw/` : Original inconsistent CSV datasets
- `datasets/cleaned/` : Standardized and cleaned datasets
- `sql_scripts/` : SQL cleaning and validation scripts
- `screenshots/` : Validation and query result screenshots
- `documentation/` : Additional cleaning notes and project summaries
<br><br>

## Core Quality Reviews & Cleaning Logic
### 1. Hold Data Validation
- I used `ROW_NUMVER() OVER(PARTITION BY)` to review potential duplicate values.
- After reviewing the records, I found that duplicated values contained different details and were not actual duplicates.
- The records were intentionally preserved to avoid unnecessary data lose.
- Please refer to `screenshots/sql_validation_examples.png`
<br><br>

### 2. Duration Validation
- Reviewed **Hold_duration_days** by comparing stored values against recalculated `DATEDIFF()` results.
- This validation identified several rows with inconsistent duration values.
- Additional investigation showed that some records were affected by inconsistent data formatting due to unclear raw data.
- Instead of forcefully correcting uncertain values, affected rows were flagged as `unclear` to preserve traceability and reporting reliability.
- Please refer to `screenshots/data_quality_review.png`


