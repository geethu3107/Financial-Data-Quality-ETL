-- ============================================================
-- Financial Data Onboarding & Data Quality Validation
-- ============================================================
-- Dataset: 86,288 financial complaint records
-- Database: financial_data_onboarding
--
-- Workflow:
-- Raw Source
--     -> ETL Transformation
--     -> Target Table
--     -> Source-to-Target Reconciliation
--     -> Post-Load Validation
--     -> DQ Exceptions
--     -> Defect Investigation
--     -> Root Cause Analysis
--
-- Tools: MySQL
-- ============================================================


-- ============================================================
-- 1. CREATE DATABASE
-- ============================================================

CREATE DATABASE financial_data_onboarding;

USE financial_data_onboarding;

SELECT DATABASE();


-- ============================================================
-- 2. CREATE RAW SOURCE TABLE
-- ============================================================
-- Raw source fields are initially stored as VARCHAR where
-- transformation may be required during ETL.
--
-- The source date fields contain ISO 8601 timestamps such as:
-- 2025-01-01T02:57:50.000Z
-- ============================================================

CREATE TABLE raw_complaints (
    `Date received` VARCHAR(50),
    `Product` VARCHAR(255),
    `Sub-product` VARCHAR(255),
    `Issue` VARCHAR(255),
    `Sub-issue` VARCHAR(255),
    `Company public response` VARCHAR(255),
    `Company` VARCHAR(255),
    `State` VARCHAR(50),
    `ZIP code` VARCHAR(50),
    `Tags` VARCHAR(255),
    `Submitted via` VARCHAR(100),
    `Date sent to company` VARCHAR(50),
    `Company response to consumer` VARCHAR(255),
    `Timely response?` VARCHAR(50),
    `Complaint ID` BIGINT
);


-- ============================================================
-- 3. VALIDATE RAW SOURCE
-- ============================================================

-- Check total source records
SELECT COUNT(*) AS source_records
FROM raw_complaints;

-- Check unique Complaint IDs
SELECT COUNT(DISTINCT `Complaint ID`) AS unique_complaint_ids
FROM raw_complaints;

-- Inspect sample source records
SELECT *
FROM raw_complaints
LIMIT 5;


-- ============================================================
-- 4. CREATE TARGET TABLE
-- ============================================================
-- Target table uses DATE data types for the two date fields.
-- Complaint ID is defined as the primary key.
-- ============================================================

CREATE TABLE financial_complaints_target (
    `Date received` DATE,
    `Product` VARCHAR(255),
    `Sub-product` VARCHAR(255),
    `Issue` VARCHAR(255),
    `Sub-issue` VARCHAR(255),
    `Company public response` VARCHAR(255),
    `Company` VARCHAR(255),
    `State` VARCHAR(50),
    `ZIP code` VARCHAR(50),
    `Tags` VARCHAR(255),
    `Submitted via` VARCHAR(100),
    `Date sent to company` DATE,
    `Company response to consumer` VARCHAR(255),
    `Timely response?` VARCHAR(50),
    `Complaint ID` BIGINT PRIMARY KEY
);


-- ============================================================
-- 5. ETL TRANSFORMATION AND TARGET LOAD
-- ============================================================
-- Transformations performed:
--
-- 1. Extract YYYY-MM-DD from ISO 8601 timestamps.
-- 2. Convert the extracted values to SQL DATE.
-- 3. Trim text fields.
-- 4. Convert empty strings to NULL.
-- 5. Preserve Complaint ID as the unique identifier.
--
-- Note:
-- An initial load attempt using MM/DD/YYYY date parsing failed
-- because the source contained ISO 8601 timestamps.
-- The transformation was corrected using LEFT(..., 10)
-- followed by STR_TO_DATE(..., '%Y-%m-%d').
-- ============================================================

INSERT INTO financial_complaints_target
(
    `Date received`,
    `Product`,
    `Sub-product`,
    `Issue`,
    `Sub-issue`,
    `Company public response`,
    `Company`,
    `State`,
    `ZIP code`,
    `Tags`,
    `Submitted via`,
    `Date sent to company`,
    `Company response to consumer`,
    `Timely response?`,
    `Complaint ID`
)
SELECT
    STR_TO_DATE(
        LEFT(TRIM(`Date received`), 10),
        '%Y-%m-%d'
    ),

    NULLIF(TRIM(`Product`), ''),
    NULLIF(TRIM(`Sub-product`), ''),
    NULLIF(TRIM(`Issue`), ''),
    NULLIF(TRIM(`Sub-issue`), ''),
    NULLIF(TRIM(`Company public response`), ''),
    NULLIF(TRIM(`Company`), ''),
    NULLIF(TRIM(`State`), ''),
    NULLIF(TRIM(`ZIP code`), ''),
    NULLIF(TRIM(`Tags`), ''),
    NULLIF(TRIM(`Submitted via`), ''),

    STR_TO_DATE(
        LEFT(TRIM(`Date sent to company`), 10),
        '%Y-%m-%d'
    ),

    NULLIF(TRIM(`Company response to consumer`), ''),
    NULLIF(TRIM(`Timely response?`), ''),

    `Complaint ID`

FROM raw_complaints;


-- ============================================================
-- 6. VALIDATE TARGET LOAD
-- ============================================================

-- Check total target records
SELECT COUNT(*) AS target_records
FROM financial_complaints_target;

-- Check unique target Complaint IDs
SELECT COUNT(DISTINCT `Complaint ID`) AS unique_target_ids
FROM financial_complaints_target;

-- Inspect sample target records
SELECT *
FROM financial_complaints_target
LIMIT 5;


-- ============================================================
-- 7. SOURCE-TO-TARGET RECONCILIATION
-- ============================================================
-- Verify that source and target contain the same number
-- of records.
-- ============================================================

SELECT
    (SELECT COUNT(*)
     FROM raw_complaints) AS source_records,

    (SELECT COUNT(*)
     FROM financial_complaints_target) AS target_records;


-- Compare unique Complaint IDs

SELECT
    (SELECT COUNT(DISTINCT `Complaint ID`)
     FROM raw_complaints) AS source_unique_ids,

    (SELECT COUNT(DISTINCT `Complaint ID`)
     FROM financial_complaints_target) AS target_unique_ids;


-- Check for source records missing in target

SELECT COUNT(*) AS missing_in_target
FROM raw_complaints r
LEFT JOIN financial_complaints_target t
    ON r.`Complaint ID` = t.`Complaint ID`
WHERE t.`Complaint ID` IS NULL;


-- Check for extra target records that do not exist in source

SELECT COUNT(*) AS extra_in_target
FROM financial_complaints_target t
LEFT JOIN raw_complaints r
    ON t.`Complaint ID` = r.`Complaint ID`
WHERE r.`Complaint ID` IS NULL;


-- ============================================================
-- 8. POST-LOAD DATA QUALITY VALIDATION
-- ============================================================

-- Check mandatory fields for NULL values

SELECT
    SUM(`Complaint ID` IS NULL) AS missing_complaint_id,
    SUM(`Product` IS NULL) AS missing_product,
    SUM(`Issue` IS NULL) AS missing_issue,
    SUM(`Sub-product` IS NULL) AS missing_sub_product,
    SUM(`Sub-issue` IS NULL) AS missing_sub_issue,
    SUM(`Company` IS NULL) AS missing_company
FROM financial_complaints_target;


-- Check for duplicate Complaint IDs

SELECT
    `Complaint ID`,
    COUNT(*) AS occurrence_count
FROM financial_complaints_target
GROUP BY `Complaint ID`
HAVING COUNT(*) > 1;


-- Check date consistency.
-- Date sent to company should not be earlier than Date received.

SELECT COUNT(*) AS invalid_date_sequence
FROM financial_complaints_target
WHERE `Date sent to company` < `Date received`;


-- Check distribution of Timely Response values

SELECT
    `Timely response?`,
    COUNT(*) AS record_count
FROM financial_complaints_target
GROUP BY `Timely response?`
ORDER BY record_count DESC;


-- ============================================================
-- 9. CREATE DATA QUALITY EXCEPTION TABLE
-- ============================================================
-- DQ012 identifies State values represented as the literal
-- string "None". These values are treated as missing/unknown
-- and require investigation.
-- ============================================================

CREATE TABLE dq_exceptions (
    exception_id INT AUTO_INCREMENT PRIMARY KEY,
    rule_id VARCHAR(20),
    complaint_id BIGINT,
    field_name VARCHAR(100),
    issue_description VARCHAR(500),
    severity VARCHAR(20),
    status VARCHAR(30),
    identified_date DATE
);


-- ============================================================
-- 10. CAPTURE STATE DATA QUALITY EXCEPTIONS
-- ============================================================

INSERT INTO dq_exceptions
(
    rule_id,
    complaint_id,
    field_name,
    issue_description,
    severity,
    status,
    identified_date
)
SELECT
    'DQ012',
    `Complaint ID`,
    'State',
    'State value is represented as literal None and requires investigation',
    'Medium',
    'Open',
    CURDATE()

FROM financial_complaints_target

WHERE LOWER(TRIM(`State`)) = 'none';


-- Review captured exceptions

SELECT *
FROM dq_exceptions
LIMIT 10;


-- ============================================================
-- 11. INVESTIGATE DQ EXCEPTIONS
-- ============================================================
-- Analyze affected records by Product and Issue.
-- ============================================================

SELECT
    `Product`,
    `Issue`,
    COUNT(*) AS exception_count
FROM financial_complaints_target
WHERE LOWER(TRIM(`State`)) = 'none'
GROUP BY `Product`, `Issue`
ORDER BY exception_count DESC;


-- Confirm representation in the raw source

SELECT
    `State`,
    COUNT(*) AS record_count
FROM raw_complaints
WHERE LOWER(TRIM(`State`)) = 'none'
GROUP BY `State`;


-- Inspect sample affected records

SELECT
    `Complaint ID`,
    `Product`,
    `Issue`,
    `Company`,
    `State`
FROM financial_complaints_target
WHERE LOWER(TRIM(`State`)) = 'none'
LIMIT 10;


-- ============================================================
-- 12. CREATE ROOT CAUSE ANALYSIS LOG
-- ============================================================

CREATE TABLE dq_rca_log (
    rca_id INT AUTO_INCREMENT PRIMARY KEY,
    rule_id VARCHAR(20),
    issue VARCHAR(255),
    affected_records INT,
    root_cause VARCHAR(500),
    corrective_action VARCHAR(500),
    status VARCHAR(30),
    identified_date DATE
);


-- ============================================================
-- 13. DOCUMENT ROOT CAUSE ANALYSIS
-- ============================================================
-- Finding:
-- 183 records contain the literal value "None" for State.
--
-- Root cause:
-- The source represents missing State information using the
-- literal text "None" rather than a SQL NULL value.
--
-- Corrective action:
-- Treat "None" as a missing-value representation during DQ
-- validation and investigate without inferring a State value.
-- ============================================================

INSERT INTO dq_rca_log
(
    rule_id,
    issue,
    affected_records,
    root_cause,
    corrective_action,
    status,
    identified_date
)
VALUES
(
    'DQ012',
    'State represented as literal None',
    183,
    'Source records contain the literal value None instead of a valid State value.',
    'Retain the records for investigation and treat None as a missing-value representation during validation. Do not infer or replace the State without an authoritative source.',
    'Open',
    CURDATE()
);


-- Review RCA record

SELECT *
FROM dq_rca_log;


-- ============================================================
-- END OF FINANCIAL DATA ONBOARDING ETL
-- ============================================================