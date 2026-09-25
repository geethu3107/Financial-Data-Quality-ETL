CREATE DATABASE financial_data_quality;

USE financial_data_quality;

SELECT DATABASE();

-- =========================================================
-- 1. BASIC DATASET VALIDATION
-- =========================================================
ALTER TABLE data_quality_validation_final
CHANGE COLUMN `ï»¿Date received` `Date received` TEXT;
SELECT COUNT(*) AS total_records
FROM data_quality_validation_final;


SELECT *
FROM data_quality_validation_final
LIMIT 5;


SELECT
    COUNT(*) AS total_records,
    COUNT(`Complaint ID`) AS non_null_complaint_ids,
    COUNT(*) - COUNT(`Complaint ID`) AS null_complaint_ids,
    COUNT(DISTINCT `Complaint ID`) AS unique_complaint_ids
FROM data_quality_validation_final;


-- =========================================================
-- 2. DUPLICATE COMPLAINT ID CHECK
-- =========================================================

SELECT
    `Complaint ID`,
    COUNT(*) AS occurrence_count
FROM data_quality_validation_final
GROUP BY `Complaint ID`
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;

-- =========================================================
-- 3. COMPLETENESS VALIDATION
-- =========================================================

SELECT
    SUM(CASE
        WHEN Product IS NULL OR TRIM(Product) = ''
        THEN 1 ELSE 0
    END) AS missing_product,

    SUM(CASE
        WHEN Issue IS NULL OR TRIM(Issue) = ''
        THEN 1 ELSE 0
    END) AS missing_issue,

    SUM(CASE
        WHEN `Sub-product` IS NULL OR TRIM(`Sub-product`) = ''
        THEN 1 ELSE 0
    END) AS missing_sub_product,

    SUM(CASE
        WHEN `Sub-issue` IS NULL OR TRIM(`Sub-issue`) = ''
        THEN 1 ELSE 0
    END) AS missing_sub_issue,

    SUM(CASE
        WHEN Company IS NULL OR TRIM(Company) = ''
        THEN 1 ELSE 0
    END) AS missing_company
FROM data_quality_validation_final;


-- =========================================================
-- 4. DATE VALIDATION
-- =========================================================

SELECT
    SUM(CASE
        WHEN `Date received` IS NULL
        THEN 1 ELSE 0
    END) AS missing_received_date,

    SUM(CASE
        WHEN `Date sent to company` IS NULL
        THEN 1 ELSE 0
    END) AS missing_sent_date
FROM data_quality_validation_final;


-- =========================================================
-- 5. DATE CONSISTENCY
-- Date sent should not be earlier than Date received
-- =========================================================

SELECT COUNT(*) AS invalid_date_sequence
FROM data_quality_validation_final
WHERE `Date sent to company` < `Date received`;


-- Show the actual problematic records, if any

SELECT
    `Complaint ID`,
    `Date received`,
    `Date sent to company`
FROM data_quality_validation_final
WHERE `Date sent to company` < `Date received`
ORDER BY `Date received`;


-- =========================================================
-- 6. TIMELY RESPONSE VALIDATION
-- =========================================================

SELECT
    `Timely response?`,
    COUNT(*) AS record_count
FROM data_quality_validation_final
GROUP BY `Timely response?`
ORDER BY record_count DESC;


-- Check unexpected Timely Response values

SELECT DISTINCT
    `Timely response?`
FROM data_quality_validation_final;


-- =========================================================
-- 7. COMPANY RESPONSE ANALYSIS
-- =========================================================

SELECT
    `Company response to consumer`,
    COUNT(*) AS record_count
FROM data_quality_validation_final
GROUP BY `Company response to consumer`
ORDER BY record_count DESC;


-- =========================================================
-- 8. TIMELY RESPONSE / COMPANY RESPONSE CONSISTENCY
-- =========================================================

SELECT COUNT(*) AS inconsistent_timely_records
FROM data_quality_validation_final
WHERE
    `Timely response?` = 'Yes'
    AND `Company response to consumer` = 'No';


-- =========================================================
-- 9. STATE VALIDATION
-- =========================================================

SELECT
    State,
    COUNT(*) AS record_count
FROM data_quality_validation_final
GROUP BY State
ORDER BY record_count DESC;


-- Missing State records

SELECT COUNT(*) AS missing_state
FROM data_quality_validation_final
WHERE State IS NULL OR TRIM(State) = '';


-- =========================================================
-- 10. ZIP CODE ANALYSIS
-- =========================================================

SELECT
    `ZIP code`,
    COUNT(*) AS record_count
FROM data_quality_validation_final
WHERE `ZIP code` IS NOT NULL
GROUP BY `ZIP code`
ORDER BY record_count DESC
LIMIT 20;


-- =========================================================
-- 11. PRODUCT / SUB-PRODUCT CONSISTENCY
-- =========================================================

SELECT
    Product,
    `Sub-product`,
    COUNT(*) AS record_count
FROM data_quality_validation_final
GROUP BY
    Product,
    `Sub-product`
ORDER BY record_count DESC;


-- =========================================================
-- 12. ISSUE / SUB-ISSUE CONSISTENCY
-- =========================================================

SELECT
    Issue,
    `Sub-issue`,
    COUNT(*) AS record_count
FROM data_quality_validation_final
GROUP BY
    Issue,
    `Sub-issue`
ORDER BY record_count DESC;


-- =========================================================
-- 13. EX001 - LARGE RESPONSE-DATE GAPS
-- =========================================================

SELECT
    `Complaint ID`,
    `Date received`,
    `Date sent to company`,
    DATEDIFF(
        `Date sent to company`,
        `Date received`
    ) AS response_gap_days
FROM data_quality_validation_final
WHERE DATEDIFF(
        `Date sent to company`,
        `Date received`
      ) > 30
ORDER BY response_gap_days DESC;


-- =========================================================
-- 14. EXCEPTION COUNT FOR LARGE DATE GAPS
-- =========================================================

SELECT
    COUNT(*) AS large_date_gap_records
FROM data_quality_validation_final
WHERE DATEDIFF(
        `Date sent to company`,
        `Date received`
      ) > 30;


-- =========================================================
-- 15. NEW POWER QUERY DQ COLUMNS
-- =========================================================

SELECT
    `DQ002 IDuniqueness`,
    COUNT(*) AS record_count
FROM data_quality_validation_final
GROUP BY `DQ002 IDuniqueness`;


SELECT
    `DQ005 Subproduct`,
    COUNT(*) AS record_count
FROM data_quality_validation_final
GROUP BY `DQ005 Subproduct`;


SELECT
    `DQ006 Subissue`,
    COUNT(*) AS record_count
FROM data_quality_validation_final
GROUP BY `DQ006 Subissue`;


SELECT
    `DQ009 Date Validity`,
    COUNT(*) AS record_count
FROM data_quality_validation_final
GROUP BY `DQ009 Date Validity`;


SELECT
    `DQ012 State validity`,
    COUNT(*) AS record_count
FROM data_quality_validation_final
GROUP BY `DQ012 State validity`;


SELECT
    `DQ014-Response to consumer`,
    COUNT(*) AS record_count
FROM data_quality_validation_final
GROUP BY `DQ014-Response to consumer`;


SELECT
    `DQ015 Tags`,
    COUNT(*) AS record_count
FROM data_quality_validation_final
GROUP BY `DQ015 Tags`;


-- =========================================================
-- 16. FINAL DATA QUALITY CLASSIFICATION
-- =========================================================

SELECT
    `Final Data Quality Classification`,
    COUNT(*) AS record_count
FROM data_quality_validation_final
GROUP BY `Final Data Quality Classification`
ORDER BY record_count DESC;


-- =========================================================
-- 17. OVERALL DATA QUALITY STATUS
-- =========================================================

SELECT
    OverallDQStatus,
    COUNT(*) AS record_count
FROM data_quality_validation_final
GROUP BY OverallDQStatus
ORDER BY record_count DESC;


-- =========================================================
-- 18. SHOW RECORDS REQUIRING ATTENTION
-- =========================================================

SELECT *
FROM data_quality_validation_final
WHERE OverallDQStatus <> 'Pass'
ORDER BY `Complaint ID`;


-- =========================================================
-- 19. FINAL PROJECT SUMMARY
-- =========================================================

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT `Complaint ID`) AS unique_complaint_ids,

    SUM(
        CASE
            WHEN OverallDQStatus = 'Pass'
            THEN 1 ELSE 0
        END
    ) AS passed_records,

    SUM(
        CASE
            WHEN OverallDQStatus <> 'Pass'
            THEN 1 ELSE 0
        END
    ) AS records_requiring_attention

FROM data_quality_validation_final;

