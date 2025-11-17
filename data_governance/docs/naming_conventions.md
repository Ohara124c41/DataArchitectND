# SneakerPark Data Naming Conventions

## Purpose
This document establishes standard naming conventions for SneakerPark's data assets to improve consistency, readability, and maintainability across all systems.

---

## Current State Analysis

### Existing Naming Patterns Observed

#### Schema Names
✅ **Good Practice**: Short, lowercase, meaningful abbreviations
- `usr` - User Service
- `li` - Listing Service
- `op` - Order Processing
- `im` - Inventory Management
- `cs` - Customer Service

**Assessment**: Generally good, follows PostgreSQL conventions

---

#### Table Names
⚠️ **Mixed Practice**: Some inconsistencies found

**Current Patterns**:
- `usr.users` ✅ Plural noun (good)
- `usr.creditcards` ❌ Compound word without separator (should be `credit_cards`)
- `li.listings` ✅ Plural noun (good)
- `op.Orders` ❌ Capitalized (should be lowercase `orders`)
- `op.OrderItems` ❌ PascalCase (should be `order_items`)
- `op.OrderShipments` ❌ PascalCase (should be `order_shipments`)
- `im.Items` ❌ Capitalized (should be lowercase `items`)
- `cs.CustomerServiceRequests` ❌ PascalCase (should be `customer_service_requests`)

**Issues**:
- Inconsistent capitalization (some lowercase, some PascalCase)
- Inconsistent word separators (some run together, some use PascalCase, none use underscores)

---

#### Column Names
⚠️ **Highly Inconsistent**: Multiple patterns used

**Current Patterns**:

**PascalCase** (used in some tables):
- `UserID`, `FirstName`, `LastName`, `Email`, `Address`, `ZipCode` ❌
- `CreditCardID`, `CreditCardNumber`, `CreditCardExpirationDate` ❌
- `OrderID`, `BuyerID`, `ShippingCost`, `TotalAmount`, `OrderDate` ❌

**lowercase** (used in some tables):
- `userid`, `firstname`, `lastname`, `email` ❌ (in INSERT statements)
- `listingid`, `sellerid`, `productid`, `shoetype`, `listingprice` ❌

**Mixed Case Issues**:
```sql
-- Table definition uses PascalCase:
CREATE TABLE usr.users (
    UserID INT NOT NULL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    ...
);

-- But INSERT statements use lowercase:
INSERT INTO usr.users (userid, firstname, lastname, ...)
```

**Identifier Naming**:
- Some IDs use suffix: `UserID`, `OrderID`, `ListingID` ✅
- Some IDs use suffix: `ID` (generic) in cs.CustomerServiceRequests ❌

---

#### Data Type Conventions
⚠️ **Inconsistent Precision**

**Issues**:
- VARCHAR lengths vary without clear pattern:
  - `FirstName VARCHAR(50)` vs `LastName VARCHAR(50)` ✅ Consistent
  - `Email VARCHAR(50)` ❌ Too short for modern email addresses (should be 100+)
  - `Address VARCHAR(50)` ❌ Too short for full addresses (should be 200+)
  - `ShippingAddress VARCHAR(100)` ⚠️ Different from Address (inconsistent)
  - `ItemName VARCHAR(100)` vs `BrandName VARCHAR(100)` ✅ Consistent

- DECIMAL precision:
  - `ListingPrice DECIMAL(8,2)` ✅ Good for currency
  - `ShippingCost DECIMAL(5,2)` ✅ Good for shipping
  - Consistent use of 2 decimal places for money ✅

---

## Recommended Naming Conventions

### 1. General Principles

**Use Descriptive Names**
- Names should clearly indicate what data is stored
- Avoid cryptic abbreviations (unless industry-standard)
- Aim for clarity over brevity

**Be Consistent**
- Use the same pattern throughout all databases
- If you use underscores, always use underscores (never mix with PascalCase)
- If you abbreviate, abbreviate consistently

**Use Standard English**
- Avoid slang, regional terms, or jargon
- Use singular for entities (e.g., "user" not "users" for entity)
- Use plural for tables (e.g., "users" table stores multiple user records)

**Avoid Reserved Words**
- Don't use SQL keywords as names (e.g., "Order" is reserved, use "orders" or "customer_order")
- Check database-specific reserved word lists

---

### 2. Schema Naming

**Convention**: `lowercase_with_underscores`

**Pattern**: `{business_area}` or `{application_abbreviation}`

**Examples**:
- `user_service` or `usr` ✅
- `listing_service` or `li` ✅
- `order_processing` or `op` ✅
- `inventory_mgmt` or `im` ✅
- `customer_service` or `cs` ✅

**Notes**:
- Keep abbreviations short (2-4 characters) for convenience
- Document abbreviation meanings in data dictionary
- Avoid generic names like "data", "main", "prod"

**Current State**: ✅ SneakerPark's current schema names are good, no changes needed.

---

### 3. Table Naming

**Convention**: `lowercase_with_underscores`, **plural noun**

**Pattern**: `{entity_name_plural}`

**Examples**:
- ✅ `users` (not `user`, `Users`, or `tblUsers`)
- ✅ `credit_cards` (not `creditcards`, `CreditCards`)
- ✅ `listings` (not `listing`, `Listings`)
- ✅ `orders` (not `Orders`, `Order`)
- ✅ `order_items` (not `OrderItems`, `orderitems`)
- ✅ `customer_service_requests` (not `CustomerServiceRequests`)

**Rationale**:
- Plural indicates table stores multiple records
- Lowercase avoids quoting issues in SQL
- Underscores improve readability for multi-word names

**Junction/Bridge Tables**:
- Pattern: `{entity1}_{entity2}` (alphabetical order if no primary)
- Example: `order_items` (links orders to listings)

**Avoid**:
- Prefixes like `tbl_`, `dim_`, `fact_` (use schemas instead)
- Hungarian notation

**Improvements Needed**:
```sql
-- CURRENT (Inconsistent):
usr.creditcards          -- Missing underscore
op.Orders                -- Capitalized
op.OrderItems            -- PascalCase
op.OrderShipments        -- PascalCase
im.Items                 -- Capitalized
cs.CustomerServiceRequests -- PascalCase

-- RECOMMENDED:
usr.credit_cards
op.orders
op.order_items
op.order_shipments
im.items
cs.customer_service_requests
```

---

### 4. Column Naming

**Convention**: `lowercase_with_underscores`

**Pattern**: `{descriptive_name}` or `{table_name}_{attribute}`

**Examples**:
- ✅ `user_id` (not `UserID`, `userId`, `ID`)
- ✅ `first_name` (not `FirstName`, `fname`)
- ✅ `last_name` (not `LastName`, `lname`)
- ✅ `email_address` (not `Email`, `emailAddr`)
- ✅ `listing_price` (not `ListingPrice`, `price`)
- ✅ `listing_create_date` (not `ListingCreateDate`, `createDate`)

**Primary Keys**:
- Pattern: `{table_name_singular}_id`
- Examples:
  - `user_id` for users table
  - `order_id` for orders table
  - `listing_id` for listings table

**Foreign Keys**:
- Pattern: `{referenced_table_singular}_id`
- Examples:
  - `user_id` in credit_cards table (references users.user_id)
  - `seller_id` in listings table (references users.user_id, role-specific name)
  - `buyer_id` in orders table (references users.user_id, role-specific name)

**Boolean Columns**:
- Pattern: `is_{condition}` or `has_{attribute}`
- Examples:
  - `is_active` (not `active`, `Active`)
  - `has_shipped` (not `shipped`, `Shipped`)
  - `is_authenticated` (not `authenticated`)

**Date/Time Columns**:
- Pattern: `{event}_date` or `{event}_timestamp` or `{event}_datetime`
- Examples:
  - `create_date` (not `createDate`, `CreateDate`, `created`)
  - `order_date` vs `order_timestamp` (specify precision)
  - `arrival_date` (not `arrivaldate`, `ArrivalDate`)

**Monetary Columns**:
- Pattern: `{description}_amount` or `{description}_cost` or `{description}_price`
- Examples:
  - `listing_price` (not `price`, `ListingPrice`)
  - `shipping_cost` (not `ShippingCost`)
  - `total_amount` (not `TotalAmount`, `total`)

**Avoid**:
- Abbreviations: `fname`, `lname`, `addr`, `qty` (use full words)
- Data type in name: `user_id_int`, `price_decimal` (redundant)
- Plurals in column names: `emails`, `addresses` (column stores single value)
- Prefixes: `str_first_name`, `int_user_id` (use data types instead)

**Improvements Needed**:
```sql
-- CURRENT (Inconsistent PascalCase):
UserID, FirstName, LastName, Email, Address, ZipCode
CreditCardID, CreditCardNumber, CreditCardExpirationDate
ListingID, SellerID, ProductID, ShoeType, Brand, Color
OrderID, BuyerID, ShippingCost, TaxRatePercent, TotalAmount

-- RECOMMENDED (snake_case):
user_id, first_name, last_name, email_address, street_address, zip_code
credit_card_id, card_number, expiration_date
listing_id, seller_id, product_id, shoe_type, brand_name, color_name
order_id, buyer_id, shipping_cost, tax_rate_percent, total_amount
```

---

### 5. Constraint Naming

**Convention**: `{constraint_type}_{table_name}_{column_name(s)}`

**Primary Keys**:
- Pattern: `pk_{table_name}`
- Example: `pk_users`, `pk_orders`, `pk_order_items`

**Foreign Keys**:
- Pattern: `fk_{table_name}_{referenced_table}`
- Example: `fk_credit_cards_users`, `fk_orders_users`, `fk_listings_users`

**Unique Constraints**:
- Pattern: `uq_{table_name}_{column_name}`
- Example: `uq_users_email`, `uq_listings_listing_id`

**Check Constraints**:
- Pattern: `chk_{table_name}_{column_name}_{rule}`
- Example: `chk_listings_shoe_size_range`, `chk_users_email_format`

**Indexes**:
- Pattern: `idx_{table_name}_{column_name(s)}`
- Example: `idx_listings_seller_id`, `idx_orders_buyer_id`

**Example**:
```sql
CREATE TABLE users (
  user_id INT NOT NULL,
  email_address VARCHAR(100) NOT NULL,
  zip_code VARCHAR(10) NOT NULL,

  CONSTRAINT pk_users PRIMARY KEY (user_id),
  CONSTRAINT uq_users_email UNIQUE (email_address),
  CONSTRAINT chk_users_zip_code_length CHECK (LENGTH(zip_code) >= 5)
);

CREATE INDEX idx_users_zip_code ON users(zip_code);
```

**Current State**: ⚠️ Constraints are unnamed or use defaults (e.g., `users_pkey`). Recommend adding explicit names.

---

### 6. Data Type Standards

**Strings**:
- Use `VARCHAR(n)` with appropriate length, not `TEXT` for structured data
- Recommended lengths:
  - Names (first, last): `VARCHAR(100)`
  - Email: `VARCHAR(254)` (RFC 5321 max length)
  - Phone: `VARCHAR(20)` (international format with +)
  - Addresses: `VARCHAR(200)`
  - City: `VARCHAR(100)`
  - State/Province: `VARCHAR(50)` or `CHAR(2)` if using abbreviations
  - Zip/Postal Code: `VARCHAR(10)` (supports formats like "12345-6789")
  - Short codes (Gender, Status): `VARCHAR(20)` for flexibility

**Identifiers**:
- Use `INT` or `BIGINT` for IDs (auto-incrementing)
- Use `UUID` if distributed system with potential ID collisions
- SneakerPark should use `BIGINT` as they scale (handles up to 9 quintillion IDs)

**Monetary Values**:
- Use `DECIMAL(precision, scale)` NOT `FLOAT` or `REAL` (avoid rounding errors)
- Pattern: `DECIMAL(10, 2)` for amounts up to $99,999,999.99
- Examples:
  - Listing Price: `DECIMAL(8, 2)` (up to $999,999.99) ✅
  - Shipping Cost: `DECIMAL(5, 2)` (up to $999.99) ✅
  - Total Amount: `DECIMAL(10, 2)` (up to $99,999,999.99)

**Dates and Times**:
- Use `DATE` for dates without time (e.g., arrival_date, birth_date)
- Use `TIMESTAMP` or `TIMESTAMP WITH TIME ZONE` for date-times (e.g., order_timestamp, created_at)
- Avoid `DATETIME` (not standard SQL)
- Always use UTC in database, convert to local timezone in application

**Booleans**:
- Use `BOOLEAN` type (TRUE/FALSE/NULL)
- NOT `CHAR(1)` with 'Y'/'N' or `INT` with 0/1
- Example: `is_active BOOLEAN DEFAULT TRUE`

**Improvements Needed**:
```sql
-- CURRENT:
Email VARCHAR(50)           -- Too short
Address VARCHAR(50)         -- Too short
Gender CHAR(1)              -- Inflexible
Status VARCHAR(50)          -- Okay but could be enum

-- RECOMMENDED:
email_address VARCHAR(254)  -- RFC-compliant
street_address VARCHAR(200) -- Accommodates long addresses
gender VARCHAR(20)          -- Flexible for "Male", "Female", "Non-Binary", etc.
order_status VARCHAR(50)    -- OR use ENUM/CHECK constraint
```

---

### 7. Abbreviation Standards

**Avoid Abbreviations** when possible for clarity. When necessary:

**Acceptable Abbreviations**:
- `id` - identifier (universal)
- `num` - number (e.g., tracking_num)
- `qty` - quantity ⚠️ (prefer `quantity`)
- `amt` - amount ⚠️ (prefer `amount`)
- `addr` - address ❌ (prefer full word)
- `desc` - description ⚠️ (okay in `product_desc`, but `description` is better)

**Standard Acronyms** (industry-recognized):
- `url` - Uniform Resource Locator
- `ssn` - Social Security Number
- `uuid` - Universally Unique Identifier
- `api` - Application Programming Interface

**SneakerPark-Specific Abbreviations** (document in glossary):
- `usr` - User Service schema
- `li` - Listing Service schema
- `op` - Order Processing schema
- `im` - Inventory Management schema
- `cs` - Customer Service schema

**Rule**: If abbreviation is not universally known, spell it out.

---

### 8. Special Cases

**Temporal Columns** (Audit Trail):
- `created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP`
- `updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`
- `created_by_user_id INT` (foreign key to users)
- `updated_by_user_id INT`

**Soft Deletes**:
- `is_deleted BOOLEAN DEFAULT FALSE`
- `deleted_at TIMESTAMP NULL`
- `deleted_by_user_id INT NULL`

**Versioning**:
- `version_number INT NOT NULL DEFAULT 1`
- `effective_from_date DATE NOT NULL`
- `effective_to_date DATE NULL`

**Status/State Columns**:
- Use meaningful enums or VARCHAR with CHECK constraint
- Examples:
  - `order_status VARCHAR(20) CHECK (order_status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))`
  - `item_status VARCHAR(20) CHECK (item_status IN ('received', 'approved', 'listed', 'sold', 'rejected', 'returned'))`

---

## Implementation Roadmap

### Phase 1: Documentation (Immediate)
1. ✅ Document current naming conventions (this document)
2. Publish naming standards to all developers and data team
3. Add naming conventions to onboarding materials
4. Include in code review checklist

### Phase 2: New Development (Ongoing)
1. Apply naming conventions to all new tables/columns
2. Enforce via code review process
3. Use database migration tools that support naming standards
4. Update ORM/application layer to use new names

### Phase 3: Remediation (Gradual)
⚠️ **Do NOT rename existing tables/columns immediately** - this will break applications!

**Safe Approach**:
1. Create views with new names pointing to old tables
```sql
-- Example: Create view with standard name
CREATE VIEW op.order_items AS SELECT * FROM op.OrderItems;
```

2. Update applications incrementally to use views
3. Once all applications migrated, rename underlying tables
4. Drop views (or keep for backwards compatibility)

**Priority for Remediation**:
1. **High**: Fix capitalization inconsistencies (Orders → orders, Items → items)
2. **Medium**: Fix compound words (creditcards → credit_cards)
3. **Low**: Column renames (UserID → user_id) - only if major refactor planned

**Timeline**: 6-12 months for full remediation alongside normal development cycles

---

## Naming Convention Checklist

Before creating any new database object, verify:

- [ ] Name is **lowercase** (no PascalCase, no UPPERCASE)
- [ ] Multi-word names use **underscores** (not camelCase, not run together)
- [ ] Name is **descriptive** (clear meaning without documentation)
- [ ] **No abbreviations** (unless industry-standard like ID, URL)
- [ ] **No reserved words** (check PostgreSQL reserved word list)
- [ ] **Plural** for tables (e.g., users, orders)
- [ ] **Singular** for columns (e.g., user_id, not users_id)
- [ ] IDs end with **_id** suffix (e.g., user_id, order_id)
- [ ] Dates end with **_date** or **_timestamp** (e.g., created_date, order_timestamp)
- [ ] Booleans start with **is_** or **has_** (e.g., is_active, has_shipped)
- [ ] Monetary values end with **_amount**, **_price**, or **_cost** (e.g., total_amount, listing_price)
- [ ] Constraints follow naming pattern (pk_, fk_, uq_, chk_, idx_)

---

## Examples: Before and After

### Table Rename Examples
```sql
-- BEFORE (Current):
CREATE TABLE op.OrderItems (
  OrderID INT NOT NULL,
  ListingID INT NOT NULL,
  ListingSoldPrice DECIMAL(8,2),
  PRIMARY KEY (OrderID, ListingID)
);

-- AFTER (Recommended):
CREATE TABLE op.order_items (
  order_id INT NOT NULL,
  listing_id INT NOT NULL,
  sold_price DECIMAL(8,2),

  CONSTRAINT pk_order_items PRIMARY KEY (order_id, listing_id),
  CONSTRAINT fk_order_items_orders FOREIGN KEY (order_id) REFERENCES op.orders(order_id),
  CONSTRAINT fk_order_items_listings FOREIGN KEY (listing_id) REFERENCES li.listings(listing_id)
);
```

### Column Rename Examples
```sql
-- BEFORE:
CREATE TABLE usr.users (
  UserID INT NOT NULL PRIMARY KEY,
  FirstName VARCHAR(50) NOT NULL,
  LastName VARCHAR(50) NOT NULL,
  Email VARCHAR(50) NOT NULL,
  Address VARCHAR(50) NOT NULL,
  ZipCode VARCHAR(10) NOT NULL
);

-- AFTER:
CREATE TABLE usr.users (
  user_id BIGINT NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email_address VARCHAR(254) NOT NULL,
  street_address VARCHAR(200) NOT NULL,
  zip_code VARCHAR(10) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT pk_users PRIMARY KEY (user_id),
  CONSTRAINT uq_users_email UNIQUE (email_address),
  CONSTRAINT chk_users_email_format CHECK (email_address LIKE '%@%.%')
);

CREATE INDEX idx_users_email ON users(email_address);
CREATE INDEX idx_users_zip_code ON users(zip_code);
```

---

## Governance and Enforcement

**Responsibility**: Enterprise Data Architect (or Data Architecture team)

**Enforcement Methods**:
1. **Code Reviews**: Reject PRs that violate naming conventions
2. **Database Migrations**: Require naming standard compliance before approval
3. **Automated Linting**: Use tools like SQLFluff to enforce standards
4. **Documentation**: Require data dictionary entry for all new tables/columns
5. **Training**: Include in developer onboarding

**Review Cycle**: Quarterly review of naming standards, update as needed

**Exception Process**: If exception needed, document rationale and get Data Architect approval

---

## Benefits of Standard Naming Conventions

### Developer Productivity
- ✅ New developers understand schema faster
- ✅ Less time spent deciphering cryptic names
- ✅ Easier to write queries (autocomplete works better)

### Data Quality
- ✅ Reduces naming errors and typos
- ✅ Consistent data types prevent conversion errors
- ✅ Constraints are discoverable (named consistently)

### Maintenance
- ✅ Easier to refactor and upgrade systems
- ✅ Clearer dependencies between tables
- ✅ Less tribal knowledge required

### Integration
- ✅ APIs and data exports have intuitive field names
- ✅ MDM Hub matching is easier with standardized names
- ✅ Reporting tools work better (readable column names)

### Future-Proofing
- ✅ Prepared for Phase 2 (Enterprise Data Warehouse)
- ✅ Easier to add new systems following same pattern
- ✅ International expansion won't require renaming

---

## Summary of Key Changes Needed

| Current | Recommended | Priority |
|---------|-------------|----------|
| `op.Orders` | `op.orders` | High |
| `op.OrderItems` | `op.order_items` | High |
| `op.OrderShipments` | `op.order_shipments` | High |
| `im.Items` | `im.items` | High |
| `cs.CustomerServiceRequests` | `cs.customer_service_requests` | High |
| `usr.creditcards` | `usr.credit_cards` | Medium |
| `UserID` | `user_id` | Medium |
| `FirstName` | `first_name` | Medium |
| `Email VARCHAR(50)` | `email_address VARCHAR(254)` | Medium |
| `Address VARCHAR(50)` | `street_address VARCHAR(200)` | Medium |
| `Gender CHAR(1)` | `gender VARCHAR(20)` | Low |

---

*These naming conventions will improve consistency and maintainability across SneakerPark's data landscape. Implement gradually to avoid disrupting existing systems.*
