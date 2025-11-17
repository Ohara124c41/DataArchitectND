-- ============================================================================
-- File: 04_mdm_item_crossref.sql
-- Purpose: Create Item Cross-Reference Index (Registry Component)
-- Project: SneakerPark Data Governance - Phase 1
-- Author: Data Architecture Team
-- Date: 2025-11-17
-- ============================================================================

-- This script implements the Registry MDM component for Item cross-referencing
-- Part of the Hybrid MDM Architecture (Centralized for Customers, Registry for Items)

\echo '========================================';
\echo 'Creating MDM Item Cross-Reference Index';
\echo 'Registry Component - Hybrid Architecture';
\echo '========================================';
\echo '';

-- ============================================================================
-- ITEM CROSS-REFERENCE TABLE
-- ============================================================================

\echo '1. Creating Item Cross-Reference index table...';
\echo '';

CREATE TABLE IF NOT EXISTS mdm.item_xref (
    xref_id SERIAL PRIMARY KEY,

    -- Item Identifiers (lightweight index, no data duplication)
    item_id INT,  -- From im.Items (Inventory Management)
    product_id INT,  -- From li.listings (Listing Service)
    listing_id INT,  -- From li.listings (Listing Service)
    seller_id INT NOT NULL,  -- Common across both systems

    -- Physical Product Attributes (for matching)
    brand_name VARCHAR(100),
    color VARCHAR(15),
    size VARCHAR(4),
    condition VARCHAR(50),
    shoe_type VARCHAR(50),
    gender VARCHAR(10),

    -- Cross-Reference Metadata
    link_type VARCHAR(50) DEFAULT 'probable' CHECK (link_type IN ('definite', 'probable', 'possible')),
    confidence_score NUMERIC(5,2) DEFAULT 0.00 CHECK (confidence_score BETWEEN 0 AND 100),
    match_rule VARCHAR(100),  -- References matching rule used

    -- Lifecycle Tracking
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_sync_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,

    -- Business Process Tracking
    warehouse_arrival_date DATE,  -- From im.Items.ArrivalDate
    listing_create_date DATE,  -- From li.listings.ListingCreateDate
    days_to_listing INT,  -- Calculated: listing_create_date - warehouse_arrival_date
    forty_five_day_alert BOOLEAN DEFAULT FALSE,  -- Flag if approaching deadline

    -- System References
    source_im_system VARCHAR(10) DEFAULT 'im',
    source_li_system VARCHAR(10) DEFAULT 'li',

    -- Unique constraint: Each listing can only be linked once
    UNIQUE (listing_id),
    -- Each item can potentially link to multiple listings (same item listed multiple times)
    -- But typically 1:1 or 1:0 relationship
    CHECK (item_id IS NOT NULL OR listing_id IS NOT NULL)  -- At least one must exist
);

\echo 'Item Cross-Reference table created: mdm.item_xref';
\echo '';

-- ============================================================================
-- ITEM MATCH HISTORY TABLE
-- ============================================================================

\echo '2. Creating Item Match History table...';
\echo '';

CREATE TABLE IF NOT EXISTS mdm.item_match_history (
    match_id SERIAL PRIMARY KEY,
    xref_id INT REFERENCES mdm.item_xref(xref_id),

    -- Match Details
    match_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    match_rule VARCHAR(100) NOT NULL,
    confidence_score NUMERIC(5,2) NOT NULL,

    -- Source Records
    item_id INT,
    listing_id INT,

    -- Match Attributes Used
    attributes_matched TEXT[],  -- e.g., ['Brand', 'Color', 'Size', 'Condition', 'Gender']
    attributes_count INT,

    -- Stewardship
    auto_matched BOOLEAN DEFAULT TRUE,
    steward_reviewed BOOLEAN DEFAULT FALSE,
    reviewed_by VARCHAR(100),
    review_date TIMESTAMP,
    review_notes TEXT
);

\echo 'Item Match History table created: mdm.item_match_history';
\echo '';

-- ============================================================================
-- LOAD INVENTORY MANAGEMENT ITEMS
-- ============================================================================

\echo '3. Loading items from Inventory Management system...';
\echo '';

INSERT INTO mdm.item_xref (
    item_id,
    seller_id,
    brand_name,
    color,
    size,
    condition,
    shoe_type,
    gender,
    warehouse_arrival_date,
    link_type,
    confidence_score,
    match_rule
)
SELECT
    ItemID,
    SellerID,
    BrandName,
    Color,
    Size,
    Condition,
    Type AS shoe_type,
    Sex AS gender,
    ArrivalDate,
    'definite',  -- From authoritative source
    100.00,
    'Direct load from im.Items'
FROM im.Items
WHERE ItemID IS NOT NULL
ON CONFLICT (listing_id) DO NOTHING;  -- Prevent duplicates on reload

\echo 'Inventory Management items loaded';
SELECT COUNT(*) AS im_items_loaded FROM mdm.item_xref WHERE item_id IS NOT NULL;

\echo '';

-- ============================================================================
-- LINK LISTINGS TO ITEMS
-- ============================================================================

\echo '4. Linking Listing Service listings to Inventory Management items...';
\echo '';

-- Update existing records with listing information where match is found
UPDATE mdm.item_xref
SET
    listing_id = l.ListingID,
    product_id = l.ProductID,
    listing_create_date = l.ListingCreateDate,
    days_to_listing = l.ListingCreateDate - mdm.item_xref.warehouse_arrival_date,
    forty_five_day_alert = CASE
        WHEN (l.ListingCreateDate - mdm.item_xref.warehouse_arrival_date) >= 40
        THEN TRUE
        ELSE FALSE
    END,
    last_sync_date = CURRENT_TIMESTAMP,
    link_type = 'definite',
    confidence_score = 100.00,
    match_rule = 'SellerID + Physical Characteristics Match'
FROM li.listings l
WHERE mdm.item_xref.seller_id = l.SellerID
  AND mdm.item_xref.item_id IS NOT NULL
  AND mdm.item_xref.listing_id IS NULL
  AND mdm.item_xref.brand_name = l.Brand
  AND mdm.item_xref.color = l.Color
  AND mdm.item_xref.size = l.Size
  AND mdm.item_xref.condition = l.Condition;

\echo 'Listings linked to items using physical characteristics match';
SELECT COUNT(*) AS matched_items_to_listings
FROM mdm.item_xref
WHERE item_id IS NOT NULL AND listing_id IS NOT NULL;

\echo '';

-- ============================================================================
-- INSERT ORPHAN LISTINGS (not yet in warehouse)
-- ============================================================================

\echo '5. Loading orphan listings (not yet matched to warehouse items)...';
\echo '';

-- Insert listings that don't match any warehouse items
-- These may be items still in transit or data quality issues
INSERT INTO mdm.item_xref (
    listing_id,
    product_id,
    seller_id,
    brand_name,
    color,
    size,
    condition,
    shoe_type,
    gender,
    listing_create_date,
    link_type,
    confidence_score,
    match_rule
)
SELECT
    l.ListingID,
    l.ProductID,
    l.SellerID,
    l.Brand,
    l.Color,
    l.Size,
    l.Condition,
    l.ShoeType,
    l.Gender,
    l.ListingCreateDate,
    'possible',  -- Not yet linked to warehouse
    50.00,
    'Listing without warehouse item'
FROM li.listings l
WHERE NOT EXISTS (
    SELECT 1 FROM mdm.item_xref xref
    WHERE xref.listing_id = l.ListingID
)
ON CONFLICT (listing_id) DO NOTHING;

\echo 'Orphan listings loaded';
SELECT COUNT(*) AS orphan_listings
FROM mdm.item_xref
WHERE listing_id IS NOT NULL AND item_id IS NULL;

\echo '';

-- ============================================================================
-- CALCULATE 45-DAY RULE VIOLATIONS
-- ============================================================================

\echo '6. Calculating 45-day rule compliance...';
\echo '';

UPDATE mdm.item_xref
SET
    forty_five_day_alert = TRUE
WHERE warehouse_arrival_date IS NOT NULL
  AND listing_create_date IS NOT NULL
  AND (listing_create_date - warehouse_arrival_date) >= 40;

\echo 'Items flagged for 45-day rule violations:';
SELECT
    COUNT(*) AS items_at_risk,
    COUNT(*) FILTER (WHERE days_to_listing >= 45) AS overdue_items,
    COUNT(*) FILTER (WHERE days_to_listing BETWEEN 40 AND 44) AS warning_items
FROM mdm.item_xref
WHERE days_to_listing IS NOT NULL;

\echo '';

-- Identify unlisted items approaching deadline
\echo 'Unlisted items approaching 45-day deadline:';
SELECT
    COUNT(*) AS unlisted_approaching_deadline
FROM mdm.item_xref
WHERE item_id IS NOT NULL
  AND listing_id IS NULL
  AND warehouse_arrival_date IS NOT NULL
  AND (CURRENT_DATE - warehouse_arrival_date) >= 40;

\echo '';

-- ============================================================================
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

\echo '7. Creating indexes for fast lookups...';
\echo '';

CREATE INDEX IF NOT EXISTS idx_item_xref_item_id ON mdm.item_xref(item_id) WHERE item_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_item_xref_listing_id ON mdm.item_xref(listing_id) WHERE listing_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_item_xref_seller_id ON mdm.item_xref(seller_id);
CREATE INDEX IF NOT EXISTS idx_item_xref_product_id ON mdm.item_xref(product_id) WHERE product_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_item_xref_active ON mdm.item_xref(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_item_xref_alert ON mdm.item_xref(forty_five_day_alert) WHERE forty_five_day_alert = TRUE;

-- Composite index for matching queries
CREATE INDEX IF NOT EXISTS idx_item_xref_match ON mdm.item_xref(seller_id, brand_name, color, size, condition);

\echo 'Indexes created for MDM Item Cross-Reference';
\echo '';

-- ============================================================================
-- CREATE VIEWS FOR EASY ACCESS
-- ============================================================================

\echo '8. Creating convenience views...';
\echo '';

-- View: Items needing listing (approaching 45-day deadline)
CREATE OR REPLACE VIEW mdm.v_items_needing_listing AS
SELECT
    xref.item_id,
    xref.seller_id,
    xref.brand_name,
    xref.color,
    xref.size,
    xref.condition,
    xref.warehouse_arrival_date,
    CURRENT_DATE - xref.warehouse_arrival_date AS days_in_warehouse,
    45 - (CURRENT_DATE - xref.warehouse_arrival_date) AS days_remaining,
    CASE
        WHEN (CURRENT_DATE - xref.warehouse_arrival_date) >= 45
        THEN 'OVERDUE - Return to seller'
        WHEN (CURRENT_DATE - xref.warehouse_arrival_date) >= 40
        THEN 'URGENT - Less than 5 days'
        WHEN (CURRENT_DATE - xref.warehouse_arrival_date) >= 30
        THEN 'WARNING - Less than 15 days'
        ELSE 'OK'
    END AS urgency
FROM mdm.item_xref xref
WHERE xref.item_id IS NOT NULL
  AND xref.listing_id IS NULL
  AND xref.warehouse_arrival_date IS NOT NULL
ORDER BY xref.warehouse_arrival_date ASC;

\echo 'View created: mdm.v_items_needing_listing';

-- View: Orphan listings (no warehouse item)
CREATE OR REPLACE VIEW mdm.v_orphan_listings AS
SELECT
    xref.listing_id,
    xref.product_id,
    xref.seller_id,
    xref.brand_name,
    xref.color,
    xref.size,
    xref.condition,
    xref.listing_create_date,
    CURRENT_DATE - xref.listing_create_date AS days_since_listed,
    'No warehouse item found' AS issue
FROM mdm.item_xref xref
WHERE xref.listing_id IS NOT NULL
  AND xref.item_id IS NULL
ORDER BY xref.listing_create_date DESC;

\echo 'View created: mdm.v_orphan_listings';

-- View: Item-to-Listing timeline
CREATE OR REPLACE VIEW mdm.v_item_listing_timeline AS
SELECT
    xref.item_id,
    xref.listing_id,
    xref.seller_id,
    xref.brand_name || ' ' || xref.color || ' ' || xref.shoe_type AS product_description,
    xref.warehouse_arrival_date,
    xref.listing_create_date,
    xref.days_to_listing,
    CASE
        WHEN xref.days_to_listing IS NULL THEN 'Not yet listed'
        WHEN xref.days_to_listing < 0 THEN 'Listed before arrival (data issue)'
        WHEN xref.days_to_listing <= 7 THEN 'Quick listing (< 1 week)'
        WHEN xref.days_to_listing <= 30 THEN 'Normal listing (1-4 weeks)'
        WHEN xref.days_to_listing <= 45 THEN 'Slow listing (4-6 weeks)'
        WHEN xref.days_to_listing > 45 THEN '45-day rule violation'
    END AS timeline_category,
    xref.forty_five_day_alert,
    xref.confidence_score,
    xref.match_rule
FROM mdm.item_xref xref
WHERE xref.item_id IS NOT NULL
ORDER BY xref.days_to_listing DESC NULLS FIRST;

\echo 'View created: mdm.v_item_listing_timeline';
\echo '';

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================

\echo '========================================';
\echo 'MDM ITEM CROSS-REFERENCE INDEX - SUMMARY';
\echo '========================================';
\echo '';

SELECT 'Total Cross-Reference Records' AS metric, COUNT(*)::TEXT AS value
FROM mdm.item_xref

UNION ALL

SELECT 'Warehouse Items (im.Items)', COUNT(*)::TEXT
FROM mdm.item_xref
WHERE item_id IS NOT NULL

UNION ALL

SELECT 'Listings (li.listings)', COUNT(*)::TEXT
FROM mdm.item_xref
WHERE listing_id IS NOT NULL

UNION ALL

SELECT 'Matched (Item + Listing)', COUNT(*)::TEXT
FROM mdm.item_xref
WHERE item_id IS NOT NULL AND listing_id IS NOT NULL

UNION ALL

SELECT 'Orphan Items (not listed)', COUNT(*)::TEXT
FROM mdm.item_xref
WHERE item_id IS NOT NULL AND listing_id IS NULL

UNION ALL

SELECT 'Orphan Listings (no warehouse item)', COUNT(*)::TEXT
FROM mdm.item_xref
WHERE listing_id IS NOT NULL AND item_id IS NULL

UNION ALL

SELECT '45-Day Rule Violations', COUNT(*)::TEXT
FROM mdm.item_xref
WHERE days_to_listing >= 45

UNION ALL

SELECT '45-Day Rule Warnings (40-44 days)', COUNT(*)::TEXT
FROM mdm.item_xref
WHERE days_to_listing BETWEEN 40 AND 44

UNION ALL

SELECT 'Unlisted Items Approaching Deadline', COUNT(*)::TEXT
FROM mdm.v_items_needing_listing
WHERE urgency IN ('OVERDUE - Return to seller', 'URGENT - Less than 5 days')

UNION ALL

SELECT 'Average Days to Listing', ROUND(AVG(days_to_listing), 1)::TEXT || ' days'
FROM mdm.item_xref
WHERE days_to_listing IS NOT NULL AND days_to_listing >= 0;

\echo '';
\echo '========================================';
\echo 'Item Cross-Reference Index Creation Complete';
\echo '';
\echo 'Next Steps:';
\echo '  1. Run item matching rules (06_item_matching.sql)';
\echo '  2. Review orphan items: SELECT * FROM mdm.v_items_needing_listing;';
\echo '  3. Review orphan listings: SELECT * FROM mdm.v_orphan_listings;';
\echo '  4. Set up nightly batch sync from im.Items';
\echo '========================================';
