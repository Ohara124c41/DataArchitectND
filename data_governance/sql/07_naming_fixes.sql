-- ============================================================================
-- File: 07_naming_fixes.sql
-- Purpose: Apply Recommended Naming Conventions
-- Project: SneakerPark Data Governance - Phase 1
-- Author: Data Architecture Team
-- Date: 2025-11-17
-- ============================================================================

-- This script applies the naming convention recommendations from naming_conventions.md
-- WARNING: This is a major refactoring. Run in non-production environment first.
-- Requires application code updates to reference new names.

\echo '========================================';
\echo 'Applying Naming Convention Standards';
\echo 'WARNING: Breaking changes - coordinate with development teams';
\echo '========================================';
\echo '';

-- ============================================================================
-- PHASE 1: Rename Tables (PascalCase → snake_case)
-- ============================================================================

\echo '1. Renaming tables to lowercase_with_underscores...';
\echo '';

-- Orders → orders
ALTER TABLE IF EXISTS op.Orders RENAME TO orders;
\echo '  ✓ op.Orders → op.orders';

-- OrderItems → order_items
ALTER TABLE IF EXISTS op.OrderItems RENAME TO order_items;
\echo '  ✓ op.OrderItems → op.order_items';

-- OrderShipments → order_shipments
ALTER TABLE IF EXISTS op.OrderShipments RENAME TO order_shipments;
\echo '  ✓ op.OrderShipments → op.order_shipments';

-- Items → items
ALTER TABLE IF EXISTS im.Items RENAME TO items;
\echo '  ✓ im.Items → im.items';

-- CustomerServiceRequests → customer_service_requests
ALTER TABLE IF EXISTS cs.CustomerServiceRequests RENAME TO customer_service_requests;
\echo '  ✓ cs.CustomerServiceRequests → cs.customer_service_requests';

-- creditcards → credit_cards (add underscore)
ALTER TABLE IF EXISTS usr.creditcards RENAME TO credit_cards;
\echo '  ✓ usr.creditcards → usr.credit_cards';

\echo '';
\echo 'Table renaming complete';
\echo '';

-- ============================================================================
-- PHASE 2: Rename Columns (PascalCase → snake_case)
-- ============================================================================

\echo '2. Renaming columns to lowercase_with_underscores...';
\echo '';

-- usr.users columns
\echo 'Updating usr.users columns...';
ALTER TABLE usr.users RENAME COLUMN UserID TO user_id;
ALTER TABLE usr.users RENAME COLUMN FirstName TO first_name;
ALTER TABLE usr.users RENAME COLUMN LastName TO last_name;
ALTER TABLE usr.users RENAME COLUMN Email TO email;
ALTER TABLE usr.users RENAME COLUMN Address TO address;
ALTER TABLE usr.users RENAME COLUMN ZipCode TO zip_code;
\echo '  ✓ usr.users columns updated (6 columns)';
\echo '';

-- usr.credit_cards columns
\echo 'Updating usr.credit_cards columns...';
ALTER TABLE usr.credit_cards RENAME COLUMN CreditCardID TO credit_card_id;
ALTER TABLE usr.credit_cards RENAME COLUMN CreditCardNumber TO credit_card_number;
ALTER TABLE usr.credit_cards RENAME COLUMN CreditCardExpirationDate TO credit_card_expiration_date;
ALTER TABLE usr.credit_cards RENAME COLUMN UserID TO user_id;
\echo '  ✓ usr.credit_cards columns updated (4 columns)';
\echo '';

-- li.listings columns
\echo 'Updating li.listings columns...';
ALTER TABLE li.listings RENAME COLUMN ListingID TO listing_id;
ALTER TABLE li.listings RENAME COLUMN SellerID TO seller_id;
ALTER TABLE li.listings RENAME COLUMN ProductID TO product_id;
ALTER TABLE li.listings RENAME COLUMN ShoeType TO shoe_type;
ALTER TABLE li.listings RENAME COLUMN Brand TO brand;
ALTER TABLE li.listings RENAME COLUMN Color TO color;
ALTER TABLE li.listings RENAME COLUMN Gender TO gender;
ALTER TABLE li.listings RENAME COLUMN Size TO size;
ALTER TABLE li.listings RENAME COLUMN Condition TO condition;
ALTER TABLE li.listings RENAME COLUMN ListingPrice TO listing_price;
ALTER TABLE li.listings RENAME COLUMN ListingType TO listing_type;
ALTER TABLE li.listings RENAME COLUMN ListingCreateDate TO listing_create_date;
ALTER TABLE li.listings RENAME COLUMN ListingEndDate TO listing_end_date;
\echo '  ✓ li.listings columns updated (13 columns)';
\echo '';

-- op.orders columns
\echo 'Updating op.orders columns...';
ALTER TABLE op.orders RENAME COLUMN OrderID TO order_id;
ALTER TABLE op.orders RENAME COLUMN BuyerID TO buyer_id;
ALTER TABLE op.orders RENAME COLUMN CreditCardID TO credit_card_id;
ALTER TABLE op.orders RENAME COLUMN ShippingCost TO shipping_cost;
ALTER TABLE op.orders RENAME COLUMN TaxRatePercent TO tax_rate_percent;
ALTER TABLE op.orders RENAME COLUMN TotalAmount TO total_amount;
ALTER TABLE op.orders RENAME COLUMN ShippingAddress TO shipping_address;
ALTER TABLE op.orders RENAME COLUMN ShippingZipCode TO shipping_zip_code;
ALTER TABLE op.orders RENAME COLUMN OrderDate TO order_date;
ALTER TABLE op.orders RENAME COLUMN Status TO status;
\echo '  ✓ op.orders columns updated (10 columns)';
\echo '';

-- op.order_items columns
\echo 'Updating op.order_items columns...';
ALTER TABLE op.order_items RENAME COLUMN OrderID TO order_id;
ALTER TABLE op.order_items RENAME COLUMN ListingID TO listing_id;
ALTER TABLE op.order_items RENAME COLUMN ListingSoldPrice TO listing_sold_price;
\echo '  ✓ op.order_items columns updated (3 columns)';
\echo '';

-- op.order_shipments columns
\echo 'Updating op.order_shipments columns...';
ALTER TABLE op.order_shipments RENAME COLUMN ShipmentID TO shipment_id;
ALTER TABLE op.order_shipments RENAME COLUMN OrderID TO order_id;
ALTER TABLE op.order_shipments RENAME COLUMN Carrier TO carrier;
ALTER TABLE op.order_shipments RENAME COLUMN TrackingNumber TO tracking_number;
ALTER TABLE op.order_shipments RENAME COLUMN OrderShipDate TO order_ship_date;
\echo '  ✓ op.order_shipments columns updated (5 columns)';
\echo '';

-- im.items columns
\echo 'Updating im.items columns...';
ALTER TABLE im.items RENAME COLUMN ItemID TO item_id;
ALTER TABLE im.items RENAME COLUMN ItemName TO item_name;
ALTER TABLE im.items RENAME COLUMN SellerID TO seller_id;
ALTER TABLE im.items RENAME COLUMN Type TO shoe_type;  -- Standardize to shoe_type
ALTER TABLE im.items RENAME COLUMN BrandName TO brand;  -- Standardize to brand
ALTER TABLE im.items RENAME COLUMN Color TO color;
ALTER TABLE im.items RENAME COLUMN Size TO size;
ALTER TABLE im.items RENAME COLUMN Sex TO gender;  -- Standardize to gender
ALTER TABLE im.items RENAME COLUMN Condition TO condition;
ALTER TABLE im.items RENAME COLUMN ItemStatus TO item_status;
ALTER TABLE im.items RENAME COLUMN ArrivalDate TO arrival_date;
\echo '  ✓ im.items columns updated (11 columns)';
\echo '';

-- cs.customer_service_requests columns
\echo 'Updating cs.customer_service_requests columns...';
ALTER TABLE cs.customer_service_requests RENAME COLUMN ID TO request_id;  -- More descriptive
ALTER TABLE cs.customer_service_requests RENAME COLUMN UserID TO user_id;
ALTER TABLE cs.customer_service_requests RENAME COLUMN FirstName TO first_name;
ALTER TABLE cs.customer_service_requests RENAME COLUMN LastName TO last_name;
ALTER TABLE cs.customer_service_requests RENAME COLUMN ContactReason TO contact_reason;
ALTER TABLE cs.customer_service_requests RENAME COLUMN Email TO email;
ALTER TABLE cs.customer_service_requests RENAME COLUMN Phone TO phone;
ALTER TABLE cs.customer_service_requests RENAME COLUMN OrderID TO order_id;
ALTER TABLE cs.customer_service_requests RENAME COLUMN Resolution TO resolution;
ALTER TABLE cs.customer_service_requests RENAME COLUMN ContactMethod TO contact_method;
\echo '  ✓ cs.customer_service_requests columns updated (10 columns)';
\echo '';

\echo 'Column renaming complete (62 columns renamed)';
\echo '';

-- ============================================================================
-- PHASE 3: Standardize Field Name Variations
-- ============================================================================

\echo '3. Standardizing field name variations across systems...';
\echo '';

-- Brand vs BrandName → brand (already done in im.items above)
\echo '  ✓ BrandName standardized to brand';

-- Gender vs Sex → gender (already done in im.items above)
\echo '  ✓ Sex standardized to gender';

-- ShoeType vs Type → shoe_type (already done in im.items above)
\echo '  ✓ Type standardized to shoe_type';

\echo '';
\echo 'Field name standardization complete';
\echo '';

-- ============================================================================
-- PHASE 4: Rename Constraints (Following Naming Convention)
-- ============================================================================

\echo '4. Renaming constraints to standard format...';
\echo '';

-- Primary Key Constraints: pk_{table_name}
\echo 'Renaming primary key constraints...';

-- Note: Constraint renaming syntax varies by PostgreSQL version
-- This uses the standard ALTER TABLE RENAME CONSTRAINT syntax

-- usr.users
ALTER TABLE usr.users RENAME CONSTRAINT users_pkey TO pk_users;
\echo '  ✓ pk_users';

-- usr.credit_cards
ALTER TABLE usr.credit_cards RENAME CONSTRAINT creditcards_pkey TO pk_credit_cards;
\echo '  ✓ pk_credit_cards';

-- li.listings
ALTER TABLE li.listings RENAME CONSTRAINT listings_pkey TO pk_listings;
\echo '  ✓ pk_listings';

-- op.orders
ALTER TABLE op.orders RENAME CONSTRAINT orders_pkey TO pk_orders;
\echo '  ✓ pk_orders';

-- op.order_items
ALTER TABLE op.order_items RENAME CONSTRAINT orderitems_pkey TO pk_order_items;
\echo '  ✓ pk_order_items';

-- op.order_shipments
ALTER TABLE op.order_shipments RENAME CONSTRAINT ordershipments_pkey TO pk_order_shipments;
\echo '  ✓ pk_order_shipments';

-- im.items
ALTER TABLE im.items RENAME CONSTRAINT items_pkey TO pk_items;
\echo '  ✓ pk_items';

-- cs.customer_service_requests
ALTER TABLE cs.customer_service_requests RENAME CONSTRAINT customerservicerequests_pkey TO pk_customer_service_requests;
\echo '  ✓ pk_customer_service_requests';

\echo '';

-- Foreign Key Constraints: fk_{table}_{referenced_table}
\echo 'Renaming foreign key constraints...';

ALTER TABLE usr.credit_cards RENAME CONSTRAINT creditcards_userid_fkey TO fk_credit_cards_users;
\echo '  ✓ fk_credit_cards_users';

ALTER TABLE li.listings RENAME CONSTRAINT listings_sellerid_fkey TO fk_listings_users;
\echo '  ✓ fk_listings_users';

ALTER TABLE op.orders RENAME CONSTRAINT orders_buyerid_fkey TO fk_orders_users_buyer;
\echo '  ✓ fk_orders_users_buyer';

ALTER TABLE op.orders RENAME CONSTRAINT orders_creditcardid_fkey TO fk_orders_credit_cards;
\echo '  ✓ fk_orders_credit_cards';

ALTER TABLE op.order_items RENAME CONSTRAINT orderitems_listingid_fkey TO fk_order_items_listings;
\echo '  ✓ fk_order_items_listings';

ALTER TABLE op.order_items RENAME CONSTRAINT orderitems_orderid_fkey TO fk_order_items_orders;
\echo '  ✓ fk_order_items_orders';

ALTER TABLE op.order_shipments RENAME CONSTRAINT ordershipments_orderid_fkey TO fk_order_shipments_orders;
\echo '  ✓ fk_order_shipments_orders';

\echo '';
\echo 'Constraint renaming complete';
\echo '';

-- ============================================================================
-- PHASE 5: Create Indexes with Standard Naming
-- ============================================================================

\echo '5. Renaming indexes to standard format (idx_{table}_{column})...';
\echo '';

-- This would require identifying existing indexes and renaming them
-- For brevity, showing examples:

-- Example: idx_listings_seller_id
-- ALTER INDEX IF EXISTS listings_sellerid_idx RENAME TO idx_listings_seller_id;

\echo '  Note: Index renaming requires identifying existing index names';
\echo '  Refer to 08_constraints_indexes.sql for new index creation';
\echo '';

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================

\echo '========================================';
\echo 'NAMING CONVENTION UPDATES - SUMMARY';
\echo '========================================';
\echo '';

\echo 'Tables Renamed: 6';
\echo '  - op.Orders → op.orders';
\echo '  - op.OrderItems → op.order_items';
\echo '  - op.OrderShipments → op.order_shipments';
\echo '  - im.Items → im.items';
\echo '  - cs.CustomerServiceRequests → cs.customer_service_requests';
\echo '  - usr.creditcards → usr.credit_cards';
\echo '';

\echo 'Columns Renamed: 62 across 8 tables';
\echo '  - All PascalCase → snake_case';
\echo '  - Standardized: BrandName → brand, Sex → gender, Type → shoe_type';
\echo '';

\echo 'Constraints Renamed: 15';
\echo '  - 8 Primary Key constraints: pk_{table}';
\echo '  - 7 Foreign Key constraints: fk_{table}_{referenced_table}';
\echo '';

\echo '========================================';
\echo 'Naming Convention Updates Complete';
\echo '';
\echo 'CRITICAL NEXT STEPS:';
\echo '  1. Update all application code to use new table/column names';
\echo '  2. Update ORM models (if applicable)';
\echo '  3. Update API endpoints and queries';
\echo '  4. Update documentation and ERD diagrams';
\echo '  5. Update stored procedures and views';
\echo '  6. Run comprehensive integration tests';
\echo '';
\echo 'ROLLBACK: If issues occur, restore from backup';
\echo '========================================';
