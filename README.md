# Financial Data Quality & ETL Validation

## Project Overview

A data quality and ETL validation project built using a real-world financial-services dataset from the Consumer Financial Protection Bureau (CFPB).

The project simulates a data onboarding workflow where source data is profiled, validated against defined business and data-quality rules, transformed, loaded into a target database, and checked through post-load validation and source-to-target reconciliation.

The focus is on identifying data-quality exceptions, distinguishing valid business conditions from actual defects, and performing structured root cause analysis.

---

## Business Problem

Before financial data is onboarded into an enterprise data environment, it must be checked for:

- Missing or incomplete values
- Duplicate records
- Invalid or inconsistent dates
- Invalid field formats
- Unexpected category combinations
- Source-to-target mismatches
- Data-quality exceptions

The objective of this project is to build a repeatable validation workflow that improves data integrity and provides clear evidence for resolving data-quality issues.

---

## Dataset

**Source:** Consumer Financial Protection Bureau (CFPB) Consumer Complaint Database

The dataset contains consumer complaint records related to financial products and services.

The project uses a filtered extract containing:

- **86,288 records**
- **15 columns**

Key fields include:

- Complaint ID
- Date received
- Product
- Sub-product
- Issue
- Sub-issue
- Company
- State
- ZIP code
- Submitted via
- Date sent to company
- Company response to consumer
- Timely response

The raw source file is preserved without modification.

---

## Project Workflow

```text
Real Financial Dataset
        ↓
Source Profiling
        ↓
Business Requirements & Data Quality Rules
        ↓
Excel / Power Query Validation
        ↓
SQL Validation & Exception Handling
        ↓
VBA Automation
        ↓
Azure Data Factory ETL
        ↓
Target SQL Database
        ↓
Post-Load Validation
        ↓
Source-to-Target Reconciliation
        ↓
Root Cause Analysis & Documentation
