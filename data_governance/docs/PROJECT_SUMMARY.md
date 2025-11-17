# SneakerPark Data Governance Project - Summary and Deliverables

## Project Completion Status

### ✅ Completed Deliverables

All required components have been created and documented. Below is a summary of each deliverable and where to find it.

---

## Part 1: Enterprise Conceptual Data Model ✅

**File**: [enterprise_data_model.md](enterprise_data_model.md)

**What's Included**:
- Complete ERD using Mermaid diagram with Crow's Foot notation
- All 8 entities with attributes
- Cardinality and optionality for all relationships
- Detailed relationship descriptions
- Business rules reflected in the model
- System mapping (schemas to entities)

**How to Use**:
1. Copy the Mermaid diagram code from the file
2. Paste into [Mermaid Live Editor](https://mermaid.live) or any Mermaid renderer
3. Export as PNG or SVG
4. Insert into your project template (Step 1)

**Entities Included**:
- USER (Customer master)
- CREDIT_CARD (Payment methods)
- LISTING (Marketplace offerings)
- ORDER (Purchase transactions)
- ORDER_ITEM (Line items)
- ORDER_SHIPMENT (Delivery tracking)
- ITEM (Warehouse inventory)
- CUSTOMER_SERVICE_REQUEST (Support tickets)

---

## Part 2: Enterprise Data Catalog ⚠️ IN PROGRESS

**Source File**: [extract_metadata.md](extract_metadata.md)

**Excel File**: `sneakerpark-templates.xlsx` (YOU NEED TO COMPLETE THIS)

### What You Need to Do:

The metadata has been extracted and documented in `extract_metadata.md`. You need to transfer this information to the Excel file.

#### **Tab 1: Data Dictionary**

For EACH of the 8 tables, fill out these columns:

| Column in Excel | Where to Find the Data | Example |
|----------------|------------------------|---------|
| Schema Name | Check SQL: usr, li, op, im, cs | usr |
| Table Name | Check SQL: users, listings, etc. | users |
| Column Name | From CREATE TABLE statements | UserID |
| Data Type | From CREATE TABLE (include length!) | INT or VARCHAR(50) |
| Nullable | NOT NULL or NULL | NOT NULL |
| Primary Key | Check PRIMARY KEY constraint | Yes |
| Foreign Key | Check FOREIGN KEY constraints | No |
| Description | From extract_metadata.md | Unique identifier for user account |

**Tables to Document** (all 8):
1. usr.users (6 columns)
2. usr.creditcards (4 columns)
3. li.listings (13 columns)
4. op.Orders (10 columns)
5. op.OrderItems (3 columns)
6. op.OrderShipments (5 columns)
7. im.Items (11 columns)
8. cs.CustomerServiceRequests (11 columns)

**Total**: ~63 rows (one per column across all tables)

#### **Tab 2: Business Metadata**

For EACH of the 8 tables, fill out:

| Column in Excel | Value | Source |
|----------------|-------|--------|
| Schema | usr, li, op, im, cs | SQL file |
| Table Name | users, listings, etc. | SQL file |
| Business Name | User Accounts, Active Listings, etc. | extract_metadata.md |
| Description | Detailed business description | extract_metadata.md |
| Subject Area | Customers, Inventory, Listings, Orders | extract_metadata.md |
| Data Classification | Confidential, Internal, etc. | extract_metadata.md |
| Retention Period | 7 years, 2 years, etc. | extract_metadata.md + INSTRUCTIONS.md |
| Data Owner | User Service team, etc. | extract_metadata.md |
| Update Frequency | Real-time, Batch, etc. | extract_metadata.md |
| Source System | User Service, Listing Service, etc. | extract_metadata.md |

**All information is in [extract_metadata.md](extract_metadata.md) - just copy it into the Excel file.**

---

## Part 3: Data Quality Issues ✅

**Analysis File**: [data_quality_analysis.md](data_quality_analysis.md)

**Excel File**: `sneakerpark-templates.xlsx` → "Data Quality Issues" tab (YOU NEED TO COMPLETE THIS)

### What You Need to Do:

Transfer the 5 data quality issues to the Excel file:

#### Issue 1: Missing ShoeType
- **Existing Issue**: Yes
- **Table**: li.listings
- **Column**: ShoeType
- **Issue**: NULL values in ShoeType column
- **Dimension**: Completeness
- **Description**: The ShoeType column contains NULL values despite being important product information for buyers
- **Example**: ListingID 922399 has ShoeType = NULL
- **Suggested Resolution**: Make ShoeType required, backfill from im.Items.Type
- **Data Quality Rule**: "Every listing must have a shoe type specified to help customers find the right product"
- **Metric**: Percentage of listings with NULL ShoeType = (COUNT NULL / COUNT all) × 100

#### Issue 2: Name Mismatches
- **Existing Issue**: Yes
- **Table**: cs.CustomerServiceRequests
- **Column**: LastName, FirstName
- **Issue**: Customer names don't match User Service system
- **Dimension**: Consistency, Accuracy
- **Description**: Customer names in CS system do not match usr.users
- **Example**: UserID 3586: "Vamderheydem" vs "Vanderheyden"
- **Suggested Resolution**: Implement MDM Hub, add validation, reconciliation job
- **Data Quality Rule**: "A customer's name in any system must exactly match the name in the User Service system of record"
- **Metric**: Count of mismatches WHERE cs.firstname <> usr.firstname OR cs.lastname <> usr.lastname

#### Issue 3: Invalid Sizes
- **Existing Issue**: Yes
- **Table**: li.listings
- **Column**: Size
- **Issue**: Invalid size value '0'
- **Dimension**: Validity, Accuracy
- **Description**: Shoe size contains invalid value '0' which is not a valid shoe size
- **Example**: ListingID 780492 has Size = '0'
- **Suggested Resolution**: Implement dropdown validation, CHECK constraint (0.5-22)
- **Data Quality Rule**: "Every shoe listing must have a valid size between 0.5 and 22 to ensure accurate product information"
- **Metric**: Count of invalid sizes WHERE Size = '0' OR Size NOT BETWEEN 0.5 AND 22

#### Issue 4: Missing ArrivalDate
- **Existing Issue**: Yes
- **Table**: im.Items
- **Column**: ArrivalDate
- **Issue**: Missing arrival dates prevent 45-day rule enforcement
- **Dimension**: Completeness, Timeliness
- **Description**: Some items missing arrival dates, can't track 45-day deadline
- **Example**: ItemID 46646 has ArrivalDate = NULL
- **Suggested Resolution**: Make mandatory, auto-populate, backfill from logs
- **Data Quality Rule**: "Every item received at the warehouse must have an arrival date recorded to track the 45-day listing deadline"
- **Metric**: Percentage of items with NULL ArrivalDate = (COUNT NULL / COUNT all) × 100

#### Issue 5: Duplicate Accounts (FUTURE)
- **Existing Issue**: No (POTENTIAL FUTURE)
- **Table**: usr.users
- **Column**: Email, FirstName, LastName, Address
- **Issue**: Risk of users creating multiple accounts
- **Dimension**: Uniqueness
- **Description**: Potential for duplicate customer records through typos or fraud
- **Example**: Same person with different emails (john.smith@gmail vs john.smith@yahoo)
- **Suggested Resolution**: Email uniqueness, duplicate detection at registration, MDM matching
- **Data Quality Rule**: "Each person should have only one user account to maintain accurate customer history and prevent fraud"
- **Metric**: Count of potential duplicates (same name + zipcode OR same email prefix)

**All details are in [data_quality_analysis.md](data_quality_analysis.md)**

---

## Part 4: Data Quality Dashboard ✅

**File**: [data_quality_dashboard.md](data_quality_dashboard.md)

**What's Included**:
- Mermaid diagram mockup (copy-paste into Mermaid renderer)
- ASCII/text-based dashboard layout (ready to use)
- SQL queries for all 5 metrics
- Dashboard features and recommendations
- Suggested tool: Apache Superset (open source)

**How to Use**:
1. Choose either the Mermaid diagram OR the ASCII layout
2. Copy into your project template (Step 4)
3. Optionally: Create actual dashboard using Apache Superset or similar tool

**Metrics Included**:
1. Missing ShoeType (15.2% - Critical)
2. Name Mismatches (3.8% - Warning)
3. Invalid Sizes (0.2% - Good)
4. Missing ArrivalDate (8.7% - Critical)
5. Duplicate Accounts (0.08% - Good)

---

## Part 5: MDM Architecture ✅

**File**: [mdm_architecture.md](mdm_architecture.md)

**What's Included**:
- Mermaid architecture diagram (Hybrid MDM approach)
- Detailed explanation of WHY Hybrid was chosen
- Analysis of why NOT Registry, Centralized, or Consolidation alone
- Component descriptions (Centralized + Registry + Integration layers)
- Phased implementation plan (5 phases over 12 months)
- Technology recommendations
- Success metrics and risk mitigation

**Recommended MDM Style**: **HYBRID**
- Centralized for Customer data (golden records)
- Registry for Item cross-references
- Dual integration: Real-time for critical systems, Batch for isolated systems

**How to Use**:
1. Copy Mermaid diagram into renderer, export as image
2. Copy written explanation into project template (Step 5)

**Key Justification**:
- Minimally disruptive to Order Processing (99.999% uptime)
- Addresses customer data quality issues
- Maintains performance for item lookups
- Scalable and pragmatic

---

## Part 6: Matching Rules ✅

**File**: [matching_rules.md](matching_rules.md)

**What's Included**:
- 4 detailed matching rules (2 for Customers, 2 for Items)
- Examples with actual data from SQL file
- Confidence levels and scoring
- SQL implementation queries
- Stewardship actions for each rule

**Matching Rules**:

### Customer Rules:
1. **Email and Name Match**: Same email + 90%+ name similarity → High confidence (95-100%)
2. **Address and Phone Match**: Same zipcode + address similarity + phone → Medium-High (85-95%)

### Item Rules:
3. **Physical Characteristics Match**: Brand + Color + Size + Condition → High confidence (95-100%)
4. **Seller and Item ID Match**: ItemID = ProductID + SellerID + timeline → Very High (98-100%)

**How to Use**:
Copy descriptions and examples into project template (Step 6)

---

## Part 7: Governance Roles ✅

**File**: [governance_roles.md](governance_roles.md)

**What's Included**:
- Detailed discussion of roles across 6 governance aspects
- Analysis of current staff capabilities (Jake, Jessica)
- Hiring recommendations
- Organizational structure
- Success metrics

**Governance Aspects Covered**:
1. **Data Quality Management**: CDO, DQ Manager, Data Stewards
2. **Master Data Management**: MDM Architect, MDM Administrator
3. **Metadata Management**: Data Catalog Manager, Metadata Stewards
4. **Data Architecture**: Enterprise Data Architect
5. **Data Security/Compliance**: Data Privacy Officer
6. **Data Governance Council**: Cross-functional oversight

**Current Staff Assessment**:
- **Jessica**: Promote to Data Quality Manager ✅
- **Jake**: Train as MDM Administrator ✅
- **New Hires Needed**: CDO, MDM Architect, Data Quality Analyst, Enterprise Architect, Privacy Officer

**How to Use**:
Copy the 1-2 paragraph summary (or full document) into project template (Step 7)

---

## Standout Deliverables ✅

### Standout 1: Business Glossary ✅

**File**: [business_glossary.md](business_glossary.md)

**What's Included**:
- 30+ business terms with definitions
- Related terms and synonyms
- System field mappings
- Business rules
- Inconsistency analysis
- Recommendations for standardization

**Key Terms Defined**:
- Account, Buyer, Seller, Customer
- Item, Listing, Order
- Authentication, Condition, Brand
- Golden Record, MDM concepts
- And many more...

**How to Use**:
Optionally transfer to Excel "Business Glossary" tab, or submit as markdown

---

### Standout 2: Naming Conventions ✅

**File**: [naming_conventions.md](naming_conventions.md)

**What's Included**:
- Current state analysis (inconsistencies identified)
- Recommended conventions for schemas, tables, columns
- Data type standards
- Constraint naming patterns
- Before/After examples
- Implementation roadmap (don't break existing systems!)
- Checklist for new development

**Key Recommendations**:
- Use `lowercase_with_underscores` (not PascalCase)
- Tables: plural nouns (users, orders)
- Columns: singular descriptive (user_id, first_name)
- IDs: end with `_id`
- Dates: end with `_date` or `_timestamp`
- Booleans: start with `is_` or `has_`

**How to Use**:
Optionally transfer to Excel "Standard Naming Conventions" tab, or submit as markdown

---

## Files Created - Complete List

### Core Deliverables:
1. ✅ **INSTRUCTIONS.md** - Complete project requirements and approach
2. ✅ **enterprise_data_model.md** - ERD with Crow's Foot notation (Part 1)
3. ✅ **extract_metadata.md** - Metadata for Data Catalog (Part 2 source)
4. ✅ **data_quality_analysis.md** - 5 DQ issues with details (Part 3)
5. ✅ **data_quality_dashboard.md** - Dashboard mockup (Part 4)
6. ✅ **mdm_architecture.md** - Hybrid MDM design and explanation (Part 5)
7. ✅ **matching_rules.md** - 4 matching rules with examples (Part 6)
8. ✅ **governance_roles.md** - Roles and responsibilities (Part 7)

### Standout Deliverables:
9. ✅ **business_glossary.md** - 30+ terms defined (Standout 1)
10. ✅ **naming_conventions.md** - Standards and recommendations (Standout 2)

### Supporting Files:
11. ✅ **PROJECT_SUMMARY.md** - This file, project overview

---

## Next Steps - What YOU Need to Do

### 1. Complete the Excel File ⚠️ REQUIRED

**File**: `sneakerpark-templates.xlsx`

**Tabs to Fill**:

#### ✅ Tab: "Data Dictionary"
- Use [extract_metadata.md](extract_metadata.md) as source
- Fill all 8 tables × ~8 columns each = ~63 rows
- Include: Schema, Table, Column, Data Type, Nullable, PK, FK, Description

#### ✅ Tab: "Business Metadata"
- Use [extract_metadata.md](extract_metadata.md) as source
- Fill all 8 tables = 8 rows
- Include: Schema, Table, Business Name, Description, Subject Area, Classification, Retention, Owner, Frequency, Source System

#### ✅ Tab: "Data Quality Issues"
- Use [data_quality_analysis.md](data_quality_analysis.md) as source
- Fill 5 issues (4 existing + 1 future)
- Include: Existing Issue?, Table, Column, Issue, Dimension, Description, Example, Resolution, DQ Rule, Metric

#### Optional Tabs (Standout):

#### ⭐ Tab: "Business Glossary"
- Use [business_glossary.md](business_glossary.md) as source
- Select key terms to include (at least 10-15)

#### ⭐ Tab: "Standard Naming Conventions"
- Use [naming_conventions.md](naming_conventions.md) as source
- Document current conventions and recommended changes

**Time Estimate**: 2-3 hours to complete Excel file

---

### 2. Complete the PowerPoint Template

**File**: `starter-template.pptx`

Insert the following into each step:

#### Step 1: Enterprise Data Model
- Export Mermaid diagram from [enterprise_data_model.md](enterprise_data_model.md) as PNG
- Insert image into PowerPoint
- Optionally add brief description

#### Step 4: Data Quality Dashboard
- Export Mermaid diagram OR use ASCII layout from [data_quality_dashboard.md](data_quality_dashboard.md)
- Insert into PowerPoint
- Include note about recommended tool (Apache Superset)

#### Step 5: MDM Architecture
- Export Mermaid diagram from [mdm_architecture.md](mdm_architecture.md) as PNG
- Insert diagram
- Copy written explanation (summary version or full text)

#### Step 6: Matching Rules
- Copy the 4 matching rules from [matching_rules.md](matching_rules.md)
- Format as bullet points or table
- Include confidence levels

#### Step 7: Governance Roles
- Copy 1-2 paragraph summary from [governance_roles.md](governance_roles.md)
- Mention: DQ Management, MDM, Metadata Management aspects
- State hiring recommendations (CDO, MDM Architect, promote Jessica, train Jake)

**Time Estimate**: 1-2 hours to complete PowerPoint

---

### 3. Review and Validate

#### Checklist:
- [ ] All 8 tables documented in Data Dictionary
- [ ] All 8 tables documented in Business Metadata
- [ ] 5 data quality issues documented (4 existing + 1 future)
- [ ] ERD includes all entities with cardinality and optionality
- [ ] Dashboard mockup shows all 5 metrics clearly labeled
- [ ] MDM architecture diagram shows Hybrid approach
- [ ] MDM explanation covers WHY Hybrid was chosen
- [ ] 4 matching rules defined (2 Customer, 2 Item)
- [ ] Governance discussion covers 3+ aspects
- [ ] Governance discussion addresses hiring needs
- [ ] (Optional) Business Glossary completed
- [ ] (Optional) Naming Conventions documented

---

## How to Render Mermaid Diagrams

All diagrams are in Mermaid format for easy copy-paste:

### Option 1: Mermaid Live Editor (Recommended)
1. Go to https://mermaid.live
2. Copy diagram code from .md file
3. Paste into editor (left side)
4. Diagram renders on right side
5. Click "Actions" → "PNG" or "SVG" to export

### Option 2: VS Code Extension
1. Install "Markdown Preview Mermaid Support" extension
2. Open .md file in VS Code
3. Click "Preview" button
4. Right-click diagram → Save as image

### Option 3: GitHub
1. Push .md file to GitHub repository
2. GitHub automatically renders Mermaid diagrams
3. View file and take screenshot

---

## Quality Assurance

### Self-Check Questions:

1. **Completeness**: Did I fill out ALL required fields in the Excel file?
2. **Accuracy**: Did I use the actual data from the SQL file (not hallucinated values)?
3. **Consistency**: Do my table/column names match the SQL file exactly?
4. **Clarity**: Are my diagrams clearly labeled and readable?
5. **Specificity**: Is my MDM explanation specific to SneakerPark (not generic)?
6. **Justification**: Did I explain WHY I chose Hybrid MDM?
7. **Realism**: Are my matching rules realistic and executable?
8. **Practicality**: Are my governance recommendations realistic for SneakerPark's size?

---

## Rubric Alignment

### Enterprise Data Catalog ✅
- [x] E-R Diagram with Crow's Foot Notation
- [x] Cardinality and Optionality specified
- [x] All important entities and relationships
- [x] Entities clearly labeled
- [ ] Data Dictionary completely filled (YOU DO THIS)
- [ ] Business Metadata completely filled (YOU DO THIS)
- [x] All 8 tables covered

### Data Quality Management ✅
- [x] 3+ existing issues profiled
- [x] 1+ potential future issue
- [x] Description and example for each
- [x] Concrete resolution for each
- [x] Data quality rule in business terms
- [x] Measurable metric for each
- [x] Dashboard mockup with metrics labeled

### MDM Architecture ✅
- [x] MDM architecture diagram (Hybrid)
- [x] Written explanation specific to SneakerPark
- [x] 4 matching rules (2 Items, 2 Customers)
- [x] Rules are realistic and unique

### Governance ✅
- [x] 1-2 paragraph discussion
- [x] Cover 3+ governance aspects
- [x] Discuss hiring needs
- [x] Specific to SneakerPark

### Standout ⭐
- [x] Business Glossary created
- [x] Naming Conventions documented

---

## Estimated Time to Complete

- **Excel Data Dictionary**: 1-2 hours
- **Excel Business Metadata**: 30 minutes
- **Excel Data Quality Issues**: 30 minutes
- **PowerPoint Assembly**: 1-2 hours
- **Review and Polish**: 30 minutes

**Total**: ~4-5 hours to finalize submission

---

## Final Submission Checklist

- [ ] `sneakerpark-templates.xlsx` - Fully completed with all tabs
- [ ] `starter-template.pptx` - All steps filled with diagrams and text
- [ ] All diagrams exported and inserted into PowerPoint
- [ ] Reviewed for typos and formatting
- [ ] Verified all table/column names match SQL file exactly
- [ ] Checked that no data values were hallucinated

---

## Support Files

All markdown files can be submitted as supplementary documentation:
- They contain full details and examples
- They show your thorough analysis
- They demonstrate depth of understanding
- Reviewers can reference them for context

---

## Congratulations!

You have completed a comprehensive Enterprise Data Management project for SneakerPark, including:

✅ Enterprise Data Model with full E-R diagram
✅ Metadata extraction and cataloging
✅ Data quality profiling and issue identification
✅ Data quality monitoring dashboard
✅ Hybrid MDM architecture with detailed justification
✅ Matching rules for golden records
✅ Governance roles and organizational structure
✅ Business glossary for terminology standardization
✅ Naming conventions for future development

This project provides a solid foundation for SneakerPark's Phase 1 Enterprise Data Management initiative and prepares them for Phase 2 (Enterprise Data Warehouse).

**Great work! Now complete the Excel file and submit!** 🎉

---

*Created for SneakerPark Data Governance Project - Udacity Data Architecture Nanodegree*
