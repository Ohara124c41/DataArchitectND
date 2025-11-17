-- ============================================================================
-- File: 03_mdm_golden_customer.sql
-- Purpose: Create Golden Customer MDM Hub (Centralized Component)
-- Project: SneakerPark Data Governance - Phase 1
-- Author: Data Architecture Team
-- Date: 2025-11-17
-- ============================================================================

-- This script implements the Centralized MDM component for Customer master data
-- Part of the Hybrid MDM Architecture (Centralized for Customers, Registry for Items)

\echo '========================================';
\echo 'Creating MDM Golden Customer Hub';
\echo 'Centralized Component - Hybrid Architecture';
\echo '========================================';
\echo '';

-- Create MDM schema
CREATE SCHEMA IF NOT EXISTS mdm;

-- ============================================================================
-- GOLDEN CUSTOMER TABLE
-- ============================================================================

\echo '1. Creating Golden Customer master table...';
\echo '';

CREATE TABLE IF NOT EXISTS mdm.golden_customer (
    -- Golden Master ID
    golden_customer_id SERIAL PRIMARY KEY,

    -- Master Data Attributes (Cleaned, Verified)
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(254) NOT NULL UNIQUE,  -- Increased from 50 to 254 (RFC 5321 standard)
    address VARCHAR(200),  -- Increased from 50 to 200 for full addresses
    zip_code VARCHAR(10),

    -- Data Quality Metrics
    data_quality_score NUMERIC(5,2) DEFAULT 0.00 CHECK (data_quality_score BETWEEN 0 AND 100),
    completeness_score NUMERIC(5,2),
    consistency_score NUMERIC(5,2),
    validity_score NUMERIC(5,2),

    -- MDM Metadata
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by VARCHAR(100) DEFAULT 'MDM_SYSTEM',
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,

    -- Merge Tracking
    master_record_flag BOOLEAN DEFAULT TRUE,
    merged_into_id INT REFERENCES mdm.golden_customer(golden_customer_id),
    merge_date TIMESTAMP,
    merge_reason TEXT,

    -- Source System Tracking
    source_system VARCHAR(50) DEFAULT 'usr',  -- usr, cs, op
    source_record_count INT DEFAULT 1,

    -- Stewardship
    data_steward VARCHAR(100) DEFAULT 'Jessica',
    last_review_date TIMESTAMP,
    review_notes TEXT
);

\echo 'Golden Customer table created: mdm.golden_customer';
\echo '';

-- ============================================================================
-- CUSTOMER CROSS-REFERENCE TABLE
-- ============================================================================

\echo '2. Creating Customer Cross-Reference table...';
\echo '';

CREATE TABLE IF NOT EXISTS mdm.customer_xref (
    xref_id SERIAL PRIMARY KEY,
    golden_customer_id INT NOT NULL REFERENCES mdm.golden_customer(golden_customer_id),

    -- Source System Reference
    source_system VARCHAR(50) NOT NULL CHECK (source_system IN ('usr', 'cs', 'op')),
    source_table VARCHAR(100) NOT NULL,
    source_id INT NOT NULL,

    -- Cross-Reference Metadata
    link_type VARCHAR(50) DEFAULT 'definite' CHECK (link_type IN ('definite', 'probable', 'possible')),
    confidence_score NUMERIC(5,2) DEFAULT 100.00 CHECK (confidence_score BETWEEN 0 AND 100),
    match_rule VARCHAR(100),  -- References matching rule used

    -- Lifecycle
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    deactivated_date TIMESTAMP,
    deactivation_reason TEXT,

    -- Prevent duplicate links
    UNIQUE (source_system, source_table, source_id)
);

\echo 'Customer Cross-Reference table created: mdm.customer_xref';
\echo '';

-- ============================================================================
-- CUSTOMER MERGE HISTORY TABLE
-- ============================================================================

\echo '3. Creating Customer Merge History table...';
\echo '';

CREATE TABLE IF NOT EXISTS mdm.customer_merge_history (
    merge_id SERIAL PRIMARY KEY,
    surviving_customer_id INT NOT NULL REFERENCES mdm.golden_customer(golden_customer_id),
    merged_customer_id INT NOT NULL,  -- May no longer exist after merge

    -- Merge Details
    merge_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    merge_reason TEXT NOT NULL,
    merged_by VARCHAR(100) NOT NULL,
    match_confidence NUMERIC(5,2),
    match_rule VARCHAR(100),

    -- Audit Trail
    surviving_customer_before JSONB,  -- Snapshot before merge
    merged_customer_data JSONB,  -- Data from merged record
    surviving_customer_after JSONB,  -- Snapshot after merge

    -- Rollback Support
    can_rollback BOOLEAN DEFAULT TRUE,
    rollback_date TIMESTAMP,
    rollback_reason TEXT
);

\echo 'Customer Merge History table created: mdm.customer_merge_history';
\echo '';

-- ============================================================================
-- CUSTOMER DATA QUALITY HISTORY TABLE
-- ============================================================================

\echo '4. Creating Customer Data Quality History table...';
\echo '';

CREATE TABLE IF NOT EXISTS mdm.customer_quality_history (
    quality_id SERIAL PRIMARY KEY,
    golden_customer_id INT NOT NULL REFERENCES mdm.golden_customer(golden_customer_id),

    -- Quality Scores
    assessment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    overall_quality_score NUMERIC(5,2),
    completeness_score NUMERIC(5,2),
    consistency_score NUMERIC(5,2),
    validity_score NUMERIC(5,2),
    uniqueness_score NUMERIC(5,2),
    timeliness_score NUMERIC(5,2),

    -- Issues Detected
    issues_detected TEXT[],
    issue_count INT,
    critical_issues INT,

    -- Assessment Details
    assessed_by VARCHAR(100),
    assessment_notes TEXT
);

\echo 'Customer Data Quality History table created: mdm.customer_quality_history';
\echo '';

-- ============================================================================
-- LOAD INITIAL GOLDEN CUSTOMER DATA FROM USER SERVICE
-- ============================================================================

\echo '5. Loading initial Golden Customer data from User Service...';
\echo '';

-- User Service is the source of truth for customer data
INSERT INTO mdm.golden_customer (
    first_name,
    last_name,
    email,
    address,
    zip_code,
    data_quality_score,
    is_verified,
    source_system
)
SELECT
    FirstName,
    LastName,
    Email,
    Address,
    ZipCode,
    -- Initial quality score calculation
    (CASE WHEN FirstName IS NOT NULL THEN 20 ELSE 0 END +
     CASE WHEN LastName IS NOT NULL THEN 20 ELSE 0 END +
     CASE WHEN Email IS NOT NULL THEN 20 ELSE 0 END +
     CASE WHEN Address IS NOT NULL THEN 20 ELSE 0 END +
     CASE WHEN ZipCode IS NOT NULL THEN 20 ELSE 0 END) AS data_quality_score,
    TRUE,  -- User Service records are verified
    'usr'
FROM usr.users
ON CONFLICT (email) DO NOTHING;  -- Prevent duplicates on reload

\echo 'Golden Customer records loaded from User Service';
SELECT COUNT(*) AS golden_customer_count FROM mdm.golden_customer;

\echo '';

-- ============================================================================
-- CREATE CROSS-REFERENCES TO SOURCE SYSTEMS
-- ============================================================================

\echo '6. Creating cross-references to source systems...';
\echo '';

-- Link to User Service
INSERT INTO mdm.customer_xref (golden_customer_id, source_system, source_table, source_id, link_type, confidence_score, match_rule)
SELECT
    gc.golden_customer_id,
    'usr',
    'users',
    u.UserID,
    'definite',
    100.00,
    'Email exact match'
FROM mdm.golden_customer gc
JOIN usr.users u ON gc.email = u.Email
WHERE gc.source_system = 'usr'
ON CONFLICT (source_system, source_table, source_id) DO NOTHING;

\echo 'User Service cross-references created';
SELECT COUNT(*) AS usr_xrefs FROM mdm.customer_xref WHERE source_system = 'usr';

-- Link to Customer Service (using UserID from cs.CustomerServiceRequests)
INSERT INTO mdm.customer_xref (golden_customer_id, source_system, source_table, source_id, link_type, confidence_score, match_rule)
SELECT DISTINCT
    xref.golden_customer_id,
    'cs',
    'CustomerServiceRequests',
    cs.ID,
    'definite',
    100.00,
    'UserID match via usr.users'
FROM cs.CustomerServiceRequests cs
JOIN usr.users u ON u.UserID = cs.UserID
JOIN mdm.customer_xref xref ON xref.source_id = u.UserID AND xref.source_system = 'usr'
ON CONFLICT (source_system, source_table, source_id) DO NOTHING;

\echo '';
\echo 'Customer Service cross-references created';
SELECT COUNT(*) AS cs_xrefs FROM mdm.customer_xref WHERE source_system = 'cs';

-- Link to Order Processing (using BuyerID from op.Orders)
INSERT INTO mdm.customer_xref (golden_customer_id, source_system, source_table, source_id, link_type, confidence_score, match_rule)
SELECT DISTINCT
    xref.golden_customer_id,
    'op',
    'Orders',
    o.OrderID,
    'definite',
    100.00,
    'BuyerID match via usr.users'
FROM op.Orders o
JOIN usr.users u ON u.UserID = o.BuyerID
JOIN mdm.customer_xref xref ON xref.source_id = u.UserID AND xref.source_system = 'usr'
ON CONFLICT (source_system, source_table, source_id) DO NOTHING;

\echo '';
\echo 'Order Processing cross-references created';
SELECT COUNT(*) AS op_xrefs FROM mdm.customer_xref WHERE source_system = 'op';

\echo '';
\echo '';

-- ============================================================================
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

\echo '7. Creating indexes for performance...';
\echo '';

CREATE INDEX IF NOT EXISTS idx_golden_customer_email ON mdm.golden_customer(email);
CREATE INDEX IF NOT EXISTS idx_golden_customer_lastname ON mdm.golden_customer(last_name);
CREATE INDEX IF NOT EXISTS idx_golden_customer_quality ON mdm.golden_customer(data_quality_score);
CREATE INDEX IF NOT EXISTS idx_golden_customer_active ON mdm.golden_customer(is_active) WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_customer_xref_golden_id ON mdm.customer_xref(golden_customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_xref_source ON mdm.customer_xref(source_system, source_id);
CREATE INDEX IF NOT EXISTS idx_customer_xref_active ON mdm.customer_xref(is_active) WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_merge_history_surviving ON mdm.customer_merge_history(surviving_customer_id);
CREATE INDEX IF NOT EXISTS idx_merge_history_merged ON mdm.customer_merge_history(merged_customer_id);

\echo 'Indexes created for MDM tables';
\echo '';

-- ============================================================================
-- CREATE VIEWS FOR EASY ACCESS
-- ============================================================================

\echo '8. Creating convenience views...';
\echo '';

-- View: Customer 360 (all data from all systems)
CREATE OR REPLACE VIEW mdm.v_customer_360 AS
SELECT
    gc.golden_customer_id,
    gc.first_name,
    gc.last_name,
    gc.email,
    gc.address,
    gc.zip_code,
    gc.data_quality_score,
    gc.is_verified,

    -- Count of related records across systems
    COUNT(DISTINCT xref_usr.source_id) AS usr_record_count,
    COUNT(DISTINCT xref_cs.source_id) AS cs_record_count,
    COUNT(DISTINCT xref_op.source_id) AS op_order_count,

    -- Quality indicators
    gc.created_date,
    gc.last_modified_date,
    gc.data_steward
FROM mdm.golden_customer gc
LEFT JOIN mdm.customer_xref xref_usr
    ON gc.golden_customer_id = xref_usr.golden_customer_id
    AND xref_usr.source_system = 'usr'
LEFT JOIN mdm.customer_xref xref_cs
    ON gc.golden_customer_id = xref_cs.golden_customer_id
    AND xref_cs.source_system = 'cs'
LEFT JOIN mdm.customer_xref xref_op
    ON gc.golden_customer_id = xref_op.golden_customer_id
    AND xref_op.source_system = 'op'
WHERE gc.is_active = TRUE
  AND gc.master_record_flag = TRUE
GROUP BY
    gc.golden_customer_id,
    gc.first_name,
    gc.last_name,
    gc.email,
    gc.address,
    gc.zip_code,
    gc.data_quality_score,
    gc.is_verified,
    gc.created_date,
    gc.last_modified_date,
    gc.data_steward;

\echo 'View created: mdm.v_customer_360';

-- View: Low Quality Customers (requiring steward attention)
CREATE OR REPLACE VIEW mdm.v_low_quality_customers AS
SELECT
    golden_customer_id,
    first_name,
    last_name,
    email,
    data_quality_score,
    CASE
        WHEN first_name IS NULL THEN 'Missing FirstName'
        WHEN last_name IS NULL THEN 'Missing LastName'
        WHEN address IS NULL THEN 'Missing Address'
        WHEN zip_code IS NULL THEN 'Missing ZipCode'
        WHEN data_quality_score < 80 THEN 'Overall low quality'
    END AS issue,
    last_review_date,
    data_steward
FROM mdm.golden_customer
WHERE data_quality_score < 80
   OR first_name IS NULL
   OR last_name IS NULL
   OR address IS NULL
ORDER BY data_quality_score ASC;

\echo 'View created: mdm.v_low_quality_customers';
\echo '';

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================

\echo '========================================';
\echo 'MDM GOLDEN CUSTOMER HUB - SUMMARY';
\echo '========================================';
\echo '';

SELECT 'Golden Customer Records' AS metric, COUNT(*)::TEXT AS value
FROM mdm.golden_customer
WHERE is_active = TRUE

UNION ALL

SELECT 'Average Data Quality Score', ROUND(AVG(data_quality_score), 1)::TEXT || '%'
FROM mdm.golden_customer
WHERE is_active = TRUE

UNION ALL

SELECT 'Verified Customers', COUNT(*)::TEXT
FROM mdm.golden_customer
WHERE is_verified = TRUE

UNION ALL

SELECT 'Cross-References (Total)', COUNT(*)::TEXT
FROM mdm.customer_xref
WHERE is_active = TRUE

UNION ALL

SELECT '  └─ User Service', COUNT(*)::TEXT
FROM mdm.customer_xref
WHERE source_system = 'usr' AND is_active = TRUE

UNION ALL

SELECT '  └─ Customer Service', COUNT(*)::TEXT
FROM mdm.customer_xref
WHERE source_system = 'cs' AND is_active = TRUE

UNION ALL

SELECT '  └─ Order Processing', COUNT(*)::TEXT
FROM mdm.customer_xref
WHERE source_system = 'op' AND is_active = TRUE

UNION ALL

SELECT 'Low Quality Records (< 80%)', COUNT(*)::TEXT
FROM mdm.golden_customer
WHERE data_quality_score < 80;

\echo '';
\echo '========================================';
\echo 'Golden Customer Hub Creation Complete';
\echo '';
\echo 'Next Steps:';
\echo '  1. Run customer matching rules (05_customer_matching.sql)';
\echo '  2. Review low quality customers: SELECT * FROM mdm.v_low_quality_customers;';
\echo '  3. Implement real-time CDC integration';
\echo '========================================';
