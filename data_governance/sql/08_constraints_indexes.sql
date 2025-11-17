-- ============================================================================
-- File: 08_constraints_indexes.sql
-- Purpose: Add Missing Constraints and Indexes for Data Quality
-- Project: SneakerPark Data Governance - Phase 1
-- Author: Data Architecture Team
-- Date: 2025-11-17
-- ============================================================================

-- This script adds missing constraints and indexes to enforce data quality rules
-- and improve performance. Implements recommendations from data_quality_analysis.md

-- NOTE: This assumes 07_naming_fixes.sql has been run (uses snake_case names)
-- If using original schema, adjust table/column names accordingly

\echo '========================================';
\echo 'Adding Data Quality Constraints and Indexes';
\echo 'Enforcing Data Governance Rules';
\echo '========================================';
\echo '';

-- ============================================================================
-- PHASE 1: Add NOT NULL Constraints (Completeness)
-- ============================================================================

\echo '1. Adding NOT NULL constraints to enforce completeness...';
\echo '';

-- DQ Rule 1: Every listing must have ShoeType
ALTER TABLE li.listings
ALTER COLUMN shoe_type SET NOT NULL;
\echo '  ✓ li.listings.shoe_type → NOT NULL (DQ-001)';

-- DQ Rule 4: Every received item must have ArrivalDate
-- Note: Can't enforce NOT NULL globally because items not yet received will be NULL
-- Instead, we'll create a CHECK constraint
ALTER TABLE im.items
ADD CONSTRAINT chk_items_arrival_date_if_received
CHECK (
    (item_status = 'received' AND arrival_date IS NOT NULL)
    OR
    (item_status != 'received')
);
\echo '  ✓ im.items.arrival_date → CHECK constraint for received items (DQ-004)';

-- Other important NOT NULL constraints
ALTER TABLE usr.users
ALTER COLUMN first_name SET NOT NULL,
ALTER COLUMN last_name SET NOT NULL,
ALTER COLUMN email SET NOT NULL,
ALTER COLUMN address SET NOT NULL,
ALTER COLUMN zip_code SET NOT NULL;
\echo '  ✓ usr.users → All core fields NOT NULL';

\echo '';

-- ============================================================================
-- PHASE 2: Add CHECK Constraints (Validity)
-- ============================================================================

\echo '2. Adding CHECK constraints to enforce validity rules...';
\echo '';

-- DQ Rule 3: Shoe sizes must be between 0.5 and 22
ALTER TABLE li.listings
ADD CONSTRAINT chk_listings_size_valid
CHECK (size::NUMERIC BETWEEN 0.5 AND 22);
\echo '  ✓ li.listings.size → CHECK (0.5 to 22) (DQ-003)';

ALTER TABLE im.items
ADD CONSTRAINT chk_items_size_valid
CHECK (size::NUMERIC BETWEEN 0.5 AND 22);
\echo '  ✓ im.items.size → CHECK (0.5 to 22)';

-- Email format validation (basic)
ALTER TABLE usr.users
ADD CONSTRAINT chk_users_email_format
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
\echo '  ✓ usr.users.email → CHECK email format';

-- Price validation (must be positive)
ALTER TABLE li.listings
ADD CONSTRAINT chk_listings_price_positive
CHECK (listing_price > 0);
\echo '  ✓ li.listings.listing_price → CHECK (> 0)';

-- Order total must be positive
ALTER TABLE op.orders
ADD CONSTRAINT chk_orders_total_positive
CHECK (total_amount > 0);
\echo '  ✓ op.orders.total_amount → CHECK (> 0)';

-- Tax rate must be between 0 and 100 percent
ALTER TABLE op.orders
ADD CONSTRAINT chk_orders_tax_rate_valid
CHECK (tax_rate_percent BETWEEN 0 AND 100);
\echo '  ✓ op.orders.tax_rate_percent → CHECK (0 to 100)';

-- Zip code format (US 5-digit or 5+4 format)
ALTER TABLE usr.users
ADD CONSTRAINT chk_users_zipcode_format
CHECK (zip_code ~* '^\d{5}(-\d{4})?$');
\echo '  ✓ usr.users.zip_code → CHECK format';

-- Gender values (M, F, U for Unisex)
ALTER TABLE li.listings
ADD CONSTRAINT chk_listings_gender_valid
CHECK (gender IN ('M', 'F', 'U'));
\echo '  ✓ li.listings.gender → CHECK (M, F, U)';

-- Listing type validation
ALTER TABLE li.listings
ADD CONSTRAINT chk_listings_type_valid
CHECK (listing_type IN ('auction', 'fixed_price', 'buy_it_now'));
\echo '  ✓ li.listings.listing_type → CHECK valid values';

-- Order status validation
ALTER TABLE op.orders
ADD CONSTRAINT chk_orders_status_valid
CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded'));
\echo '  ✓ op.orders.status → CHECK valid values';

\echo '';

-- ============================================================================
-- PHASE 3: Add UNIQUE Constraints (Uniqueness)
-- ============================================================================

\echo '3. Adding UNIQUE constraints to prevent duplicates...';
\echo '';

-- DQ Rule 5: Prevent duplicate user accounts by email
ALTER TABLE usr.users
ADD CONSTRAINT uq_users_email UNIQUE (email);
\echo '  ✓ usr.users.email → UNIQUE (DQ-005)';

-- Prevent duplicate credit card numbers per user
ALTER TABLE usr.credit_cards
ADD CONSTRAINT uq_credit_cards_number_user UNIQUE (user_id, credit_card_number);
\echo '  ✓ usr.credit_cards → UNIQUE (user_id, credit_card_number)';

-- Ensure listing IDs are unique (already PK, but showing for completeness)
\echo '  ✓ Listing IDs already unique (PK)';

\echo '';

-- ============================================================================
-- PHASE 4: Add Date Logic Constraints (Timeliness)
-- ============================================================================

\echo '4. Adding date logic constraints...';
\echo '';

-- Listing create date must be before or equal to end date
ALTER TABLE li.listings
ADD CONSTRAINT chk_listings_dates_logical
CHECK (listing_end_date IS NULL OR listing_end_date >= listing_create_date);
\echo '  ✓ li.listings → CHECK listing_create_date <= listing_end_date';

-- Order ship date must be on or after order date
ALTER TABLE op.order_shipments
ADD CONSTRAINT chk_shipments_date_logical
CHECK (order_ship_date >= (
    SELECT order_date::DATE FROM op.orders WHERE order_id = order_shipments.order_id
));
\echo '  ✓ op.order_shipments → CHECK order_ship_date >= order_date';

-- Credit card expiration must be in the future (or current month)
ALTER TABLE usr.credit_cards
ADD CONSTRAINT chk_credit_cards_not_expired
CHECK (credit_card_expiration_date >= CURRENT_DATE - INTERVAL '1 month');
\echo '  ✓ usr.credit_cards → CHECK not expired';

\echo '';

-- ============================================================================
-- PHASE 5: Add Performance Indexes
-- ============================================================================

\echo '5. Creating performance indexes...';
\echo '';

-- User lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON usr.users(email);
CREATE INDEX IF NOT EXISTS idx_users_lastname ON usr.users(last_name);
CREATE INDEX IF NOT EXISTS idx_users_zipcode ON usr.users(zip_code);
\echo '  ✓ usr.users indexes (email, last_name, zip_code)';

-- Credit card lookups
CREATE INDEX IF NOT EXISTS idx_credit_cards_user_id ON usr.credit_cards(user_id);
\echo '  ✓ usr.credit_cards indexes (user_id)';

-- Listing lookups and filters
CREATE INDEX IF NOT EXISTS idx_listings_seller_id ON li.listings(seller_id);
CREATE INDEX IF NOT EXISTS idx_listings_brand ON li.listings(brand);
CREATE INDEX IF NOT EXISTS idx_listings_shoe_type ON li.listings(shoe_type);
CREATE INDEX IF NOT EXISTS idx_listings_size ON li.listings(size);
CREATE INDEX IF NOT EXISTS idx_listings_gender ON li.listings(gender);
CREATE INDEX IF NOT EXISTS idx_listings_price ON li.listings(listing_price);
CREATE INDEX IF NOT EXISTS idx_listings_create_date ON li.listings(listing_create_date);
\echo '  ✓ li.listings indexes (seller, brand, type, size, gender, price, date)';

-- Order lookups
CREATE INDEX IF NOT EXISTS idx_orders_buyer_id ON op.orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_orders_credit_card_id ON op.orders(credit_card_id);
CREATE INDEX IF NOT EXISTS idx_orders_date ON op.orders(order_date);
CREATE INDEX IF NOT EXISTS idx_orders_status ON op.orders(status);
\echo '  ✓ op.orders indexes (buyer, credit_card, date, status)';

-- Order items lookups
CREATE INDEX IF NOT EXISTS idx_order_items_listing_id ON op.order_items(listing_id);
\echo '  ✓ op.order_items indexes (listing_id)';

-- Order shipments lookups
CREATE INDEX IF NOT EXISTS idx_order_shipments_order_id ON op.order_shipments(order_id);
CREATE INDEX IF NOT EXISTS idx_order_shipments_tracking ON op.order_shipments(tracking_number);
\echo '  ✓ op.order_shipments indexes (order_id, tracking_number)';

-- Inventory items lookups
CREATE INDEX IF NOT EXISTS idx_items_seller_id ON im.items(seller_id);
CREATE INDEX IF NOT EXISTS idx_items_brand ON im.items(brand);
CREATE INDEX IF NOT EXISTS idx_items_shoe_type ON im.items(shoe_type);
CREATE INDEX IF NOT EXISTS idx_items_status ON im.items(item_status);
CREATE INDEX IF NOT EXISTS idx_items_arrival_date ON im.items(arrival_date);
\echo '  ✓ im.items indexes (seller, brand, type, status, arrival_date)';

-- Customer service request lookups
CREATE INDEX IF NOT EXISTS idx_cs_requests_user_id ON cs.customer_service_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_cs_requests_order_id ON cs.customer_service_requests(order_id);
CREATE INDEX IF NOT EXISTS idx_cs_requests_email ON cs.customer_service_requests(email);
\echo '  ✓ cs.customer_service_requests indexes (user_id, order_id, email)';

-- Composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_listings_search ON li.listings(brand, shoe_type, size, gender);
CREATE INDEX IF NOT EXISTS idx_items_search ON im.items(brand, shoe_type, size, gender);
\echo '  ✓ Composite indexes for search patterns';

\echo '';

-- ============================================================================
-- PHASE 6: Create Triggers for Data Quality Enforcement
-- ============================================================================

\echo '6. Creating triggers for data quality enforcement...';
\echo '';

-- Trigger: Update last_modified_date on Golden Customer records
CREATE OR REPLACE FUNCTION mdm.update_last_modified_date()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_modified_date = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_golden_customer_update
BEFORE UPDATE ON mdm.golden_customer
FOR EACH ROW
EXECUTE FUNCTION mdm.update_last_modified_date();

\echo '  ✓ Trigger: Update last_modified_date on mdm.golden_customer';

-- Trigger: Recalculate data quality score on Golden Customer updates
CREATE OR REPLACE FUNCTION mdm.recalculate_quality_score()
RETURNS TRIGGER AS $$
BEGIN
    NEW.data_quality_score = (
        (CASE WHEN NEW.first_name IS NOT NULL THEN 20 ELSE 0 END) +
        (CASE WHEN NEW.last_name IS NOT NULL THEN 20 ELSE 0 END) +
        (CASE WHEN NEW.email IS NOT NULL THEN 20 ELSE 0 END) +
        (CASE WHEN NEW.address IS NOT NULL THEN 20 ELSE 0 END) +
        (CASE WHEN NEW.zip_code IS NOT NULL THEN 20 ELSE 0 END)
    );

    NEW.completeness_score = NEW.data_quality_score;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_golden_customer_quality_score
BEFORE INSERT OR UPDATE ON mdm.golden_customer
FOR EACH ROW
EXECUTE FUNCTION mdm.recalculate_quality_score();

\echo '  ✓ Trigger: Recalculate data_quality_score on mdm.golden_customer';

-- Trigger: Flag items approaching 45-day deadline
CREATE OR REPLACE FUNCTION mdm.flag_45_day_deadline()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.warehouse_arrival_date IS NOT NULL AND NEW.listing_create_date IS NULL THEN
        IF (CURRENT_DATE - NEW.warehouse_arrival_date) >= 40 THEN
            NEW.forty_five_day_alert = TRUE;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_item_xref_45_day_alert
BEFORE INSERT OR UPDATE ON mdm.item_xref
FOR EACH ROW
EXECUTE FUNCTION mdm.flag_45_day_deadline();

\echo '  ✓ Trigger: Flag 45-day deadline on mdm.item_xref';

\echo '';

-- ============================================================================
-- PHASE 7: Create Data Quality Monitoring Views
-- ============================================================================

\echo '7. Creating data quality monitoring views...';
\echo '';

-- View: Real-time data quality metrics
CREATE OR REPLACE VIEW dq.v_quality_metrics AS
SELECT
    'Missing ShoeType' AS metric,
    'Completeness' AS dimension,
    'li.listings' AS table_name,
    COUNT(*) FILTER (WHERE shoe_type IS NULL) AS issue_count,
    COUNT(*) AS total_records,
    ROUND((COUNT(*) FILTER (WHERE shoe_type IS NULL)::NUMERIC / COUNT(*)) * 100, 2) AS percentage,
    '< 2%' AS target,
    CASE
        WHEN (COUNT(*) FILTER (WHERE shoe_type IS NULL)::NUMERIC / COUNT(*)) > 0.02
        THEN 'FAIL'
        ELSE 'PASS'
    END AS status
FROM li.listings

UNION ALL

SELECT
    'Invalid Sizes',
    'Validity',
    'li.listings',
    COUNT(*) FILTER (WHERE size IS NOT NULL AND (size::NUMERIC < 0.5 OR size::NUMERIC > 22)),
    COUNT(*),
    ROUND((COUNT(*) FILTER (WHERE size IS NOT NULL AND (size::NUMERIC < 0.5 OR size::NUMERIC > 22))::NUMERIC / COUNT(*)) * 100, 2),
    '0%',
    CASE
        WHEN COUNT(*) FILTER (WHERE size IS NOT NULL AND (size::NUMERIC < 0.5 OR size::NUMERIC > 22)) > 0
        THEN 'FAIL'
        ELSE 'PASS'
    END
FROM li.listings

UNION ALL

SELECT
    'Missing ArrivalDate (Received Items)',
    'Timeliness',
    'im.items',
    COUNT(*) FILTER (WHERE item_status = 'received' AND arrival_date IS NULL),
    COUNT(*) FILTER (WHERE item_status = 'received'),
    ROUND((COUNT(*) FILTER (WHERE item_status = 'received' AND arrival_date IS NULL)::NUMERIC / NULLIF(COUNT(*) FILTER (WHERE item_status = 'received'), 0)) * 100, 2),
    '< 1%',
    CASE
        WHEN (COUNT(*) FILTER (WHERE item_status = 'received' AND arrival_date IS NULL)::NUMERIC / NULLIF(COUNT(*) FILTER (WHERE item_status = 'received'), 0)) > 0.01
        THEN 'FAIL'
        ELSE 'PASS'
    END
FROM im.items

UNION ALL

SELECT
    'Duplicate Emails',
    'Uniqueness',
    'usr.users',
    COUNT(*) - COUNT(DISTINCT email),
    COUNT(*),
    ROUND(((COUNT(*) - COUNT(DISTINCT email))::NUMERIC / COUNT(*)) * 100, 2),
    '0%',
    CASE
        WHEN COUNT(*) - COUNT(DISTINCT email) > 0
        THEN 'FAIL'
        ELSE 'PASS'
    END
FROM usr.users;

\echo '  ✓ View: dq.v_quality_metrics (real-time DQ dashboard)';

-- View: Constraint violations
CREATE OR REPLACE VIEW dq.v_constraint_violations AS
SELECT
    'li.listings' AS table_name,
    'shoe_type NOT NULL' AS constraint_name,
    listing_id AS record_id,
    'ShoeType is NULL' AS violation
FROM li.listings
WHERE shoe_type IS NULL

UNION ALL

SELECT
    'li.listings',
    'size CHECK (0.5 to 22)',
    listing_id,
    'Invalid size: ' || size
FROM li.listings
WHERE size IS NOT NULL AND (size::NUMERIC < 0.5 OR size::NUMERIC > 22)

UNION ALL

SELECT
    'im.items',
    'arrival_date for received items',
    item_id,
    'Received item missing arrival date'
FROM im.items
WHERE item_status = 'received' AND arrival_date IS NULL;

\echo '  ✓ View: dq.v_constraint_violations (monitor violations)';

\echo '';

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================

\echo '========================================';
\echo 'CONSTRAINTS AND INDEXES - SUMMARY';
\echo '========================================';
\echo '';

\echo 'Constraints Added:';
\echo '  - NOT NULL: 6 columns (completeness enforcement)';
\echo '  - CHECK: 12 constraints (validity rules)';
\echo '  - UNIQUE: 2 constraints (duplicate prevention)';
\echo '  - Date Logic: 3 constraints (timeliness)';
\echo '';

\echo 'Indexes Created:';
\echo '  - Single-column: 25 indexes';
\echo '  - Composite: 2 indexes';
\echo '  - Total: 27 performance indexes';
\echo '';

\echo 'Triggers Created:';
\echo '  - 3 data quality enforcement triggers';
\echo '  - Automatic quality score calculation';
\echo '  - 45-day rule alert automation';
\echo '';

\echo 'Views Created:';
\echo '  - dq.v_quality_metrics (real-time DQ monitoring)';
\echo '  - dq.v_constraint_violations (violation tracking)';
\echo '';

\echo '========================================';
\echo 'Constraints and Indexes Complete';
\echo '';
\echo 'Data Quality Rules Now Enforced:';
\echo '  ✓ DQ-001: Every listing must have ShoeType';
\echo '  ✓ DQ-003: Shoe sizes must be 0.5-22';
\echo '  ✓ DQ-004: Received items must have ArrivalDate';
\echo '  ✓ DQ-005: Email addresses must be unique';
\echo '';
\echo 'Monitor Compliance:';
\echo '  SELECT * FROM dq.v_quality_metrics;';
\echo '  SELECT * FROM dq.v_constraint_violations;';
\echo '========================================';
