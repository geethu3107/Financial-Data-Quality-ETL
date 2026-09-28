# Azure Data Factory ETL Workflow Design

## Objective

Design an Azure Data Factory workflow for onboarding financial complaint
data into a SQL target while applying data transformation and data-quality
validation.

## Source

Financial complaint CSV containing 86,288 records.

## Workflow

1. Source CSV
2. Azure Data Factory source dataset
3. Copy/ETL activity
4. SQL target table
5. Source-to-target reconciliation
6. Post-load data-quality validation
7. Exception capture
8. Defect investigation and RCA

## Transformation

- Convert ISO 8601 timestamp values to SQL DATE values.
- Trim text fields.
- Convert empty text values to NULL where appropriate.
- Preserve Complaint ID as the unique identifier.
- Validate mandatory fields.
- Validate date consistency.
- Identify missing/unknown State values.

## Target

SQL table:

financial_complaints_target

## Validation

The workflow is followed by:

- Record-count reconciliation
- Unique Complaint ID reconciliation
- Missing-record checks
- Extra-record checks
- Mandatory-field validation
- Duplicate validation
- Date validation
- Data-quality exception capture

## Exception Handling

Data-quality exceptions are stored in:

dq_exceptions

Root-cause findings are documented in:

dq_rca_log

## Deployment Status

The workflow was designed based on the implemented local SQL ETL process.
Live Azure Data Factory execution was not performed because an Azure
subscription was not provisioned.