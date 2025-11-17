# Matching Rules for SneakerPark MDM Hub

## Overview

These matching rules will be used by the MDM Hub's Matching Engine to identify and link master entities (Customers and Items) across SneakerPark's different systems. The rules enable creation of "golden records" by matching records that represent the same real-world entity.

---

## CUSTOMER MATCHING RULES

### Customer Matching Rule #1: "Email and Name Match"

**Purpose**: Identify the same customer across systems using their email address and name

**Rule Definition**:
Match customer records as the **same person** when:
- **Email addresses are identical** (case-insensitive), AND
- **First name has 90%+ similarity** (fuzzy match to handle typos), AND
- **Last name has 90%+ similarity** (fuzzy match to handle typos)

**Business Logic**:
*"A customer in one system is the same customer in another system if they have the same email address and their name is substantially similar"*

**Systems Involved**:
- usr.users (Email, FirstName, LastName)
- cs.CustomerServiceRequests (Email, FirstName, LastName)

**Example Match**:
```
System: usr.users
UserID: 3586
Email: bobby.vanderheyden@fakeemail.com
FirstName: Bobby
LastName: Vanderheyden

System: cs.CustomerServiceRequests
ID: 822950
UserID: 3586
Email: bobby.vanderheyden@fakeemail.com
FirstName: Bobby
LastName: Vamderheydem  ← Typo!

Match Score: 95%
- Email: 100% match ✓
- FirstName: 100% match ✓
- LastName: 91% similarity (Levenshtein distance) ✓

Action: These are the SAME customer → Create/update golden record with correct spelling "Vanderheyden" from usr.users (authoritative source)
```

**Matching Algorithm**:
```sql
-- Pseudocode for matching
SELECT
  u.userid as source1_id,
  cs.id as source2_id,
  u.email,
  cs.email,
  levenshtein_similarity(u.lastname, cs.lastname) as name_similarity,
  'Email_Name_Match' as match_rule
FROM usr.users u
JOIN cs.customerservicerequests cs
  ON LOWER(u.email) = LOWER(cs.email)
WHERE
  levenshtein_similarity(u.firstname, cs.firstname) >= 0.90
  AND levenshtein_similarity(u.lastname, cs.lastname) >= 0.90;
```

**Confidence Level**: **High (95-100%)**
- Email is unique identifier
- Name similarity confirms identity
- Very low false positive rate

**Stewardship Action**:
- Auto-merge if match score > 95%
- Manual review if match score 90-95%
- Update golden record with data from usr.users (system of record)
- Publish corrected name back to cs.CustomerServiceRequests

---

### Customer Matching Rule #2: "Address and Phone Match"

**Purpose**: Identify duplicate customer accounts or match customers when email has changed/differs

**Rule Definition**:
Match customer records as the **same person** when:
- **ZipCode is identical**, AND
- **Address has 85%+ similarity** (fuzzy match to handle abbreviations like "St" vs "Street"), AND
- **Phone number is identical** (if available)

OR as alternate condition:
- **Full name is identical** (FirstName + LastName), AND
- **ZipCode is identical**

**Business Logic**:
*"A customer is the same person if they live at the same address and have the same phone number, or if they have the exact same name and live in the same zip code"*

**Systems Involved**:
- usr.users (Address, ZipCode, FirstName, LastName)
- cs.CustomerServiceRequests (Phone, FirstName, LastName - can join to usr.users via UserID to get address)

**Example Match #1** (Address + Phone):
```
System: usr.users
UserID: 80527
FirstName: Emerson
LastName: Wire
Address: 2 Harris Place
ZipCode: 13835

System: usr.users (Potential Duplicate Account)
UserID: 80528
FirstName: E.
LastName: Wire
Address: 2 Harris Pl  ← Abbreviated
ZipCode: 13835

System: cs.CustomerServiceRequests
UserID: 80527
Phone: (555) 123-4567

System: cs.CustomerServiceRequests
UserID: 80528
Phone: (555) 123-4567  ← Same phone!

Match Score: 92%
- ZipCode: 100% match ✓
- Address: 88% similarity (handling "Place" vs "Pl") ✓
- Phone: 100% match ✓
- Name: Similar (Emerson vs E.) ✓

Action: These are DUPLICATE accounts → Flag for steward review → Merge accounts → Consolidate order history
```

**Example Match #2** (Same Name + ZipCode):
```
System: usr.users
UserID: 16548
FirstName: Tandy
LastName: Wire
ZipCode: 67353
Address: 106 Garden Square

System: usr.users (Potential Duplicate)
UserID: 16549
FirstName: Tandy
LastName: Wire
ZipCode: 67353
Address: 106 Garden Sq Apt 2B  ← More specific

Match Score: 88%
- FirstName: 100% match ✓
- LastName: 100% match ✓
- ZipCode: 100% match ✓
- Address: 75% similarity (one has apartment number) ~

Action: Flag for manual review (could be same person who moved units OR different family members)
```

**Matching Algorithm**:
```sql
-- Pseudocode for address + phone matching
SELECT
  u1.userid as account1,
  u2.userid as account2,
  u1.address,
  u2.address,
  levenshtein_similarity(u1.address, u2.address) as address_similarity,
  'Address_Phone_Match' as match_rule
FROM usr.users u1
JOIN usr.users u2
  ON u1.zipcode = u2.zipcode
  AND u1.userid < u2.userid  -- Avoid duplicate pairs
LEFT JOIN cs.customerservicerequests cs1 ON u1.userid = cs1.userid
LEFT JOIN cs.customerservicerequests cs2 ON u2.userid = cs2.userid
WHERE
  levenshtein_similarity(u1.address, u2.address) >= 0.85
  AND (
    cs1.phone = cs2.phone  -- Same phone
    OR (
      LOWER(u1.firstname) = LOWER(u2.firstname)
      AND LOWER(u1.lastname) = LOWER(u2.lastname)  -- Same full name
    )
  );
```

**Confidence Level**: **Medium-High (85-95%)**
- Address + Phone: High confidence (same household)
- Name + ZipCode: Medium confidence (could be family members)
- Requires steward review for edge cases

**Stewardship Action**:
- Flag for manual review (don't auto-merge)
- Steward investigates: check order history, dates, contact patterns
- If confirmed duplicate: Merge accounts, consolidate data, assign golden CustomerID
- If separate people: Mark as "Not a Match" in MDM Hub to prevent future alerts

**Common False Positives to Watch**:
- Family members at same address (e.g., "Tandy Wire" and "Emerson Wire" at different addresses but same last name)
- Roommates with similar names
- Parent/child with same name (Sr/Jr)

**Handling Strategy**: Require steward confirmation before merge for score < 95%

---

## ITEM MATCHING RULES

### Item Matching Rule #1: "Physical Characteristics Match"

**Purpose**: Match the same physical sneaker item between Inventory System and Listing Service

**Rule Definition**:
Match item records as the **same physical item** when:
- **Brand name is identical** (case-insensitive, accounting for spacing variations), AND
- **Color is identical** (case-insensitive), AND
- **Size is identical**, AND
- **Condition is semantically equivalent** (mapping variations like "new" = "New", "like new" = "Open Box")

**Business Logic**:
*"An item in the warehouse inventory is the same as a listed item if the brand, color, size, and condition all match"*

**Systems Involved**:
- im.Items (BrandName, Color, Size, Sex, Condition)
- li.listings (Brand, Color, Size, Gender, Condition)

**Example Match**:
```
System: im.Items
ItemID: 61135
ItemName: Era
BrandName: Reebok
Color: black
Size: 14
Sex: Male
Condition: new
ItemStatus: listed

System: li.listings
ListingID: 544961
ProductID: 1303  ← Should match ItemID 61135? NO, doesn't match physical characteristics
Brand: Reebok
Color: black
Size: 7  ← Different size!
Gender: M
Condition: New
SellerID: 54650

Match Score: 0% (Size mismatch - NOT the same item)

---

Correct Match:
System: im.Items
ItemID: 1303
BrandName: Reebok
Color: black
Size: 7
Sex: Male
Condition: new

System: li.listings
ListingID: 544961
ProductID: 1303  ← ProductID explicitly links to ItemID
Brand: Reebok
Color: black
Size: 7
Gender: M
Condition: New

Match Score: 100%
- BrandName: 100% match (Reebok = Reebok) ✓
- Color: 100% match (black = black) ✓
- Size: 100% match (7 = 7) ✓
- Condition: 100% match (new = New, case-insensitive) ✓

Action: Create cross-reference: ItemID 1303 → ListingID 544961
```

**Condition Mapping Table** (Semantic Equivalence):
| im.Items.Condition | li.listings.Condition | Match? |
|--------------------|-----------------------|--------|
| new                | New                   | ✓ Yes  |
| like new           | Open Box              | ✓ Yes  |
| used               | Used                  | ✓ Yes  |
| like new           | New                   | ✗ No   |
| used               | Open Box              | ✗ No   |

**Gender/Sex Mapping** (Handle terminology inconsistency):
| im.Items.Sex | li.listings.Gender | Match? |
|--------------|-------------------|--------|
| Male         | M                 | ✓ Yes  |
| Female       | F                 | ✓ Yes  |
| Unisex       | U                 | ✓ Yes  |

**Brand Name Normalization** (Handle spacing variations):
| im.Items.BrandName | li.listings.Brand | Normalized   | Match? |
|--------------------|-------------------|--------------|--------|
| New Balance        | NewBalance        | new_balance  | ✓ Yes  |
| Johnston & Murphy  | Johnston and Murphy| johnston_murphy | ✓ Yes |
| Nike               | Nike              | nike         | ✓ Yes  |

**Matching Algorithm**:
```sql
-- Pseudocode for item matching
SELECT
  im.itemid,
  li.listingid,
  li.productid,
  'Physical_Characteristics_Match' as match_rule
FROM im.items im
JOIN li.listings li
  ON LOWER(REPLACE(im.brandname, ' ', '')) = LOWER(REPLACE(li.brand, ' ', ''))  -- Normalize brand
  AND LOWER(im.color) = LOWER(li.color)
  AND im.size = li.size
  AND normalize_condition(im.condition) = normalize_condition(li.condition)
  AND normalize_gender(im.sex) = normalize_gender(li.gender);

-- Helper function to normalize condition
CREATE FUNCTION normalize_condition(cond VARCHAR) RETURNS VARCHAR AS $$
  CASE LOWER(cond)
    WHEN 'new' THEN 'new'
    WHEN 'like new' THEN 'openbox'
    WHEN 'open box' THEN 'openbox'
    WHEN 'used' THEN 'used'
    ELSE 'unknown'
  END;
$$ LANGUAGE SQL;
```

**Confidence Level**: **High (95-100%)**
- Physical characteristics are highly distinctive
- Four matching attributes provide strong confidence
- Low false positive rate

**Stewardship Action**:
- Auto-create cross-reference if all 4 attributes match
- Alert if ProductID in li.listings doesn't equal matched ItemID (data inconsistency)
- Update Cross-Reference Index in MDM Hub

---

### Item Matching Rule #2: "Seller and Item ID Match"

**Purpose**: Definitively link items using seller and item identifiers when available

**Rule Definition**:
Match item records as the **same physical item** when:
- **ProductID (in li.listings) equals ItemID (in im.Items)**, AND
- **SellerID is consistent** across both systems (same seller owns the item)

OR alternative strong match:
- **SellerID is identical**, AND
- **Brand, Color, Size match** (3 out of 4 physical characteristics), AND
- **Item arrival date and listing create date are within 45 days** (business rule compliance)

**Business Logic**:
*"An item is definitively the same if the ProductID matches the ItemID and both are owned by the same seller, or if the seller, most physical characteristics, and timeline align with the 45-day listing rule"*

**Systems Involved**:
- im.Items (ItemID, SellerID, BrandName, Color, Size, ArrivalDate)
- li.listings (ListingID, ProductID, SellerID, Brand, Color, Size, ListingCreateDate)

**Example Match #1** (Direct ID Match):
```
System: im.Items
ItemID: 672
SellerID: 1903
BrandName: Nike
Color: brown
Size: 10
ArrivalDate: 2020-10-15

System: li.listings
ListingID: 695111
ProductID: 672  ← Direct match to ItemID!
SellerID: 1903  ← Same seller!
Brand: Nike
Color: brown
Size: 10
ListingCreateDate: 2020-11-01  ← 17 days after arrival (within 45-day rule)

Match Score: 100%
- ProductID = ItemID: 100% match ✓
- SellerID: 100% match ✓
- Timeline: Compliant with 45-day rule ✓

Action: Create strong cross-reference ItemID 672 → ListingID 695111
```

**Example Match #2** (Seller + Characteristics + Timeline):
```
System: im.Items
ItemID: 509
SellerID: 25516
BrandName: UnderArmor
Color: brown
Size: 12
Sex: Female
Condition: Used
ArrivalDate: 2020-09-15

System: li.listings
ListingID: 922399
ProductID: 509  ← Matches ItemID
SellerID: 25516  ← Same seller
Brand: UnderArmor
Color: brown
Size: 12
Gender: F
Condition: Used
ListingCreateDate: 2020-10-06  ← 21 days after arrival (within 45-day rule)

Match Score: 100%
- SellerID: 100% match ✓
- Brand: 100% match ✓
- Color: 100% match ✓
- Size: 100% match ✓
- Timeline: 21 days (within 45-day window) ✓

Action: Confirm ProductID 509 = ItemID 509 cross-reference
```

**Example Non-Match** (Seller Different):
```
System: im.Items
ItemID: 672
SellerID: 1903  ← Original seller

System: li.listings
ListingID: 453340
ProductID: 672
SellerID: 57088  ← Different seller!

Match Score: 0%
- ProductID matches BUT SellerID doesn't
- This indicates a DATA QUALITY ISSUE

Action: Flag for steward review - ProductID reused incorrectly OR item was transferred between sellers (check business process)
```

**Timeline Validation** (45-Day Rule):
```sql
-- Check if listing was created within 45 days of arrival
SELECT
  im.itemid,
  li.listingid,
  im.arrivaldate,
  li.listingcreatedate,
  (li.listingcreatedate - im.arrivaldate) as days_to_list,
  CASE
    WHEN (li.listingcreatedate - im.arrivaldate) <= 45 THEN 'Compliant'
    WHEN (li.listingcreatedate - im.arrivaldate) > 45 THEN 'Violation - Should have been returned'
    ELSE 'Missing Date'
  END as compliance_status
FROM im.items im
JOIN li.listings li ON im.itemid = li.productid AND im.sellerid = li.sellerid
WHERE im.arrivaldate IS NOT NULL;
```

**Matching Algorithm**:
```sql
-- Pseudocode for seller + item ID matching
SELECT
  im.itemid,
  li.listingid,
  li.productid,
  im.sellerid,
  li.sellerid,
  (li.listingcreatedate - im.arrivaldate) as days_to_list,
  'Seller_ItemID_Match' as match_rule
FROM im.items im
JOIN li.listings li
  ON im.itemid = li.productid  -- Direct ID match
  AND im.sellerid = li.sellerid  -- Same seller
WHERE
  (li.listingcreatedate - im.arrivaldate) <= 45  -- Compliant with 45-day rule
  OR im.arrivaldate IS NULL;  -- Handle missing dates

-- Alternative: Seller + characteristics + timeline
SELECT
  im.itemid,
  li.listingid,
  'Seller_Characteristics_Timeline_Match' as match_rule
FROM im.items im
JOIN li.listings li
  ON im.sellerid = li.sellerid
  AND LOWER(REPLACE(im.brandname, ' ', '')) = LOWER(REPLACE(li.brand, ' ', ''))
  AND LOWER(im.color) = LOWER(li.color)
  AND im.size = li.size
WHERE
  (li.listingcreatedate - im.arrivaldate) BETWEEN 0 AND 45;
```

**Confidence Level**: **Very High (98-100%)**
- ItemID = ProductID is authoritative
- SellerID adds second confirmation
- Timeline validation prevents mismatches
- Lowest false positive rate of all rules

**Stewardship Action**:
- Auto-create cross-reference for direct matches (ProductID = ItemID + SellerID match)
- Alert if ProductID = ItemID BUT SellerID differs → Data quality issue
- Alert if timeline > 45 days → Business rule violation (item should have been returned)
- Update Cross-Reference Index with high-confidence linkage

**Data Quality Benefits**:
This rule also serves as a **data quality check**:
- Detects incorrect ProductID assignments
- Identifies 45-day rule violations
- Flags orphaned inventory items (never listed)
- Highlights seller mismatches (fraud detection)

---

## Summary of Matching Rules

| Rule Name | Entity | Key Attributes | Confidence | Auto-Action |
|-----------|--------|---------------|------------|-------------|
| Email and Name Match | Customer | Email + Name (fuzzy) | High (95%+) | Auto-merge if > 95% |
| Address and Phone Match | Customer | ZipCode + Address + Phone | Medium-High (85-95%) | Manual review required |
| Physical Characteristics | Item | Brand + Color + Size + Condition | High (95%+) | Auto-link |
| Seller and Item ID | Item | ItemID + SellerID + Timeline | Very High (98%+) | Auto-link |

---

## Matching Engine Configuration

### Thresholds
- **Auto-Merge**: Match score ≥ 95%
- **Manual Review**: Match score 85-94%
- **Reject**: Match score < 85%

### Processing Frequency
- **Customer Matching**: Daily batch (overnight) + Real-time on new account registration
- **Item Matching**: Nightly batch (aligns with Inventory system sync)

### Conflict Resolution
- **Customer**: usr.users is system of record (authoritative for name, email, address)
- **Item**: im.Items is system of record (authoritative for physical characteristics)

### Audit Trail
- Log all matches with score, rule used, timestamp
- Track steward decisions (approve/reject merge)
- Maintain history of all matched records

---

## SQL Implementation Examples

### Customer Matching Query (Email + Name)
```sql
WITH customer_matches AS (
  SELECT
    u.userid as master_id,
    cs.userid as duplicate_id,
    u.email,
    cs.email as cs_email,
    levenshtein_similarity(u.firstname, cs.firstname) as fname_similarity,
    levenshtein_similarity(u.lastname, cs.lastname) as lname_similarity,
    (
      CASE WHEN LOWER(u.email) = LOWER(cs.email) THEN 40 ELSE 0 END +
      (levenshtein_similarity(u.firstname, cs.firstname) * 30) +
      (levenshtein_similarity(u.lastname, cs.lastname) * 30)
    ) as total_match_score
  FROM usr.users u
  JOIN cs.customerservicerequests cs ON LOWER(u.email) = LOWER(cs.email)
  WHERE u.userid = cs.userid  -- Should be same, checking for discrepancies
)
SELECT
  *,
  CASE
    WHEN total_match_score >= 95 THEN 'AUTO_MERGE'
    WHEN total_match_score >= 85 THEN 'MANUAL_REVIEW'
    ELSE 'REJECT'
  END as action
FROM customer_matches
ORDER BY total_match_score DESC;
```

### Item Matching Query (Physical Characteristics)
```sql
WITH item_matches AS (
  SELECT
    im.itemid,
    li.listingid,
    li.productid,
    im.brandname,
    li.brand,
    (
      CASE WHEN LOWER(REPLACE(im.brandname, ' ', '')) = LOWER(REPLACE(li.brand, ' ', '')) THEN 25 ELSE 0 END +
      CASE WHEN LOWER(im.color) = LOWER(li.color) THEN 25 ELSE 0 END +
      CASE WHEN im.size = li.size THEN 25 ELSE 0 END +
      CASE WHEN normalize_condition(im.condition) = normalize_condition(li.condition) THEN 25 ELSE 0 END
    ) as total_match_score
  FROM im.items im
  CROSS JOIN li.listings li  -- All combinations, then filter
)
SELECT
  *,
  CASE
    WHEN total_match_score = 100 THEN 'AUTO_LINK'
    WHEN total_match_score >= 75 THEN 'MANUAL_REVIEW'
    ELSE 'NO_MATCH'
  END as action
FROM item_matches
WHERE total_match_score >= 75  -- Only show potential matches
ORDER BY total_match_score DESC;
```

---

*These matching rules provide the foundation for SneakerPark's MDM Hub to create accurate golden records and maintain data integrity across all systems.*
