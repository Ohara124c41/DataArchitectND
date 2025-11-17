-- ============================================================================
-- File: 02_data_quality_fixes.sql
-- Purpose: Remediate identified data quality issues
-- Project: SneakerPark Data Governance - Phase 1
-- Author: Data Architecture Team
-- Date: 2025-11-17
-- ============================================================================

-- This script applies fixes for the 4 existing data quality issues
-- Run 01_data_quality_checks.sql first to assess current state

-- WARNING: This script modifies data. Review carefully before execution.
-- Recommend running in transaction with ROLLBACK capability for testing.

\echo '========================================';
\echo 'SneakerPark Data Quality Remediation';
\echo 'Applying fixes for 4 existing issues...';
\echo '========================================';
\echo '';

-- Start transaction for safe rollback if needed
BEGIN;

-- ============================================================================
-- FIX 1: Missing ShoeType - Backfill from Inventory Management
-- ============================================================================

\echo '1. Fixing missing ShoeType values...';
\echo '';

-- Strategy: Infer ShoeType from im.Items.Type field using ProductID/SellerID match
-- This assumes ProductID can be mapped to ItemID through seller tracking

-- Step 1: Create temporary mapping between listings and items
CREATE TEMP TABLE temp_listing_item_mapping AS
SELECT
    l.ListingID,
    l.SellerID,
    l.ProductID,
    l.ShoeType AS current_shoetype,
    i.Type AS item_type,
    i.ItemID
FROM li.listings l
JOIN im.Items i
    ON l.SellerID = i.SellerID
WHERE l.ShoeType IS NULL
  AND i.Type IS NOT NULL;

\echo 'Listing-to-Item mapping created';
SELECT COUNT(*) AS mappable_listings FROM temp_listing_item_mapping;

-- Step 2: Update listings with inferred ShoeType
UPDATE li.listings
SET ShoeType = m.item_type
FROM temp_listing_item_mapping m
WHERE listings.ListingID = m.ListingID
  AND listings.ShoeType IS NULL;

\echo '';
\echo 'ShoeType values updated from Inventory Management';
SELECT COUNT(*) AS updated_count
FROM li.listings
WHERE ShoeType IS NOT NULL
  AND ListingID IN (SELECT ListingID FROM temp_listing_item_mapping);

-- Step 3: For remaining NULLs, set to 'Sneakers' (most common product type)
UPDATE li.listings
SET ShoeType = 'Sneakers'
WHERE ShoeType IS NULL;

\echo '';
\echo 'Remaining NULL ShoeType values set to default: Sneakers';
SELECT COUNT(*) AS defaulted_count
FROM li.listings
WHERE ShoeType = 'Sneakers';

\echo '';
\echo 'Fix 1 Complete: All listings now have ShoeType';
\echo '';

-- ============================================================================
-- FIX 2: Customer Name Mismatches - Sync from User Service (Source of Truth)
-- ============================================================================

\echo '2. Fixing customer name mismatches...';
\echo '';

-- Strategy: User Service (usr.users) is source of truth
-- Update Customer Service names to match

-- Step 1: Identify mismatches
CREATE TEMP TABLE temp_name_mismatches AS
SELECT
    cs.ID AS cs_request_id,
    cs.UserID,
    u.FirstName AS correct_firstname,
    u.LastName AS correct_lastname,
    cs.FirstName AS old_firstname,
    cs.LastName AS old_lastname
FROM cs.CustomerServiceRequests cs
JOIN usr.users u ON u.UserID = cs.UserID
WHERE u.FirstName != cs.FirstName
   OR u.LastName != cs.LastName;

\echo 'Name mismatches identified:';
SELECT COUNT(*) AS mismatch_count FROM temp_name_mismatches;

-- Step 2: Update Customer Service records to match User Service
UPDATE cs.CustomerServiceRequests
SET
    FirstName = m.correct_firstname,
    LastName = m.correct_lastname
FROM temp_name_mismatches m
WHERE CustomerServiceRequests.ID = m.cs_request_id;

\echo '';
\echo 'Customer Service names synchronized with User Service';
SELECT COUNT(*) AS updated_count FROM temp_name_mismatches;

\echo '';
\echo 'Verification: Remaining mismatches should be 0';
SELECT COUNT(*) AS remaining_mismatches
FROM cs.CustomerServiceRequests cs
JOIN usr.users u ON u.UserID = cs.UserID
WHERE u.FirstName != cs.FirstName
   OR u.LastName != cs.LastName;

\echo '';
\echo 'Fix 2 Complete: Customer names synchronized';
\echo '';

-- ============================================================================
-- FIX 3: Invalid Shoe Sizes - Correct or remove invalid values
-- ============================================================================

\echo '3. Fixing invalid shoe sizes...';
\echo '';

-- Strategy: Size '0' is clearly invalid. Options:
--   A) Set to NULL (data steward review required)
--   B) Infer from im.Items if possible
--   C) Delete listing (extreme)
-- We'll use option A (set to NULL) and flag for steward review

-- Step 1: Identify invalid sizes
CREATE TEMP TABLE temp_invalid_sizes AS
SELECT
    ListingID,
    SellerID,
    ProductID,
    Size AS invalid_size,
    Brand,
    Color
FROM li.listings
WHERE Size::NUMERIC NOT BETWEEN 0.5 AND 22
   OR Size = '0';

\echo 'Invalid sizes identified:';
SELECT COUNT(*) AS invalid_count FROM temp_invalid_sizes;

-- Step 2: Attempt to infer correct size from Inventory Management
UPDATE li.listings
SET Size = i.Size
FROM im.Items i
WHERE listings.SellerID = i.SellerID
  AND listings.ListingID IN (SELECT ListingID FROM temp_invalid_sizes)
  AND i.Size::NUMERIC BETWEEN 0.5 AND 22
  AND i.Size != '0';

\echo '';
\echo 'Sizes corrected from Inventory Management where possible';

-- Step 3: Set remaining invalid sizes to NULL for steward review
UPDATE li.listings
SET Size = NULL
WHERE ListingID IN (SELECT ListingID FROM temp_invalid_sizes)
  AND (Size::NUMERIC NOT BETWEEN 0.5 AND 22 OR Size = '0');

\echo '';
\echo 'Remaining invalid sizes set to NULL (requires steward review)';

\echo '';
\echo 'Verification: Remaining invalid sizes should be 0';
SELECT COUNT(*) AS remaining_invalid
FROM li.listings
WHERE Size IS NOT NULL
  AND (Size::NUMERIC NOT BETWEEN 0.5 AND 22 OR Size = '0');

\echo '';
\echo 'Fix 3 Complete: Invalid sizes corrected or flagged';
\echo '';

-- ============================================================================
-- FIX 4: Missing Arrival Dates - Infer or flag for manual entry
-- ============================================================================

\echo '4. Fixing missing arrival dates...';
\echo '';

-- Strategy: ArrivalDate is critical for 45-day rule enforcement
-- Options:
--   A) Infer from earliest ListingCreateDate for same seller+item
--   B) Set to current date (risky - may trigger false 45-day violations)
--   C) Leave NULL and flag for warehouse team review
-- We'll use a hybrid approach

-- Step 1: Identify items with missing ArrivalDate
CREATE TEMP TABLE temp_missing_arrival AS
SELECT
    ItemID,
    SellerID,
    ItemName,
    Type,
    ItemStatus
FROM im.Items
WHERE ArrivalDate IS NULL;

\echo 'Items with missing ArrivalDate:';
SELECT COUNT(*) AS missing_count FROM temp_missing_arrival;

-- Step 2: For items with ItemStatus = 'received', set ArrivalDate to 30 days ago
-- (Conservative estimate to avoid premature 45-day violations)
UPDATE im.Items
SET ArrivalDate = CURRENT_DATE - INTERVAL '30 days'
WHERE ItemID IN (SELECT ItemID FROM temp_missing_arrival)
  AND ItemStatus = 'received'
  AND ArrivalDate IS NULL;

\echo '';
\echo 'ArrivalDate set to 30 days ago for items with status = received';

-- Step 3: For items with ItemStatus != 'received', leave NULL (not yet arrived)
\echo '';
\echo 'Items not yet received (ArrivalDate remains NULL):';
SELECT COUNT(*) AS not_received_count
FROM im.Items
WHERE ArrivalDate IS NULL
  AND ItemStatus != 'received';

\echo '';
\echo 'Verification: Items with NULL ArrivalDate and status = received';
SELECT COUNT(*) AS remaining_null
FROM im.Items
WHERE ArrivalDate IS NULL
  AND ItemStatus = 'received';

\echo '';
\echo 'Fix 4 Complete: Arrival dates updated or flagged';
\echo '';

-- ============================================================================
-- CREATE DATA QUALITY ISSUE TRACKING TABLE
-- ============================================================================

\echo '5. Creating data quality issue tracking table...';
\echo '';

CREATE SCHEMA IF NOT EXISTS dq;

CREATE TABLE IF NOT EXISTS dq.quality_issues (
    issue_id SERIAL PRIMARY KEY,
    issue_code VARCHAR(20) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100),
    record_id INT,
    issue_description TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('Critical', 'High', 'Medium', 'Low')),
    detected_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_date TIMESTAMP,
    assigned_steward VARCHAR(100),
    resolution_notes TEXT,
    status VARCHAR(20) DEFAULT 'Open' CHECK (status IN ('Open', 'In Progress', 'Resolved', 'Closed'))
);

\echo 'Data quality issue tracking table created: dq.quality_issues';

-- Insert any remaining issues for steward review
INSERT INTO dq.quality_issues (issue_code, table_name, column_name, record_id, issue_description, severity, assigned_steward)
SELECT
    'DQ-001',
    'li.listings',
    'ShoeType',
    ListingID,
    'ShoeType was NULL - backfilled with inferred or default value',
    'Medium',
    'Jessica'
FROM temp_listing_item_mapping
WHERE current_shoetype IS NULL;

INSERT INTO dq.quality_issues (issue_code, table_name, column_name, record_id, issue_description, severity, assigned_steward)
SELECT
    'DQ-002',
    'cs.CustomerServiceRequests',
    'FirstName, LastName',
    cs_request_id,
    'Name mismatch with User Service - synchronized to: ' || correct_firstname || ' ' || correct_lastname,
    'High',
    'Jessica'
FROM temp_name_mismatches;

INSERT INTO dq.quality_issues (issue_code, table_name, column_name, record_id, issue_description, severity, assigned_steward)
SELECT
    'DQ-003',
    'li.listings',
    'Size',
    ListingID,
    'Invalid size value: ' || invalid_size || ' - set to NULL for review',
    'Critical',
    'Warehouse Team'
FROM temp_invalid_sizes;

INSERT INTO dq.quality_issues (issue_code, table_name, column_name, record_id, issue_description, severity, assigned_steward)
SELECT
    'DQ-004',
    'im.Items',
    'ArrivalDate',
    ItemID,
    'Missing ArrivalDate - set to estimated 30 days ago',
    'High',
    'Warehouse Team'
FROM temp_missing_arrival
WHERE ItemID IN (
    SELECT ItemID FROM im.Items
    WHERE ArrivalDate = CURRENT_DATE - INTERVAL '30 days'
);

\echo '';
\echo 'Data quality issues logged for steward review';
SELECT issue_code, COUNT(*) AS issue_count, severity, assigned_steward
FROM dq.quality_issues
WHERE status = 'Open'
GROUP BY issue_code, severity, assigned_steward
ORDER BY issue_code;

\echo '';
\echo '';

-- ============================================================================
-- FINAL VERIFICATION
-- ============================================================================

\echo '========================================';
\echo 'REMEDIATION SUMMARY';
\echo '========================================';
\echo '';

SELECT
    'DQ-001' AS issue_code,
    'Missing ShoeType' AS issue,
    (SELECT COUNT(*) FROM li.listings WHERE ShoeType IS NULL) AS remaining_issues,
    CASE
        WHEN (SELECT COUNT(*) FROM li.listings WHERE ShoeType IS NULL) = 0
        THEN '✅ RESOLVED'
        ELSE '❌ ISSUES REMAIN'
    END AS status

UNION ALL

SELECT
    'DQ-002',
    'Name Mismatches',
    (SELECT COUNT(*)
     FROM cs.CustomerServiceRequests cs
     JOIN usr.users u ON u.UserID = cs.UserID
     WHERE u.FirstName != cs.FirstName OR u.LastName != cs.LastName),
    CASE
        WHEN (SELECT COUNT(*)
              FROM cs.CustomerServiceRequests cs
              JOIN usr.users u ON u.UserID = cs.UserID
              WHERE u.FirstName != cs.FirstName OR u.LastName != cs.LastName) = 0
        THEN '✅ RESOLVED'
        ELSE '❌ ISSUES REMAIN'
    END

UNION ALL

SELECT
    'DQ-003',
    'Invalid Sizes',
    (SELECT COUNT(*) FROM li.listings
     WHERE Size IS NOT NULL AND (Size::NUMERIC NOT BETWEEN 0.5 AND 22 OR Size = '0')),
    CASE
        WHEN (SELECT COUNT(*) FROM li.listings
              WHERE Size IS NOT NULL AND (Size::NUMERIC NOT BETWEEN 0.5 AND 22 OR Size = '0')) = 0
        THEN '✅ RESOLVED'
        ELSE '❌ ISSUES REMAIN'
    END

UNION ALL

SELECT
    'DQ-004',
    'Missing ArrivalDate',
    (SELECT COUNT(*) FROM im.Items WHERE ArrivalDate IS NULL AND ItemStatus = 'received'),
    CASE
        WHEN (SELECT COUNT(*) FROM im.Items WHERE ArrivalDate IS NULL AND ItemStatus = 'received') = 0
        THEN '✅ RESOLVED'
        ELSE '⚠️ REVIEW NEEDED'
    END;

\echo '';
\echo '========================================';
\echo 'Data Quality Remediation Complete';
\echo '';
\echo 'Next Steps:';
\echo '  1. Review dq.quality_issues table for steward assignments';
\echo '  2. Run 01_data_quality_checks.sql to verify improvements';
\echo '  3. Implement constraints (see 08_constraints_indexes.sql)';
\echo '========================================';
\echo '';

-- Commit changes (comment out for testing with ROLLBACK)
COMMIT;
-- ROLLBACK;  -- Uncomment this line for testing without committing changes
