-- ============================================================================
-- File: 05_customer_matching.sql
-- Purpose: Implement Customer Matching Rules for Deduplication
-- Project: SneakerPark Data Governance - Phase 1
-- Author: Data Architecture Team
-- Date: 2025-11-17
-- ============================================================================

-- This script implements the 2 customer matching rules defined in Part 6:
--   1. Email + Name Match (High Confidence: 95%+)
--   2. Address + Phone Match (Medium Confidence: 85-95%)

\echo '========================================';
\echo 'Customer Matching Rules - Deduplication';
\echo 'MDM Golden Customer Component';
\echo '========================================';
\echo '';

-- ============================================================================
-- SETUP: Create Matching Results Table
-- ============================================================================

\echo '1. Creating customer match results table...';
\echo '';

CREATE TABLE IF NOT EXISTS mdm.customer_match_candidates (
    match_id SERIAL PRIMARY KEY,

    -- Golden Customer IDs being compared
    customer_id_1 INT NOT NULL REFERENCES mdm.golden_customer(golden_customer_id),
    customer_id_2 INT NOT NULL REFERENCES mdm.golden_customer(golden_customer_id),

    -- Match Details
    match_rule VARCHAR(100) NOT NULL,
    confidence_score NUMERIC(5,2) NOT NULL CHECK (confidence_score BETWEEN 0 AND 100),
    match_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Matching Attributes
    email_match BOOLEAN DEFAULT FALSE,
    firstname_match BOOLEAN DEFAULT FALSE,
    lastname_match BOOLEAN DEFAULT FALSE,
    address_match BOOLEAN DEFAULT FALSE,
    phone_match BOOLEAN DEFAULT FALSE,

    -- Similarity Scores (for probabilistic matching)
    name_similarity_score NUMERIC(5,2),
    address_similarity_score NUMERIC(5,2),

    -- Recommendation
    recommended_action VARCHAR(50) CHECK (recommended_action IN ('Auto-Merge', 'Steward Review', 'No Action')),
    steward_assigned VARCHAR(100) DEFAULT 'Jessica',

    -- Steward Review
    reviewed BOOLEAN DEFAULT FALSE,
    review_date TIMESTAMP,
    reviewed_by VARCHAR(100),
    merge_approved BOOLEAN,
    review_notes TEXT,

    -- Prevent duplicate comparisons
    UNIQUE (customer_id_1, customer_id_2),
    CHECK (customer_id_1 < customer_id_2)  -- Always store lower ID first
);

\echo 'Customer match candidates table created: mdm.customer_match_candidates';
\echo '';

-- ============================================================================
-- HELPER FUNCTION: Levenshtein Distance for Fuzzy Matching
-- ============================================================================

\echo '2. Creating Levenshtein distance function...';
\echo '';

-- PostgreSQL has built-in fuzzystrmatch extension for Levenshtein distance
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

\echo 'Fuzzy string matching extension enabled';
\echo '';

-- ============================================================================
-- MATCHING RULE 1: Email + Name Match (High Confidence: 95%+)
-- ============================================================================

\echo '3. Running Matching Rule 1: Email + Name Match...';
\echo '';

-- Rule 1: Exact email match AND (exact name match OR Levenshtein distance ≤ 2 on LastName)

INSERT INTO mdm.customer_match_candidates (
    customer_id_1,
    customer_id_2,
    match_rule,
    confidence_score,
    email_match,
    firstname_match,
    lastname_match,
    name_similarity_score,
    recommended_action
)
SELECT
    LEAST(gc1.golden_customer_id, gc2.golden_customer_id) AS customer_id_1,
    GREATEST(gc1.golden_customer_id, gc2.golden_customer_id) AS customer_id_2,
    'Rule 1: Email + Name Match' AS match_rule,
    CASE
        -- Exact email + exact name = 100%
        WHEN gc1.email = gc2.email
         AND gc1.first_name = gc2.first_name
         AND gc1.last_name = gc2.last_name
        THEN 100.00

        -- Exact email + similar name (Levenshtein distance ≤ 2) = 95-98%
        WHEN gc1.email = gc2.email
         AND gc1.first_name = gc2.first_name
         AND levenshtein(gc1.last_name, gc2.last_name) <= 2
        THEN 95.00 + ((2 - levenshtein(gc1.last_name, gc2.last_name)) * 1.5)

        -- Exact email + different FirstName but similar LastName = 90-95%
        WHEN gc1.email = gc2.email
         AND levenshtein(gc1.last_name, gc2.last_name) <= 2
        THEN 90.00 + ((2 - levenshtein(gc1.last_name, gc2.last_name)) * 2.5)

        ELSE 85.00
    END AS confidence_score,
    TRUE AS email_match,
    gc1.first_name = gc2.first_name AS firstname_match,
    gc1.last_name = gc2.last_name OR levenshtein(gc1.last_name, gc2.last_name) <= 2 AS lastname_match,
    CASE
        WHEN gc1.last_name = gc2.last_name THEN 100.00
        ELSE 100 - (levenshtein(gc1.last_name, gc2.last_name) * 10)
    END AS name_similarity_score,
    CASE
        WHEN (gc1.email = gc2.email
              AND gc1.first_name = gc2.first_name
              AND (gc1.last_name = gc2.last_name OR levenshtein(gc1.last_name, gc2.last_name) <= 1))
        THEN 'Auto-Merge'
        WHEN gc1.email = gc2.email
         AND levenshtein(gc1.last_name, gc2.last_name) <= 2
        THEN 'Steward Review'
        ELSE 'No Action'
    END AS recommended_action
FROM mdm.golden_customer gc1
JOIN mdm.golden_customer gc2
    ON gc1.email = gc2.email  -- Must have same email
    AND gc1.golden_customer_id != gc2.golden_customer_id  -- Different records
    AND gc1.is_active = TRUE
    AND gc2.is_active = TRUE
    AND gc1.master_record_flag = TRUE
    AND gc2.master_record_flag = TRUE
WHERE (
    -- Exact name match
    (gc1.first_name = gc2.first_name AND gc1.last_name = gc2.last_name)
    OR
    -- Or similar LastName (Levenshtein distance ≤ 2)
    (levenshtein(gc1.last_name, gc2.last_name) <= 2)
)
ON CONFLICT (customer_id_1, customer_id_2) DO NOTHING;

\echo 'Email + Name Match complete';
SELECT
    COUNT(*) AS total_matches,
    COUNT(*) FILTER (WHERE recommended_action = 'Auto-Merge') AS auto_merge,
    COUNT(*) FILTER (WHERE recommended_action = 'Steward Review') AS steward_review
FROM mdm.customer_match_candidates
WHERE match_rule = 'Rule 1: Email + Name Match';

\echo '';

-- ============================================================================
-- MATCHING RULE 2: Address + Phone Match (Medium Confidence: 85-95%)
-- ============================================================================

\echo '4. Running Matching Rule 2: Address + Phone Match...';
\echo '';

-- Rule 2: Standardized address match (same street, zip) AND similar name (first 3 letters of LastName + FirstName initial)

-- Note: Phone is not in usr.users table, only in cs.CustomerServiceRequests
-- We'll use address matching + name similarity as proxy

INSERT INTO mdm.customer_match_candidates (
    customer_id_1,
    customer_id_2,
    match_rule,
    confidence_score,
    address_match,
    lastname_match,
    firstname_match,
    name_similarity_score,
    address_similarity_score,
    recommended_action
)
SELECT
    LEAST(gc1.golden_customer_id, gc2.golden_customer_id) AS customer_id_1,
    GREATEST(gc1.golden_customer_id, gc2.golden_customer_id) AS customer_id_2,
    'Rule 2: Address + Name Match' AS match_rule,
    CASE
        -- Exact address + exact name = 95%
        WHEN LOWER(gc1.address) = LOWER(gc2.address)
         AND gc1.zip_code = gc2.zip_code
         AND gc1.first_name = gc2.first_name
         AND gc1.last_name = gc2.last_name
        THEN 95.00

        -- Exact address + similar name (first 3 letters LastName + FirstName initial) = 90%
        WHEN LOWER(gc1.address) = LOWER(gc2.address)
         AND gc1.zip_code = gc2.zip_code
         AND SUBSTRING(LOWER(gc1.last_name) FROM 1 FOR 3) = SUBSTRING(LOWER(gc2.last_name) FROM 1 FOR 3)
         AND SUBSTRING(LOWER(gc1.first_name) FROM 1 FOR 1) = SUBSTRING(LOWER(gc2.first_name) FROM 1 FOR 1)
        THEN 90.00

        -- Similar address (Levenshtein distance ≤ 5) + same name prefix = 85%
        WHEN levenshtein(LOWER(gc1.address), LOWER(gc2.address)) <= 5
         AND gc1.zip_code = gc2.zip_code
         AND SUBSTRING(LOWER(gc1.last_name) FROM 1 FOR 3) = SUBSTRING(LOWER(gc2.last_name) FROM 1 FOR 3)
        THEN 85.00

        ELSE 80.00
    END AS confidence_score,
    LOWER(gc1.address) = LOWER(gc2.address) OR levenshtein(LOWER(gc1.address), LOWER(gc2.address)) <= 5 AS address_match,
    SUBSTRING(LOWER(gc1.last_name) FROM 1 FOR 3) = SUBSTRING(LOWER(gc2.last_name) FROM 1 FOR 3) AS lastname_match,
    SUBSTRING(LOWER(gc1.first_name) FROM 1 FOR 1) = SUBSTRING(LOWER(gc2.first_name) FROM 1 FOR 1) AS firstname_match,
    CASE
        WHEN gc1.last_name = gc2.last_name AND gc1.first_name = gc2.first_name THEN 100.00
        WHEN SUBSTRING(LOWER(gc1.last_name) FROM 1 FOR 3) = SUBSTRING(LOWER(gc2.last_name) FROM 1 FOR 3)
         AND SUBSTRING(LOWER(gc1.first_name) FROM 1 FOR 1) = SUBSTRING(LOWER(gc2.first_name) FROM 1 FOR 1)
        THEN 75.00
        ELSE 50.00
    END AS name_similarity_score,
    CASE
        WHEN LOWER(gc1.address) = LOWER(gc2.address) THEN 100.00
        ELSE 100 - (levenshtein(LOWER(gc1.address), LOWER(gc2.address)) * 5)
    END AS address_similarity_score,
    CASE
        WHEN (LOWER(gc1.address) = LOWER(gc2.address)
              AND gc1.zip_code = gc2.zip_code
              AND SUBSTRING(LOWER(gc1.last_name) FROM 1 FOR 3) = SUBSTRING(LOWER(gc2.last_name) FROM 1 FOR 3)
              AND SUBSTRING(LOWER(gc1.first_name) FROM 1 FOR 1) = SUBSTRING(LOWER(gc2.first_name) FROM 1 FOR 1))
        THEN 'Steward Review'
        ELSE 'No Action'
    END AS recommended_action
FROM mdm.golden_customer gc1
JOIN mdm.golden_customer gc2
    ON gc1.zip_code = gc2.zip_code  -- Must have same zip code
    AND gc1.golden_customer_id != gc2.golden_customer_id  -- Different records
    AND gc1.is_active = TRUE
    AND gc2.is_active = TRUE
    AND gc1.master_record_flag = TRUE
    AND gc2.master_record_flag = TRUE
    AND gc1.address IS NOT NULL
    AND gc2.address IS NOT NULL
WHERE (
    -- Exact address match
    LOWER(gc1.address) = LOWER(gc2.address)
    OR
    -- Or similar address (Levenshtein distance ≤ 5)
    levenshtein(LOWER(gc1.address), LOWER(gc2.address)) <= 5
)
AND (
    -- Similar name (first 3 letters of LastName + FirstName initial)
    SUBSTRING(LOWER(gc1.last_name) FROM 1 FOR 3) = SUBSTRING(LOWER(gc2.last_name) FROM 1 FOR 3)
    AND SUBSTRING(LOWER(gc1.first_name) FROM 1 FOR 1) = SUBSTRING(LOWER(gc2.first_name) FROM 1 FOR 1)
)
-- Don't re-insert if already matched by Rule 1
AND NOT EXISTS (
    SELECT 1 FROM mdm.customer_match_candidates cmc
    WHERE (cmc.customer_id_1 = LEAST(gc1.golden_customer_id, gc2.golden_customer_id)
           AND cmc.customer_id_2 = GREATEST(gc1.golden_customer_id, gc2.golden_customer_id))
)
ON CONFLICT (customer_id_1, customer_id_2) DO NOTHING;

\echo 'Address + Name Match complete';
SELECT
    COUNT(*) AS total_matches,
    COUNT(*) FILTER (WHERE recommended_action = 'Steward Review') AS steward_review,
    COUNT(*) FILTER (WHERE confidence_score >= 90) AS high_confidence
FROM mdm.customer_match_candidates
WHERE match_rule = 'Rule 2: Address + Name Match';

\echo '';

-- ============================================================================
-- CREATE STEWARD REVIEW VIEW
-- ============================================================================

\echo '5. Creating steward review views...';
\echo '';

CREATE OR REPLACE VIEW mdm.v_customer_duplicates_for_review AS
SELECT
    cmc.match_id,
    cmc.match_rule,
    cmc.confidence_score,
    cmc.recommended_action,

    -- Customer 1
    gc1.golden_customer_id AS customer_1_id,
    gc1.first_name || ' ' || gc1.last_name AS customer_1_name,
    gc1.email AS customer_1_email,
    gc1.address AS customer_1_address,
    gc1.zip_code AS customer_1_zip,
    gc1.data_quality_score AS customer_1_quality,

    -- Customer 2
    gc2.golden_customer_id AS customer_2_id,
    gc2.first_name || ' ' || gc2.last_name AS customer_2_name,
    gc2.email AS customer_2_email,
    gc2.address AS customer_2_address,
    gc2.zip_code AS customer_2_zip,
    gc2.data_quality_score AS customer_2_quality,

    -- Match Details
    cmc.email_match,
    cmc.firstname_match,
    cmc.lastname_match,
    cmc.address_match,
    cmc.name_similarity_score,
    cmc.address_similarity_score,

    -- Stewardship
    cmc.steward_assigned,
    cmc.reviewed,
    cmc.merge_approved

FROM mdm.customer_match_candidates cmc
JOIN mdm.golden_customer gc1 ON cmc.customer_id_1 = gc1.golden_customer_id
JOIN mdm.golden_customer gc2 ON cmc.customer_id_2 = gc2.golden_customer_id
WHERE cmc.recommended_action IN ('Auto-Merge', 'Steward Review')
  AND cmc.reviewed = FALSE
ORDER BY cmc.confidence_score DESC, cmc.match_id;

\echo 'View created: mdm.v_customer_duplicates_for_review';
\echo '';

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================

\echo '========================================';
\echo 'CUSTOMER MATCHING SUMMARY';
\echo '========================================';
\echo '';

SELECT 'Total Duplicate Candidates' AS metric, COUNT(*)::TEXT AS value
FROM mdm.customer_match_candidates

UNION ALL

SELECT 'Rule 1: Email + Name Match', COUNT(*)::TEXT
FROM mdm.customer_match_candidates
WHERE match_rule = 'Rule 1: Email + Name Match'

UNION ALL

SELECT 'Rule 2: Address + Name Match', COUNT(*)::TEXT
FROM mdm.customer_match_candidates
WHERE match_rule = 'Rule 2: Address + Name Match'

UNION ALL

SELECT 'Recommended: Auto-Merge', COUNT(*)::TEXT
FROM mdm.customer_match_candidates
WHERE recommended_action = 'Auto-Merge'

UNION ALL

SELECT 'Recommended: Steward Review', COUNT(*)::TEXT
FROM mdm.customer_match_candidates
WHERE recommended_action = 'Steward Review'

UNION ALL

SELECT 'High Confidence (≥ 95%)', COUNT(*)::TEXT
FROM mdm.customer_match_candidates
WHERE confidence_score >= 95

UNION ALL

SELECT 'Medium Confidence (85-94%)', COUNT(*)::TEXT
FROM mdm.customer_match_candidates
WHERE confidence_score BETWEEN 85 AND 94

UNION ALL

SELECT 'Already Reviewed', COUNT(*)::TEXT
FROM mdm.customer_match_candidates
WHERE reviewed = TRUE;

\echo '';
\echo 'Top 10 High-Confidence Duplicates:';
SELECT
    match_id,
    ROUND(confidence_score, 1) AS confidence,
    match_rule,
    recommended_action,
    (SELECT first_name || ' ' || last_name FROM mdm.golden_customer WHERE golden_customer_id = customer_id_1) AS customer_1,
    (SELECT first_name || ' ' || last_name FROM mdm.golden_customer WHERE golden_customer_id = customer_id_2) AS customer_2
FROM mdm.customer_match_candidates
ORDER BY confidence_score DESC
LIMIT 10;

\echo '';
\echo '========================================';
\echo 'Customer Matching Complete';
\echo '';
\echo 'Next Steps:';
\echo '  1. Review duplicates: SELECT * FROM mdm.v_customer_duplicates_for_review;';
\echo '  2. Stewards approve/reject merges';
\echo '  3. Run merge process for approved candidates';
\echo '========================================';
