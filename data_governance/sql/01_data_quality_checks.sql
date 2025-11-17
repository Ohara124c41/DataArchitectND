-- ============================================================================
-- File: 01_data_quality_checks.sql
-- Purpose: Validate data quality rules and identify issues
-- Project: SneakerPark Data Governance - Phase 1
-- Author: Data Architecture Team
-- Date: 2025-11-17
-- ============================================================================

-- This script checks all 5 data quality issues identified in the profiling phase
-- Run this script to assess current data quality state before applying fixes

\echo '========================================';
\echo 'SneakerPark Data Quality Checks';
\echo 'Running 5 validation rules...';
\echo '========================================';
\echo '';

-- ============================================================================
-- DQ CHECK 1: Missing ShoeType (Completeness Issue)
-- ============================================================================

\echo '1. Checking for missing ShoeType values...';
\echo '';

SELECT
    'DQ-001: Missing ShoeType' AS issue_code,
    'Completeness' AS dimension,
    COUNT(*) AS total_listings,
    COUNT(*) FILTER (WHERE ShoeType IS NULL) AS null_shoetype_count,
    ROUND(
        (COUNT(*) FILTER (WHERE ShoeType IS NULL)::NUMERIC / COUNT(*)) * 100,
        2
    ) AS null_percentage,
    CASE
        WHEN COUNT(*) FILTER (WHERE ShoeType IS NULL)::NUMERIC / COUNT(*) > 0.02
        THEN 'CRITICAL - Exceeds 2% threshold'
        ELSE 'ACCEPTABLE'
    END AS status
FROM li.listings;

\echo '';
\echo 'Sample records with NULL ShoeType:';
SELECT
    ListingID,
    SellerID,
    ProductID,
    Brand,
    Color,
    Size,
    Condition,
    ListingPrice
FROM li.listings
WHERE ShoeType IS NULL
LIMIT 10;

\echo '';
\echo '';

-- ============================================================================
-- DQ CHECK 2: Customer Name Mismatches (Consistency Issue)
-- ============================================================================

\echo '2. Checking for customer name mismatches between systems...';
\echo '';

SELECT
    'DQ-002: Name Mismatches' AS issue_code,
    'Consistency' AS dimension,
    COUNT(*) AS total_cs_requests,
    COUNT(*) FILTER (
        WHERE NOT EXISTS (
            SELECT 1 FROM usr.users u
            WHERE u.UserID = cs.UserID
            AND u.FirstName = cs.FirstName
            AND u.LastName = cs.LastName
        )
    ) AS mismatch_count,
    ROUND(
        (COUNT(*) FILTER (
            WHERE NOT EXISTS (
                SELECT 1 FROM usr.users u
                WHERE u.UserID = cs.UserID
                AND u.FirstName = cs.FirstName
                AND u.LastName = cs.LastName
            )
        )::NUMERIC / COUNT(*)) * 100,
        2
    ) AS mismatch_percentage,
    CASE
        WHEN COUNT(*) FILTER (
            WHERE NOT EXISTS (
                SELECT 1 FROM usr.users u
                WHERE u.UserID = cs.UserID
                AND u.FirstName = cs.FirstName
                AND u.LastName = cs.LastName
            )
        )::NUMERIC / COUNT(*) > 0.005
        THEN 'CRITICAL - Exceeds 0.5% threshold'
        ELSE 'ACCEPTABLE'
    END AS status
FROM cs.CustomerServiceRequests cs;

\echo '';
\echo 'Sample mismatched names:';
SELECT
    cs.UserID,
    u.FirstName AS user_service_firstname,
    cs.FirstName AS cs_firstname,
    u.LastName AS user_service_lastname,
    cs.LastName AS cs_lastname,
    CASE
        WHEN u.FirstName != cs.FirstName THEN 'FirstName mismatch'
        WHEN u.LastName != cs.LastName THEN 'LastName mismatch'
        ELSE 'Both mismatch'
    END AS mismatch_type
FROM cs.CustomerServiceRequests cs
JOIN usr.users u ON u.UserID = cs.UserID
WHERE u.FirstName != cs.FirstName
   OR u.LastName != cs.LastName
LIMIT 10;

\echo '';
\echo '';

-- ============================================================================
-- DQ CHECK 3: Invalid Shoe Sizes (Validity Issue)
-- ============================================================================

\echo '3. Checking for invalid shoe sizes...';
\echo '';

SELECT
    'DQ-003: Invalid Sizes' AS issue_code,
    'Validity' AS dimension,
    COUNT(*) AS total_listings,
    COUNT(*) FILTER (
        WHERE Size::NUMERIC NOT BETWEEN 0.5 AND 22 OR Size = '0'
    ) AS invalid_size_count,
    ROUND(
        (COUNT(*) FILTER (
            WHERE Size::NUMERIC NOT BETWEEN 0.5 AND 22 OR Size = '0'
        )::NUMERIC / COUNT(*)) * 100,
        2
    ) AS invalid_percentage,
    CASE
        WHEN COUNT(*) FILTER (
            WHERE Size::NUMERIC NOT BETWEEN 0.5 AND 22 OR Size = '0'
        ) > 0
        THEN 'CRITICAL - Must be 0%'
        ELSE 'ACCEPTABLE'
    END AS status
FROM li.listings
WHERE Size IS NOT NULL;

\echo '';
\echo 'Sample records with invalid sizes:';
SELECT
    ListingID,
    SellerID,
    Brand,
    Size,
    CASE
        WHEN Size = '0' THEN 'Size is zero (impossible)'
        WHEN Size::NUMERIC < 0.5 THEN 'Size below minimum (0.5)'
        WHEN Size::NUMERIC > 22 THEN 'Size above maximum (22)'
    END AS issue_detail
FROM li.listings
WHERE Size::NUMERIC NOT BETWEEN 0.5 AND 22 OR Size = '0'
LIMIT 10;

\echo '';
\echo '';

-- ============================================================================
-- DQ CHECK 4: Missing Arrival Dates (Timeliness Issue)
-- ============================================================================

\echo '4. Checking for missing arrival dates in warehouse items...';
\echo '';

SELECT
    'DQ-004: Missing ArrivalDate' AS issue_code,
    'Timeliness' AS dimension,
    COUNT(*) AS total_items,
    COUNT(*) FILTER (WHERE ArrivalDate IS NULL) AS null_arrivaldate_count,
    ROUND(
        (COUNT(*) FILTER (WHERE ArrivalDate IS NULL)::NUMERIC / COUNT(*)) * 100,
        2
    ) AS null_percentage,
    CASE
        WHEN COUNT(*) FILTER (WHERE ArrivalDate IS NULL)::NUMERIC / COUNT(*) > 0.01
        THEN 'CRITICAL - Exceeds 1% threshold'
        ELSE 'ACCEPTABLE'
    END AS status
FROM im.Items;

\echo '';
\echo 'Sample items with missing arrival dates:';
SELECT
    ItemID,
    ItemName,
    SellerID,
    Type AS ShoeType,
    BrandName,
    ItemStatus,
    ArrivalDate
FROM im.Items
WHERE ArrivalDate IS NULL
LIMIT 10;

\echo '';
\echo 'Items at risk of exceeding 45-day rule (ArrivalDate older than 40 days):';
SELECT
    ItemID,
    ItemName,
    SellerID,
    ArrivalDate,
    CURRENT_DATE - ArrivalDate AS days_in_warehouse,
    45 - (CURRENT_DATE - ArrivalDate) AS days_remaining,
    CASE
        WHEN CURRENT_DATE - ArrivalDate >= 45 THEN 'OVERDUE - Must return to seller'
        WHEN CURRENT_DATE - ArrivalDate >= 40 THEN 'URGENT - Less than 5 days'
        ELSE 'WARNING - Monitor closely'
    END AS urgency
FROM im.Items
WHERE ArrivalDate IS NOT NULL
  AND CURRENT_DATE - ArrivalDate >= 40
ORDER BY ArrivalDate ASC
LIMIT 20;

\echo '';
\echo '';

-- ============================================================================
-- DQ CHECK 5: Potential Duplicate User Accounts (Uniqueness Issue)
-- ============================================================================

\echo '5. Checking for potential duplicate user accounts...';
\echo '';

-- Check 5a: Same email domain + similar name
\echo 'Checking for users with same email domain and similar names:';
WITH email_patterns AS (
    SELECT
        UserID,
        FirstName,
        LastName,
        Email,
        Address,
        SUBSTRING(Email FROM POSITION('@' IN Email)) AS email_domain,
        SUBSTRING(LOWER(LastName) FROM 1 FOR 3) AS lastname_prefix,
        LOWER(SUBSTRING(FirstName FROM 1 FOR 1)) AS firstname_initial
    FROM usr.users
)
SELECT
    'DQ-005a: Duplicate Accounts (Email Pattern)' AS issue_code,
    'Uniqueness' AS dimension,
    COUNT(*) AS potential_duplicate_pairs
FROM email_patterns e1
JOIN email_patterns e2
    ON e1.email_domain = e2.email_domain
    AND e1.lastname_prefix = e2.lastname_prefix
    AND e1.firstname_initial = e2.firstname_initial
    AND e1.UserID < e2.UserID;

\echo '';
\echo 'Sample potential duplicates (same email domain + similar name):';
WITH email_patterns AS (
    SELECT
        UserID,
        FirstName,
        LastName,
        Email,
        Address,
        SUBSTRING(Email FROM POSITION('@' IN Email)) AS email_domain,
        SUBSTRING(LOWER(LastName) FROM 1 FOR 3) AS lastname_prefix,
        LOWER(SUBSTRING(FirstName FROM 1 FOR 1)) AS firstname_initial
    FROM usr.users
)
SELECT
    e1.UserID AS user1_id,
    e1.FirstName AS user1_firstname,
    e1.LastName AS user1_lastname,
    e1.Email AS user1_email,
    e2.UserID AS user2_id,
    e2.FirstName AS user2_firstname,
    e2.LastName AS user2_lastname,
    e2.Email AS user2_email,
    e1.email_domain AS shared_domain
FROM email_patterns e1
JOIN email_patterns e2
    ON e1.email_domain = e2.email_domain
    AND e1.lastname_prefix = e2.lastname_prefix
    AND e1.firstname_initial = e2.firstname_initial
    AND e1.UserID < e2.UserID
LIMIT 10;

\echo '';

-- Check 5b: Same address + similar name
\echo 'Checking for users with same address and similar names:';
WITH address_patterns AS (
    SELECT
        UserID,
        FirstName,
        LastName,
        Email,
        Address,
        ZipCode,
        SUBSTRING(LOWER(LastName) FROM 1 FOR 3) AS lastname_prefix,
        LOWER(SUBSTRING(FirstName FROM 1 FOR 1)) AS firstname_initial
    FROM usr.users
)
SELECT
    'DQ-005b: Duplicate Accounts (Address Pattern)' AS issue_code,
    'Uniqueness' AS dimension,
    COUNT(*) AS potential_duplicate_pairs
FROM address_patterns a1
JOIN address_patterns a2
    ON a1.Address = a2.Address
    AND a1.ZipCode = a2.ZipCode
    AND a1.lastname_prefix = a2.lastname_prefix
    AND a1.UserID < a2.UserID;

\echo '';
\echo 'Sample potential duplicates (same address + similar name):';
WITH address_patterns AS (
    SELECT
        UserID,
        FirstName,
        LastName,
        Email,
        Address,
        ZipCode,
        SUBSTRING(LOWER(LastName) FROM 1 FOR 3) AS lastname_prefix,
        LOWER(SUBSTRING(FirstName FROM 1 FOR 1)) AS firstname_initial
    FROM usr.users
)
SELECT
    a1.UserID AS user1_id,
    a1.FirstName || ' ' || a1.LastName AS user1_name,
    a1.Email AS user1_email,
    a2.UserID AS user2_id,
    a2.FirstName || ' ' || a2.LastName AS user2_name,
    a2.Email AS user2_email,
    a1.Address || ', ' || a1.ZipCode AS shared_address
FROM address_patterns a1
JOIN address_patterns a2
    ON a1.Address = a2.Address
    AND a1.ZipCode = a2.ZipCode
    AND a1.lastname_prefix = a2.lastname_prefix
    AND a1.UserID < a2.UserID
LIMIT 10;

\echo '';
\echo '';

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================

\echo '========================================';
\echo 'DATA QUALITY SUMMARY';
\echo '========================================';
\echo '';

SELECT
    'DQ-001' AS issue_code,
    'Missing ShoeType' AS issue,
    ROUND(
        (COUNT(*) FILTER (WHERE ShoeType IS NULL)::NUMERIC / COUNT(*)) * 100,
        1
    ) || '%' AS current_rate,
    '< 2%' AS target_rate,
    CASE
        WHEN COUNT(*) FILTER (WHERE ShoeType IS NULL)::NUMERIC / COUNT(*) > 0.02
        THEN '❌ CRITICAL'
        ELSE '✅ PASS'
    END AS status
FROM li.listings

UNION ALL

SELECT
    'DQ-002',
    'Name Mismatches',
    ROUND(
        (COUNT(*) FILTER (
            WHERE NOT EXISTS (
                SELECT 1 FROM usr.users u
                WHERE u.UserID = cs.UserID
                AND u.FirstName = cs.FirstName
                AND u.LastName = cs.LastName
            )
        )::NUMERIC / COUNT(*)) * 100,
        1
    ) || '%',
    '< 0.5%',
    CASE
        WHEN COUNT(*) FILTER (
            WHERE NOT EXISTS (
                SELECT 1 FROM usr.users u
                WHERE u.UserID = cs.UserID
                AND u.FirstName = cs.FirstName
                AND u.LastName = cs.LastName
            )
        )::NUMERIC / COUNT(*) > 0.005
        THEN '❌ CRITICAL'
        ELSE '✅ PASS'
    END
FROM cs.CustomerServiceRequests cs

UNION ALL

SELECT
    'DQ-003',
    'Invalid Sizes',
    COUNT(*) FILTER (
        WHERE Size::NUMERIC NOT BETWEEN 0.5 AND 22 OR Size = '0'
    )::TEXT || ' records',
    '0 records',
    CASE
        WHEN COUNT(*) FILTER (
            WHERE Size::NUMERIC NOT BETWEEN 0.5 AND 22 OR Size = '0'
        ) > 0
        THEN '❌ CRITICAL'
        ELSE '✅ PASS'
    END
FROM li.listings
WHERE Size IS NOT NULL

UNION ALL

SELECT
    'DQ-004',
    'Missing ArrivalDate',
    ROUND(
        (COUNT(*) FILTER (WHERE ArrivalDate IS NULL)::NUMERIC / COUNT(*)) * 100,
        1
    ) || '%',
    '< 1%',
    CASE
        WHEN COUNT(*) FILTER (WHERE ArrivalDate IS NULL)::NUMERIC / COUNT(*) > 0.01
        THEN '❌ CRITICAL'
        ELSE '✅ PASS'
    END
FROM im.Items

UNION ALL

SELECT
    'DQ-005',
    'Duplicate Accounts',
    'Risk present',
    '0 new duplicates',
    '⚠️ MONITOR'
;

\echo '';
\echo '========================================';
\echo 'Data Quality Check Complete';
\echo 'Review findings and run 02_data_quality_fixes.sql to remediate issues';
\echo '========================================';
