-- ============================================================================
-- File: 06_item_matching.sql
-- Purpose: Implement Item Matching Rules for Cross-Referencing
-- Project: SneakerPark Data Governance - Phase 1
-- Author: Data Architecture Team
-- Date: 2025-11-17
-- ============================================================================

-- This script implements the 2 item matching rules defined in Part 6:
--   1. Physical Characteristics Match (High Confidence: 95%+)
--   2. Seller + ItemID Match (Very High Confidence: 98%+)

\echo '========================================';
\echo 'Item Matching Rules - Cross-Referencing';
\echo 'MDM Registry Component';
\echo '========================================';
\echo '';

-- ============================================================================
-- MATCHING RULE 1: Physical Characteristics Match (High Confidence: 95%+)
-- ============================================================================

\echo '1. Running Matching Rule 1: Physical Characteristics Match...';
\echo '';

-- Rule 1: Exact match on Brand AND Color AND Size AND Condition AND Gender

-- Find items in warehouse that match listings by physical characteristics
WITH physical_matches AS (
    SELECT
        i.ItemID,
        i.SellerID,
        l.ListingID,
        l.ProductID,

        -- Physical attribute matches
        i.BrandName = l.Brand AS brand_match,
        i.Color = l.Color AS color_match,
        i.Size = l.Size AS size_match,
        i.Condition = l.Condition AS condition_match,
        (i.Sex = l.Gender OR
         (i.Sex = 'Male' AND l.Gender = 'M') OR
         (i.Sex = 'Female' AND l.Gender = 'F') OR
         (i.Sex = 'Unisex' AND l.Gender = 'U')) AS gender_match,

        -- Count matching attributes
        (CASE WHEN i.BrandName = l.Brand THEN 1 ELSE 0 END +
         CASE WHEN i.Color = l.Color THEN 1 ELSE 0 END +
         CASE WHEN i.Size = l.Size THEN 1 ELSE 0 END +
         CASE WHEN i.Condition = l.Condition THEN 1 ELSE 0 END +
         CASE WHEN (i.Sex = l.Gender OR
                    (i.Sex = 'Male' AND l.Gender = 'M') OR
                    (i.Sex = 'Female' AND l.Gender = 'F') OR
                    (i.Sex = 'Unisex' AND l.Gender = 'U'))
              THEN 1 ELSE 0 END) AS match_count

    FROM im.Items i
    CROSS JOIN li.listings l
    WHERE i.SellerID = l.SellerID  -- Must be same seller
)
-- Update cross-reference table with matches
UPDATE mdm.item_xref
SET
    item_id = pm.ItemID,
    confidence_score = CASE
        WHEN pm.match_count = 5 THEN 100.00  -- All 5 attributes match
        WHEN pm.match_count = 4 THEN 85.00   -- 4 out of 5 match
        ELSE 70.00
    END,
    match_rule = 'Rule 1: Physical Characteristics Match (' || pm.match_count || '/5 attributes)',
    link_type = CASE
        WHEN pm.match_count = 5 THEN 'definite'
        WHEN pm.match_count = 4 THEN 'probable'
        ELSE 'possible'
    END,
    last_sync_date = CURRENT_TIMESTAMP
FROM physical_matches pm
WHERE item_xref.listing_id = pm.ListingID
  AND item_xref.item_id IS NULL  -- Only update unmatched listings
  AND pm.match_count >= 5;  -- Require all 5 attributes to match for high confidence

\echo 'Physical Characteristics Match complete';
SELECT
    'Rule 1: Physical Match' AS rule,
    COUNT(*) AS matches_found,
    COUNT(*) FILTER (WHERE confidence_score = 100) AS perfect_matches,
    ROUND(AVG(confidence_score), 1) AS avg_confidence
FROM mdm.item_xref
WHERE match_rule LIKE 'Rule 1:%';

\echo '';

-- Insert match history
INSERT INTO mdm.item_match_history (xref_id, match_rule, confidence_score, item_id, listing_id, attributes_matched, attributes_count, auto_matched)
SELECT
    xref.xref_id,
    xref.match_rule,
    xref.confidence_score,
    xref.item_id,
    xref.listing_id,
    ARRAY['Brand', 'Color', 'Size', 'Condition', 'Gender'],
    5,
    TRUE
FROM mdm.item_xref xref
WHERE xref.match_rule LIKE 'Rule 1:%'
  AND NOT EXISTS (
      SELECT 1 FROM mdm.item_match_history h
      WHERE h.xref_id = xref.xref_id
  );

\echo 'Match history recorded';
\echo '';

-- ============================================================================
-- MATCHING RULE 2: Seller + ItemID Match (Very High Confidence: 98%+)
-- ============================================================================

\echo '2. Running Matching Rule 2: Seller + ItemID Within 45-Day Window...';
\echo '';

-- Rule 2: Same SellerID AND ItemID exists in both systems within 45-day window

-- This rule links items to listings based on seller tracking and timeline
-- Assumes sellers create listings after shipping items to warehouse

WITH seller_item_timeline AS (
    SELECT
        i.ItemID,
        i.SellerID,
        i.ArrivalDate,
        l.ListingID,
        l.ProductID,
        l.ListingCreateDate,
        l.ListingCreateDate - i.ArrivalDate AS days_between,

        -- Confidence based on timeline proximity
        CASE
            WHEN l.ListingCreateDate - i.ArrivalDate BETWEEN 0 AND 7 THEN 100.00  -- Listed within 1 week
            WHEN l.ListingCreateDate - i.ArrivalDate BETWEEN 8 AND 30 THEN 98.00  -- Listed within 1 month
            WHEN l.ListingCreateDate - i.ArrivalDate BETWEEN 31 AND 45 THEN 95.00 -- Listed within 45 days
            WHEN l.ListingCreateDate - i.ArrivalDate < 0 THEN 60.00  -- Listed before arrival (data quality issue)
            ELSE 50.00  -- Listed after 45 days (45-day rule violation)
        END AS timeline_confidence

    FROM im.Items i
    JOIN li.listings l ON i.SellerID = l.SellerID
    WHERE i.ArrivalDate IS NOT NULL
      AND l.ListingCreateDate IS NOT NULL
      AND ABS(l.ListingCreateDate - i.ArrivalDate) <= 60  -- Within 60 days (includes violations)
)
-- Update cross-reference with seller+timeline matches
UPDATE mdm.item_xref
SET
    item_id = COALESCE(item_xref.item_id, st.ItemID),  -- Don't overwrite if already matched
    warehouse_arrival_date = st.ArrivalDate,
    listing_create_date = st.ListingCreateDate,
    days_to_listing = st.days_between,
    confidence_score = CASE
        WHEN item_xref.confidence_score > st.timeline_confidence THEN item_xref.confidence_score  -- Keep higher score
        ELSE st.timeline_confidence
    END,
    match_rule = CASE
        WHEN item_xref.match_rule IS NOT NULL AND item_xref.item_id IS NOT NULL
        THEN item_xref.match_rule || ' + Rule 2: Seller + Timeline'  -- Combined match
        ELSE 'Rule 2: Seller + ItemID + Timeline Match'
    END,
    link_type = 'definite',
    forty_five_day_alert = CASE
        WHEN st.days_between >= 40 THEN TRUE
        ELSE FALSE
    END,
    last_sync_date = CURRENT_TIMESTAMP
FROM seller_item_timeline st
WHERE item_xref.listing_id = st.ListingID
  AND st.timeline_confidence >= 95;  -- High confidence matches only

\echo 'Seller + ItemID + Timeline Match complete';
SELECT
    'Rule 2: Seller + Timeline' AS rule,
    COUNT(*) AS matches_found,
    COUNT(*) FILTER (WHERE confidence_score = 100) AS within_1_week,
    COUNT(*) FILTER (WHERE confidence_score >= 98) AS within_1_month,
    ROUND(AVG(confidence_score), 1) AS avg_confidence
FROM mdm.item_xref
WHERE match_rule LIKE '%Rule 2:%';

\echo '';

-- Insert match history
INSERT INTO mdm.item_match_history (xref_id, match_rule, confidence_score, item_id, listing_id, attributes_matched, attributes_count, auto_matched)
SELECT
    xref.xref_id,
    'Rule 2: Seller + ItemID + Timeline Match',
    xref.confidence_score,
    xref.item_id,
    xref.listing_id,
    ARRAY['SellerID', 'Timeline'],
    2,
    TRUE
FROM mdm.item_xref xref
WHERE xref.match_rule LIKE '%Rule 2:%'
  AND NOT EXISTS (
      SELECT 1 FROM mdm.item_match_history h
      WHERE h.xref_id = xref.xref_id
        AND h.match_rule = 'Rule 2: Seller + ItemID + Timeline Match'
  );

\echo 'Match history recorded';
\echo '';

-- ============================================================================
-- IDENTIFY LOW-CONFIDENCE MATCHES NEEDING REVIEW
-- ============================================================================

\echo '3. Identifying low-confidence matches for steward review...';
\echo '';

-- Find items/listings with low confidence or conflicting matches
CREATE OR REPLACE VIEW mdm.v_low_confidence_item_matches AS
SELECT
    xref.xref_id,
    xref.item_id,
    xref.listing_id,
    xref.seller_id,
    xref.brand_name,
    xref.color,
    xref.size,
    xref.condition,
    xref.confidence_score,
    xref.match_rule,
    xref.link_type,
    CASE
        WHEN xref.confidence_score < 85 THEN 'Low confidence - steward review needed'
        WHEN xref.item_id IS NULL THEN 'Orphan listing - no warehouse item'
        WHEN xref.listing_id IS NULL THEN 'Unlisted item - approaching deadline?'
        WHEN xref.days_to_listing < 0 THEN 'Data quality issue - listed before arrival'
        WHEN xref.days_to_listing >= 45 THEN '45-day rule violation'
        ELSE 'Review recommended'
    END AS review_reason
FROM mdm.item_xref xref
WHERE xref.confidence_score < 85
   OR xref.item_id IS NULL
   OR (xref.listing_id IS NULL AND xref.warehouse_arrival_date IS NOT NULL)
   OR xref.days_to_listing < 0
   OR xref.days_to_listing >= 45
ORDER BY xref.confidence_score ASC NULLS FIRST;

\echo 'View created: mdm.v_low_confidence_item_matches';

SELECT COUNT(*) AS items_needing_review
FROM mdm.v_low_confidence_item_matches;

\echo '';

-- ============================================================================
-- CALCULATE MATCH QUALITY METRICS
-- ============================================================================

\echo '4. Calculating match quality metrics...';
\echo '';

CREATE OR REPLACE VIEW mdm.v_item_match_metrics AS
SELECT
    'Total Items in Warehouse' AS metric,
    COUNT(DISTINCT item_id)::TEXT AS value
FROM mdm.item_xref
WHERE item_id IS NOT NULL

UNION ALL

SELECT
    'Total Listings',
    COUNT(DISTINCT listing_id)::TEXT
FROM mdm.item_xref
WHERE listing_id IS NOT NULL

UNION ALL

SELECT
    'Successfully Matched (Item + Listing)',
    COUNT(*)::TEXT
FROM mdm.item_xref
WHERE item_id IS NOT NULL AND listing_id IS NOT NULL

UNION ALL

SELECT
    'Match Rate',
    ROUND(
        (COUNT(*) FILTER (WHERE item_id IS NOT NULL AND listing_id IS NOT NULL)::NUMERIC /
         NULLIF(COUNT(DISTINCT item_id), 0)) * 100,
        1
    )::TEXT || '%'
FROM mdm.item_xref

UNION ALL

SELECT
    'High Confidence Matches (≥ 95%)',
    COUNT(*)::TEXT
FROM mdm.item_xref
WHERE confidence_score >= 95

UNION ALL

SELECT
    'Medium Confidence (85-94%)',
    COUNT(*)::TEXT
FROM mdm.item_xref
WHERE confidence_score BETWEEN 85 AND 94

UNION ALL

SELECT
    'Low Confidence (< 85%)',
    COUNT(*)::TEXT
FROM mdm.item_xref
WHERE confidence_score < 85

UNION ALL

SELECT
    'Average Match Confidence',
    ROUND(AVG(confidence_score), 1)::TEXT || '%'
FROM mdm.item_xref
WHERE confidence_score > 0;

\echo '';

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================

\echo '========================================';
\echo 'ITEM MATCHING SUMMARY';
\echo '========================================';
\echo '';

SELECT * FROM mdm.v_item_match_metrics;

\echo '';
\echo 'Matching Rule Breakdown:';
SELECT
    CASE
        WHEN match_rule LIKE '%Rule 1%' AND match_rule LIKE '%Rule 2%' THEN 'Both Rules (Combined)'
        WHEN match_rule LIKE '%Rule 1%' THEN 'Rule 1: Physical Characteristics'
        WHEN match_rule LIKE '%Rule 2%' THEN 'Rule 2: Seller + Timeline'
        ELSE 'Other/Direct Load'
    END AS match_type,
    COUNT(*) AS count,
    ROUND(AVG(confidence_score), 1) AS avg_confidence,
    MIN(confidence_score) AS min_confidence,
    MAX(confidence_score) AS max_confidence
FROM mdm.item_xref
WHERE item_id IS NOT NULL AND listing_id IS NOT NULL
GROUP BY
    CASE
        WHEN match_rule LIKE '%Rule 1%' AND match_rule LIKE '%Rule 2%' THEN 'Both Rules (Combined)'
        WHEN match_rule LIKE '%Rule 1%' THEN 'Rule 1: Physical Characteristics'
        WHEN match_rule LIKE '%Rule 2%' THEN 'Rule 2: Seller + Timeline'
        ELSE 'Other/Direct Load'
    END
ORDER BY count DESC;

\echo '';
\echo '45-Day Rule Compliance:';
SELECT
    CASE
        WHEN days_to_listing IS NULL THEN 'Not yet listed'
        WHEN days_to_listing < 0 THEN 'Listed before arrival (data issue)'
        WHEN days_to_listing <= 30 THEN 'Good (0-30 days)'
        WHEN days_to_listing BETWEEN 31 AND 39 THEN 'Acceptable (31-39 days)'
        WHEN days_to_listing BETWEEN 40 AND 44 THEN 'Warning (40-44 days)'
        WHEN days_to_listing >= 45 THEN 'VIOLATION (≥ 45 days)'
    END AS timeline_status,
    COUNT(*) AS item_count
FROM mdm.item_xref
WHERE item_id IS NOT NULL
GROUP BY
    CASE
        WHEN days_to_listing IS NULL THEN 'Not yet listed'
        WHEN days_to_listing < 0 THEN 'Listed before arrival (data issue)'
        WHEN days_to_listing <= 30 THEN 'Good (0-30 days)'
        WHEN days_to_listing BETWEEN 31 AND 39 THEN 'Acceptable (31-39 days)'
        WHEN days_to_listing BETWEEN 40 AND 44 THEN 'Warning (40-44 days)'
        WHEN days_to_listing >= 45 THEN 'VIOLATION (≥ 45 days)'
    END
ORDER BY
    CASE
        WHEN days_to_listing IS NULL THEN 1
        WHEN days_to_listing < 0 THEN 2
        WHEN days_to_listing <= 30 THEN 3
        WHEN days_to_listing BETWEEN 31 AND 39 THEN 4
        WHEN days_to_listing BETWEEN 40 AND 44 THEN 5
        WHEN days_to_listing >= 45 THEN 6
    END;

\echo '';
\echo '========================================';
\echo 'Item Matching Complete';
\echo '';
\echo 'Next Steps:';
\echo '  1. Review low-confidence matches: SELECT * FROM mdm.v_low_confidence_item_matches;';
\echo '  2. Address 45-day rule violations: SELECT * FROM mdm.v_items_needing_listing;';
\echo '  3. Investigate orphan listings: SELECT * FROM mdm.v_orphan_listings;';
\echo '========================================';
