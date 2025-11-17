# Data Quality Analysis for SneakerPark

## Data Quality Issues Identified

### CURRENT ISSUE #1: Missing Values in Required Fields

**Table**: li.listings
**Column**: ShoeType
**Dimension**: Completeness

**Description**:
The ShoeType column contains NULL values despite being important product information for buyers. ShoeType helps customers filter and search for specific footwear categories.

**Example**:
```sql
-- Row 1712: ShoeType is NULL
INSERT INTO li.listings (..., shoetype, ...)
VALUES (922399, 25516, 509, NULL, 'UnderArmor', 'brown', 'F', '12', 'Used', ...);

-- Row 1714: ShoeType is NULL
INSERT INTO li.listings (..., shoetype, ...)
VALUES (695111, 1903, 672, NULL, 'Nike', 'brown', 'M', '10', 'Open Box', ...);
```

**Impact**:
- Customers cannot filter by shoe type
- Search functionality is degraded
- Incomplete product information reduces sales conversion
- Data appears unprofessional

**Suggested Resolution**:
- Make ShoeType a required field at data entry (application validation)
- Backfill existing NULL values by inferring from Item.Type in Inventory System
- Create data quality rule to prevent future NULLs

**Data Quality Rule** (Business Terms):
*"Every listing must have a shoe type specified to help customers find the right product"*

**Measurable Metric**:
`Percentage of listings with NULL ShoeType = (COUNT of listings where ShoeType IS NULL / COUNT of all listings) × 100`

**Monitoring Query**:
```sql
SELECT
  COUNT(*) FILTER (WHERE ShoeType IS NULL) as null_count,
  COUNT(*) as total_count,
  ROUND(100.0 * COUNT(*) FILTER (WHERE ShoeType IS NULL) / COUNT(*), 2) as null_percentage
FROM li.listings;
```

---

### CURRENT ISSUE #2: Inconsistent Data Across Systems (Name Spelling Discrepancies)

**Table**: cs.CustomerServiceRequests
**Column**: LastName
**Dimension**: Consistency, Accuracy

**Description**:
Customer names in the Customer Service system do not match the User Service system, indicating data entry errors or synchronization issues. This is a critical MDM issue.

**Example**:
```sql
-- Customer Service record for UserID 3586:
INSERT INTO cs.customerservicerequests (..., userid, firstname, lastname, ...)
VALUES (822950, 3586, 'Bobby', 'Vamderheydem', ...);

-- User Service record for UserID 3586:
INSERT INTO usr.users (userid, firstname, lastname, ...)
VALUES (3586, 'Bobby', 'Vanderheyden', ...);
```

**Discrepancy**: "Vamderheydem" vs "Vanderheyden" - This is a typo/data entry error.

**Impact**:
- Customer service agents may not find the correct user
- Reports and analytics have inconsistent customer data
- Legal compliance issues (incorrect name records)
- Loss of trust in master data
- Difficulty in customer matching across systems

**Suggested Resolution**:
- Implement MDM Hub to establish single source of truth for customer data
- Add data validation at entry point in CS system (lookup against usr.users)
- Create nightly reconciliation job to identify and flag discrepancies
- Train CS staff to verify customer information from authoritative source

**Data Quality Rule** (Business Terms):
*"A customer's name in any system must exactly match the name in the User Service system of record"*

**Measurable Metric**:
`Count of customer service requests where customer name does not match User Service = COUNT of cs.CustomerServiceRequests WHERE (FirstName <> usr.users.FirstName OR LastName <> usr.users.LastName) for same UserID`

**Monitoring Query**:
```sql
SELECT
  COUNT(*) as name_mismatch_count,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM cs.customerservicerequests), 2) as mismatch_percentage
FROM cs.customerservicerequests cs
JOIN usr.users u ON cs.userid = u.userid
WHERE cs.firstname <> u.firstname
   OR cs.lastname <> u.lastname;
```

---

### CURRENT ISSUE #3: Invalid/Nonsensical Data Values

**Table**: li.listings
**Column**: Size
**Dimension**: Validity, Accuracy

**Description**:
Shoe size contains invalid value '0' which is not a valid shoe size for any age group. Valid shoe sizes typically range from infant (0.5-2) to adult (3-20).

**Example**:
```sql
-- Row 1730: Size is '0' which is invalid
INSERT INTO li.listings (..., size, ...)
VALUES (780492, 87739, 4655, NULL, 'New Balance', 'brown', 'M', '0', 'Open Box', ...);

-- Row 1731: Size is '0' which is invalid
INSERT INTO li.listings (..., size, ...)
VALUES (351716, 92916, 4655, 'Sandals or Flip Flops', 'New Balance', 'brown', 'M', '0', ...);
```

**Impact**:
- Customers searching for specific sizes won't find these items
- Items may not sell due to invalid size information
- Inventory reporting is inaccurate
- Potential buyer dissatisfaction if they purchase thinking it's a real size

**Suggested Resolution**:
- Implement dropdown/validation list for size entry (application-level constraint)
- Add CHECK constraint to database: `CHECK (Size::NUMERIC BETWEEN 0.5 AND 22)`
- Investigate and correct existing '0' values by checking source data in im.Items
- Create reference table of valid sizes by gender/age group

**Data Quality Rule** (Business Terms):
*"Every shoe listing must have a valid size between 0.5 and 22 to ensure accurate product information"*

**Measurable Metric**:
`Count of listings with invalid shoe sizes = COUNT of listings WHERE Size NOT IN (valid size range) OR Size = '0'`

**Monitoring Query**:
```sql
SELECT
  COUNT(*) as invalid_size_count,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM li.listings), 2) as invalid_percentage
FROM li.listings
WHERE Size = '0'
   OR Size::NUMERIC NOT BETWEEN 0.5 AND 22
   OR Size !~ '^[0-9]+(\\.5)?$'; -- regex for valid format
```

---

### CURRENT ISSUE #4 (BONUS): Missing Arrival Date for Inventory Items

**Table**: im.Items
**Column**: ArrivalDate
**Dimension**: Completeness, Timeliness

**Description**:
Some items in the warehouse inventory are missing arrival dates, making it impossible to track the 45-day listing deadline. Per business rules, items must be listed within 45 days or returned to seller.

**Example**:
```sql
-- Row 527: ArrivalDate is NULL
INSERT INTO im.items (itemid, itemname, sellerid, type, brandname, color, size, sex, condition, itemstatus, arrivaldate)
VALUES (46646, 'Fae', 99173, 'Sneakers', 'LeBron', 'black', '7', 'Male', 'like new', 'approved', NULL);
```

**Impact**:
- Cannot enforce 45-day listing rule
- Risk of holding inventory indefinitely
- Cannot calculate seller invoices for unreturned items
- Warehouse space management issues
- Compliance failure with business policy

**Suggested Resolution**:
- Make ArrivalDate mandatory at warehouse receipt (application requirement)
- Auto-populate ArrivalDate with current timestamp when ItemStatus = 'received'
- Backfill NULL values with earliest possible date from shipping logs
- Create alert system for items approaching 45-day limit

**Data Quality Rule** (Business Terms):
*"Every item received at the warehouse must have an arrival date recorded to track the 45-day listing deadline"*

**Measurable Metric**:
`Percentage of items with missing arrival date = (COUNT of items where ArrivalDate IS NULL / COUNT of all items) × 100`

**Monitoring Query**:
```sql
SELECT
  COUNT(*) FILTER (WHERE ArrivalDate IS NULL) as missing_date_count,
  COUNT(*) as total_items,
  ROUND(100.0 * COUNT(*) FILTER (WHERE ArrivalDate IS NULL) / COUNT(*), 2) as missing_percentage
FROM im.items;
```

---

## FUTURE/POTENTIAL ISSUE: Duplicate User Accounts

**Table**: usr.users
**Column**: Email, FirstName, LastName
**Dimension**: Uniqueness

**Description**:
There is a risk of users creating multiple accounts with slight variations in email addresses or names, leading to duplicate customer records. This could happen through typos, use of multiple email addresses, or intentional fraud.

**Potential Example**:
```sql
-- Same person, different email providers
UserID: 12345, Name: 'John Smith', Email: 'john.smith@gmail.com'
UserID: 67890, Name: 'John Smith', Email: 'john.smith@yahoo.com'

-- Same person, slight name variation
UserID: 11111, Name: 'Robert Johnson', Email: 'rjohnson@email.com'
UserID: 22222, Name: 'Rob Johnson', Email: 'rob.johnson@email.com'
```

**Impact**:
- Fragmented customer purchase history
- Difficulty in fraud detection
- Inaccurate customer analytics and reporting
- Potential abuse of new user promotions
- MDM challenges in creating golden customer records

**Suggested Resolution**:
- Implement email uniqueness constraint (already exists via UserID as PK, but enforce at app level)
- Add duplicate detection algorithm at registration (fuzzy name matching + address matching)
- Implement multi-factor authentication to verify identity
- Create periodic reconciliation job to identify potential duplicates
- Establish MDM customer matching rules (covered in Part 6)

**Data Quality Rule** (Business Terms):
*"Each person should have only one user account to maintain accurate customer history and prevent fraud"*

**Measurable Metric**:
`Count of potential duplicate users = COUNT of user pairs WHERE (same email domain + similar name) OR (same address + similar name) OR (same phone pattern)`

**Monitoring Query**:
```sql
-- Find users with same first/last name and similar addresses
SELECT
  COUNT(*) as potential_duplicate_count
FROM (
  SELECT
    firstname, lastname, zipcode, COUNT(*) as account_count
  FROM usr.users
  GROUP BY firstname, lastname, zipcode
  HAVING COUNT(*) > 1
) subq;

-- Find users with very similar email patterns (same prefix before @)
SELECT
  COUNT(*) as similar_email_count
FROM (
  SELECT
    SPLIT_PART(email, '@', 1) as email_prefix,
    COUNT(DISTINCT userid) as user_count
  FROM usr.users
  GROUP BY SPLIT_PART(email, '@', 1)
  HAVING COUNT(DISTINCT userid) > 1
) subq;
```

---

## Additional Data Quality Observations

### Inconsistent Naming Conventions
- **Brand names**: "Johnston and Murphy" (li.listings) vs "Johnston & Murphy" (im.Items)
- **Gender/Sex**: "Gender" (CHAR(1) 'M'/'F') in listings vs "Sex" (VARCHAR(10) 'Male'/'Female') in items
- **Brand spacing**: "NewBalance" vs "New Balance"
- **Condition values**: Different capitalization and terminology across systems

### Data Denormalization Issues
- CustomerServiceRequests contains FirstName, LastName, Email which duplicate usr.users
- This creates data consistency risks as seen in Issue #2

### Missing Foreign Key Constraints
- im.Items.SellerID does not have FK constraint to usr.users
- li.listings.ProductID does not have FK constraint to im.Items.ItemID
- cs.CustomerServiceRequests.UserID and OrderID do not have FK constraints

### Isolation Risks
- Inventory Management and Customer Service systems are isolated with batch exports
- Risk of stale data and synchronization delays
- Potential for orphaned records

---

## Summary of Data Quality Rules and Metrics

| Issue | Table | Column | DQ Rule | Metric |
|-------|-------|--------|---------|--------|
| Missing ShoeType | li.listings | ShoeType | Every listing must have shoe type | % NULL ShoeType |
| Name Inconsistency | cs.CustomerServiceRequests | FirstName, LastName | Name must match User Service | Count of mismatches |
| Invalid Size | li.listings | Size | Size must be 0.5-22 | Count of invalid sizes |
| Missing ArrivalDate | im.Items | ArrivalDate | Every item must have arrival date | % NULL ArrivalDate |
| Duplicate Accounts | usr.users | Email, Name, Address | One account per person | Count of potential duplicates |

---

*These data quality issues will be monitored via the dashboard created in Part 4 and addressed through the MDM initiative in Part 5.*
