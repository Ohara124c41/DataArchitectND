# SneakerPark Business Glossary

## Purpose
This Business Glossary establishes common definitions for key business terms used across SneakerPark's systems and organization. Standardizing terminology improves communication, reduces misunderstandings, and ensures data consistency.

---

## Business Terms - Alphabetical

### Account
**Definition**: A registered user profile that enables a person to buy or sell sneakers on the SneakerPark platform.

**Synonyms**: User Account, Customer Account, Seller Account

**Related Terms**: User, Buyer, Seller

**System Fields**:
- usr.users (all columns)
- usr.users.UserID

**Business Rules**:
- All buyers and sellers must have an active account
- One person should have only one account (see Duplicate Account)
- Accounts are retained for 7 years unless customer requests deletion

**Notes**: SneakerPark uses "user" and "account" interchangeably in systems, but "account" is the preferred business term.

---

### Arrival Date
**Definition**: The date when a physical sneaker item is received and logged into SneakerPark's warehouse after being shipped by the seller.

**Synonyms**: Receipt Date, Warehouse Receipt Date

**Related Terms**: Item, Warehouse, Authentication, 45-Day Rule

**System Fields**:
- im.Items.ArrivalDate

**Business Rules**:
- Must be recorded upon warehouse receipt
- Triggers the 45-day countdown for listing requirement
- If NULL, item status should be tracked manually to avoid policy violations

**Notes**: Critical for tracking the 45-day listing deadline. Missing arrival dates are a current data quality issue.

---

### Auction
**Definition**: A listing type where sellers accept bids from buyers, and the item sells to the highest bidder.

**Synonyms**: Auction Listing, Bid Listing

**Related Terms**: Listing, Listing Type, Buy Now, Bid

**System Fields**:
- li.listings.ListingType = 'Auction'

**Business Rules**:
- Seller sets starting bid price
- Listing ends when auction period expires or seller accepts a bid
- Differs from "Fixed" pricing where buyer pays listed price immediately

---

### Authentication
**Definition**: The process by which SneakerPark verifies that a sneaker item is genuine (not counterfeit) and in acceptable condition before allowing it to be listed for sale.

**Synonyms**: Verification, Item Authentication, Product Verification

**Related Terms**: Item, Item Status, Warehouse, Condition

**System Fields**:
- im.Items.ItemStatus (values: 'approved', 'rejected', 'pending')

**Business Rules**:
- All items must be authenticated before listing
- Inauthentic or unacceptable items are returned to seller with shipping invoice
- SneakerPark authenticators examine brand markings, materials, stitching, and overall quality

**Notes**: Core differentiator for SneakerPark vs. other marketplaces. Ensures buyer confidence.

---

### Brand
**Definition**: The manufacturer or label name of a sneaker product (e.g., Nike, Adidas, Reebok).

**Synonyms**: Brand Name, Manufacturer, Make

**Related Terms**: Item, Listing, Shoe Type

**System Fields**:
- li.listings.Brand
- im.Items.BrandName

**Business Rules**:
- Should follow standardized naming (e.g., "New Balance" not "NewBalance")
- Brand is required for all listings and items
- Brands must be from SneakerPark's approved list (to prevent typos/misspellings)

**Inconsistencies**:
- System inconsistency: li.listings uses "Brand", im.Items uses "BrandName"
- Spacing inconsistency: "New Balance" vs "NewBalance", "Johnston & Murphy" vs "Johnston and Murphy"

**Recommended Standardization**: Use "Brand" across all systems with consistent spacing rules.

---

### Buyer
**Definition**: A user who purchases sneakers from SneakerPark's marketplace, either through bidding or direct purchase.

**Synonyms**: Customer, Purchaser

**Related Terms**: Seller, User, Order, Account

**System Fields**:
- op.Orders.BuyerID (references usr.users.UserID)

**Business Rules**:
- Must have active account
- Must provide valid payment method
- Can also be a seller (dual role)

**Notes**: In SneakerPark's marketplace, the same person can act as both buyer and seller, depending on the transaction.

---

### Buy Now / Fixed Price
**Definition**: A listing type where the seller sets a fixed price and the buyer can purchase immediately without bidding.

**Synonyms**: Fixed Price, Buy It Now, Instant Purchase

**Related Terms**: Listing, Listing Type, Auction

**System Fields**:
- li.listings.ListingType = 'Fixed'

**Business Rules**:
- Price is non-negotiable (unlike auction)
- First buyer to click "buy now" wins the item
- Transaction completes immediately upon purchase

---

### Condition
**Definition**: The physical state or quality of a sneaker item, describing wear level and completeness.

**Synonyms**: Item Condition, Product Condition

**Related Terms**: Item, Listing, Authentication

**System Fields**:
- li.listings.Condition
- im.Items.Condition

**Standard Values** (Recommended):
- **New**: Unworn, in original packaging with all tags
- **Open Box**: Unworn but packaging opened or missing original box
- **Like New**: Minimal wear, appears nearly new
- **Used**: Worn but in good condition

**Business Rules**:
- Condition affects pricing and buyer expectations
- SneakerPark authenticators verify condition matches seller description
- Items in unacceptable condition are rejected

**Inconsistencies**:
- Current data has "new", "Open Box", "like new", "Used" (inconsistent capitalization)
- No standardized list enforced at data entry

**Recommended Standardization**: Create dropdown with 4 standard values, title case, consistent across systems.

---

### Credit Card
**Definition**: A payment method associated with a user's account, used to process order purchases.

**Synonyms**: Payment Method, Card

**Related Terms**: Account, User, Order, Payment

**System Fields**:
- usr.creditcards (all columns)
- op.Orders.CreditCardID

**Business Rules**:
- User can have multiple credit cards on file
- Card information must comply with PCI-DSS security standards
- Card used at time of order is recorded in op.Orders

**Security Notes**: Credit card numbers should be encrypted/tokenized, not stored in plain text.

---

### Customer
**Definition**: A person who interacts with SneakerPark, either as a buyer, seller, or both.

**Synonyms**: User, Client, Member

**Related Terms**: Buyer, Seller, Account, User

**System Fields**:
- usr.users (represents customers)
- cs.CustomerServiceRequests (customer support interactions)

**Business Rules**:
- "Customer" is the broadest term encompassing all platform users
- In customer service context, "customer" includes anyone contacting support
- In transaction context, "buyer" is more specific than "customer"

**Notes**: SneakerPark uses "User" in technical systems but "Customer" in business communications.

---

### Customer Service Request
**Definition**: A record of a customer support interaction, including the reason for contact, resolution, and contact method.

**Synonyms**: Support Ticket, Help Request, Case, Inquiry

**Related Terms**: Customer, User, Order, Resolution

**System Fields**:
- cs.CustomerServiceRequests (all columns)

**Business Rules**:
- Can be related to an order (OrderID) or general inquiry (OrderID = NULL)
- Common reasons: Return, Mischarge, Technical Support, Shipping Delay
- All requests must have a resolution documented
- Retained for 7 years as part of customer data

**Notes**: Customer Service system is isolated with nightly batch exports to other systems.

---

### Duplicate Account
**Definition**: Multiple user accounts belonging to the same person, which violates SneakerPark's one-account-per-person policy.

**Synonyms**: Multiple Accounts, Duplicate User

**Related Terms**: Account, User, Golden Record, MDM

**System Fields**:
- Identified via MDM Hub matching rules on usr.users

**Business Rules**:
- Prohibited to prevent fraud and promotion abuse
- Detected via matching on Email + Name or Address + Phone
- Should be merged into single golden record by data stewards

**Notes**: Currently estimated ~8 potential duplicates. Future data quality issue to monitor.

---

### Forty-Five Day Rule (45-Day Rule)
**Definition**: Business policy requiring sellers to list their authenticated items within 45 days of warehouse arrival, or the items will be returned with shipping invoice.

**Synonyms**: Listing Deadline, 45-Day Policy

**Related Terms**: Arrival Date, Listing Create Date, Item, Warehouse

**System Fields**:
- im.Items.ArrivalDate
- li.listings.ListingCreateDate
- Calculation: ListingCreateDate - ArrivalDate ≤ 45

**Business Rules**:
- Enforced to prevent indefinite warehouse storage
- Reduces seller indecision and warehouse overhead
- Violations result in item return and shipping charge to seller

**Notes**: Requires accurate ArrivalDate tracking. Missing arrival dates prevent enforcement of this rule.

---

### Gender / Sex
**Definition**: The intended wearer demographic for a sneaker product (Male, Female, or Unisex).

**Synonyms**: Sex, Target Gender, Demographic

**Related Terms**: Item, Listing, Size

**System Fields**:
- li.listings.Gender (CHAR(1): 'M', 'F', 'U')
- im.Items.Sex (VARCHAR(10): 'Male', 'Female', 'Unisex')

**Standard Values**:
- **Male** / **M**: Men's sizing and style
- **Female** / **F**: Women's sizing and style
- **Unisex** / **U**: Suitable for all genders

**Inconsistencies**:
- Field name inconsistency: "Gender" vs "Sex"
- Data type inconsistency: CHAR(1) vs VARCHAR(10)
- Value format inconsistency: 'M' vs 'Male'

**Recommended Standardization**: Adopt "Gender" as field name, use full words ("Male", "Female", "Unisex") for clarity, VARCHAR(10) data type.

---

### Golden Record
**Definition**: The single, authoritative version of a master data entity (e.g., Customer, Item) created by the MDM Hub by merging and resolving data from multiple source systems.

**Synonyms**: Master Record, Single Source of Truth, Golden Master

**Related Terms**: MDM Hub, Matching Rules, Duplicate, Data Quality

**System Fields**:
- Created and maintained in MDM Hub
- Links to source systems via cross-reference IDs

**Business Rules**:
- Golden record represents the "best" data from all sources
- Used to resolve conflicts and inconsistencies across systems
- Published back to operational systems to maintain consistency

**Notes**: Core concept in SneakerPark's proposed Hybrid MDM architecture.

---

### Item
**Definition**: A physical pair of sneakers that has been shipped to SneakerPark's warehouse for authentication and eventual listing.

**Synonyms**: Product, Inventory Item, Physical Item

**Related Terms**: Listing, Warehouse, ItemID, ProductID, Arrival Date

**System Fields**:
- im.Items (all columns)
- im.Items.ItemID (unique identifier)

**Business Rules**:
- Items receive an ItemID upon warehouse receipt
- Must be authenticated before listing
- Must be listed within 45 days or returned to seller
- "Item" refers to physical inventory; "Listing" refers to the marketplace offering

**Notes**: ItemID (in im.Items) should match ProductID (in li.listings) but inconsistencies exist.

---

### Item Status
**Definition**: The current state of a physical sneaker item in SneakerPark's warehouse workflow.

**Synonyms**: Status, Inventory Status, Item State

**Related Terms**: Item, Authentication, Warehouse, Listing

**System Fields**:
- im.Items.ItemStatus

**Standard Values**:
- **received**: Item arrived at warehouse, not yet authenticated
- **approved**: Item passed authentication, ready to list
- **listed**: Item has an active listing on marketplace
- **sold**: Item has been purchased
- **rejected**: Item failed authentication, being returned to seller
- **returned**: Item not listed within 45 days, returned to seller

**Business Rules**:
- Status progresses sequentially through workflow
- "approved" items should be listed within 45 days
- "sold" items trigger payment to seller and shipment to buyer

---

### Listing
**Definition**: An active or historical marketplace offering where a seller makes an authenticated sneaker item available for purchase or bidding.

**Synonyms**: Product Listing, Marketplace Listing, Offering

**Related Terms**: Item, Seller, Listing Type, Listing Price, ShoeType

**System Fields**:
- li.listings (all columns)
- li.listings.ListingID (unique identifier)

**Business Rules**:
- Can only be created after item authentication
- Must be created within 45 days of item arrival
- Includes pricing (auction start or fixed price)
- Can be "Auction" or "Fixed" type
- Expires after period or upon sale

**Data Retention**: Deleted 2 years post-expiration (except aggregated metrics for analytics).

---

### Listing Type
**Definition**: The sales method for a listing, either auction-based or fixed-price.

**Synonyms**: Sales Type, Pricing Type

**Related Terms**: Listing, Auction, Buy Now, Fixed Price

**System Fields**:
- li.listings.ListingType

**Standard Values**:
- **Auction**: Bidding-based sales
- **Fixed**: Immediate purchase at set price

**Business Rules**:
- Seller chooses listing type when creating listing
- Cannot change type after listing is active (typically)

---

### Order
**Definition**: A completed purchase transaction where a buyer acquires one or more listed items using a payment method.

**Synonyms**: Purchase, Transaction, Sale

**Related Terms**: Buyer, Seller, Order Item, Payment, Shipment

**System Fields**:
- op.Orders (all columns)
- op.Orders.OrderID (unique identifier)

**Business Rules**:
- Must reference a valid buyer (usr.users.UserID)
- Must have payment method (usr.creditcards.CreditCardID)
- Contains one or more order items (op.OrderItems)
- Generates shipment record (op.OrderShipments) upon fulfillment
- Highly confidential data retained for 7 years

**Notes**: Order Processing Service is mission-critical (99.999% uptime requirement).

---

### Order Item
**Definition**: An individual listing included in an order, representing a line item in the purchase transaction.

**Synonyms**: Line Item, Order Line, Purchase Item

**Related Terms**: Order, Listing, Listing Sold Price

**System Fields**:
- op.OrderItems (all columns)
- Composite key: (OrderID, ListingID)

**Business Rules**:
- Links specific listing to parent order
- Records final sale price (may differ from listing price in auctions)
- An order can contain multiple order items (multiple listings purchased together)

---

### Product ID
**Definition**: An identifier in the Listing Service that should reference the ItemID from the Inventory Management System, linking a listing to its physical item.

**Synonyms**: Item Reference, Inventory Link

**Related Terms**: Item, ItemID, Listing, Cross-Reference

**System Fields**:
- li.listings.ProductID (should equal im.Items.ItemID)

**Business Rules**:
- Should match ItemID for proper item tracking
- Used to link marketplace listing back to warehouse inventory
- Inconsistencies exist (data quality issue)

**Notes**: MDM Hub's cross-reference index will formalize this relationship using matching rules.

---

### Seller
**Definition**: A user who ships sneakers to SneakerPark's warehouse for authentication and listing, earning payment when items sell.

**Synonyms**: Vendor, Consignor

**Related Terms**: Buyer, User, Item, Listing

**System Fields**:
- li.listings.SellerID (references usr.users.UserID)
- im.Items.SellerID (references usr.users.UserID)

**Business Rules**:
- Must have active account
- Ships items to warehouse before listing
- Receives payment minus service fee and shipping costs after sale
- Can also be a buyer (dual role)

**Notes**: SellerID in im.Items does not have enforced foreign key constraint (data quality risk).

---

### Shipment
**Definition**: The physical delivery of a purchased order from SneakerPark's warehouse to the buyer's address.

**Synonyms**: Delivery, Order Shipment, Package

**Related Terms**: Order, Carrier, Tracking Number

**System Fields**:
- op.OrderShipments (all columns)

**Business Rules**:
- Created after order is processed and item retrieved from warehouse
- Includes carrier name (UPS, FedEx, USPS, etc.) and tracking number
- Ship date recorded for delivery estimation
- Multiple shipments possible for single order (if items ship separately)

---

### Shoe Size
**Definition**: The numeric size designation of a sneaker, typically ranging from 0.5 (infant) to 22 (adult).

**Synonyms**: Size, Footwear Size

**Related Terms**: Gender, Item, Listing

**System Fields**:
- li.listings.Size
- im.Items.Size

**Business Rules**:
- Must be valid size (0.5 to 22 range)
- Sizing can vary by gender/demographic (e.g., Women's 8 ≠ Men's 8)
- Should never be '0' (invalid data)

**Data Quality Issue**: Current data contains size='0' values, which are invalid.

**Recommended Standardization**: Implement dropdown with valid sizes, add validation rule to prevent '0' or out-of-range values.

---

### Shoe Type
**Definition**: The category or style of footwear (e.g., Sneakers, Boots, Sandals, Dress Shoes).

**Synonyms**: Product Type, Category, Style

**Related Terms**: Brand, Item, Listing

**System Fields**:
- li.listings.ShoeType
- im.Items.Type

**Standard Values** (Examples):
- Sneakers
- Boots
- Sandals or Flip Flops
- Dress Shoes
- Athletic Shoes

**Business Rules**:
- Important for customer search and filtering
- Should be required field (currently has NULLs - data quality issue)

**Inconsistencies**:
- Field name: "ShoeType" vs "Type"
- 15.2% of listings have NULL ShoeType (critical data quality issue)

**Recommended Standardization**: Use "ShoeType" consistently, make required, create standardized category list.

---

### Tracking Number
**Definition**: A unique alphanumeric code provided by shipping carriers to track package location and delivery status.

**Synonyms**: Shipment Tracking, Package Tracking, Tracking Code

**Related Terms**: Shipment, Carrier, Order

**System Fields**:
- op.OrderShipments.TrackingNumber

**Business Rules**:
- Provided by carrier when shipment is created
- Can be NULL if carrier doesn't provide tracking
- Buyers use this to track delivery progress

---

### User
**Definition**: A person with a registered account on SneakerPark's platform, capable of acting as buyer, seller, or both.

**Synonyms**: Account Holder, Customer, Member

**Related Terms**: Buyer, Seller, Account, Customer

**System Fields**:
- usr.users (all columns)
- usr.users.UserID (unique identifier)

**Business Rules**:
- One person should have only one user account
- User can have multiple roles (buyer and/or seller)
- Required for all marketplace transactions

**Notes**: "User" is technical term in systems; "Customer" is preferred in business communications.

---

### Warehouse
**Definition**: SneakerPark's physical facility where items are received, authenticated, stored, and shipped.

**Synonyms**: Distribution Center, Fulfillment Center

**Related Terms**: Item, Authentication, Arrival Date, Inventory

**System Fields**:
- Represented by im.Items (Inventory Management System)

**Business Rules**:
- All items must pass through warehouse for authentication
- Items stored up to 45 days awaiting listing
- Ships sold items to buyers

**Notes**: Currently only operates in the United States. Future expansion may add international warehouses.

---

## Terminology Inconsistencies Identified

### 1. Brand vs BrandName
- **li.listings** uses "Brand"
- **im.Items** uses "BrandName"
- **Recommendation**: Standardize on "Brand" (shorter, clearer)

### 2. Gender vs Sex
- **li.listings** uses "Gender" (CHAR(1): 'M', 'F', 'U')
- **im.Items** uses "Sex" (VARCHAR(10): 'Male', 'Female', 'Unisex')
- **Recommendation**: Standardize on "Gender" with full words ("Male", "Female", "Unisex")

### 3. ShoeType vs Type
- **li.listings** uses "ShoeType"
- **im.Items** uses "Type"
- **Recommendation**: Standardize on "ShoeType" (more descriptive)

### 4. Condition Capitalization
- Inconsistent: "new" vs "New", "like new" vs "Open Box"
- **Recommendation**: Standardize to title case: "New", "Open Box", "Like New", "Used"

### 5. Brand Spacing
- "New Balance" vs "NewBalance"
- "Johnston & Murphy" vs "Johnston and Murphy"
- **Recommendation**: Use spaces consistently, standardize ampersand vs "and"

### 6. User vs Customer
- Systems use "User" (usr.users, usr.users.UserID)
- Business communications use "Customer"
- **Recommendation**: Keep "User" in technical systems, use "Customer" in external communications and business documentation

---

## How to Improve Terminology Consistency

### 1. Create Reference Data Tables
Establish tables for controlled vocabularies:
```sql
CREATE TABLE ref.brands (
  brand_id INT PRIMARY KEY,
  brand_name VARCHAR(100) UNIQUE NOT NULL,  -- Standardized spelling
  brand_aliases TEXT[]  -- Common variations to map
);

CREATE TABLE ref.shoe_types (
  shoe_type_id INT PRIMARY KEY,
  shoe_type_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE ref.conditions (
  condition_id INT PRIMARY KEY,
  condition_name VARCHAR(50) UNIQUE NOT NULL
);
```

### 2. Implement Dropdown Lists
- Use reference tables to populate dropdown lists in user interfaces
- Prevents freeform text entry that causes inconsistencies
- Enforces standardized values at point of entry

### 3. Add Data Validation Rules
```sql
-- Example: Validate shoe type
ALTER TABLE li.listings
ADD CONSTRAINT fk_shoe_type
FOREIGN KEY (shoe_type_id) REFERENCES ref.shoe_types(shoe_type_id);

-- Example: Validate condition
ALTER TABLE li.listings
ADD CONSTRAINT chk_condition
CHECK (condition IN ('New', 'Open Box', 'Like New', 'Used'));
```

### 4. Conduct Data Migration
- Map existing variations to standardized values
```sql
-- Example: Normalize brand spacing
UPDATE li.listings
SET brand = 'New Balance'
WHERE brand IN ('NewBalance', 'new balance', 'new  balance');
```

### 5. Train Users
- Educate sellers, customer service reps, and warehouse staff on standard terminology
- Provide glossary in onboarding materials
- Include terminology in system tooltips and help text

### 6. Enforce via MDM Hub
- MDM Hub can normalize values during golden record creation
- Map variations to canonical form
- Publish standardized values back to source systems

---

## Usage Guidelines

### For Business Users
- Refer to this glossary when communicating about data
- Use standardized terms in reports, presentations, and documentation
- When in doubt, check the glossary before creating new terminology

### For Developers
- Use glossary terms when naming database columns, API fields, and variables
- Implement dropdown lists from reference data tables
- Add validation rules to enforce standard values

### For Data Stewards
- Maintain this glossary as business evolves
- Review and approve new terms before adding to systems
- Reconcile variations and update glossary accordingly

### For Customer Service
- Use customer-friendly terms (e.g., "customer" not "user", "order" not "transaction")
- Reference glossary when answering customer questions about data policies

---

## Glossary Maintenance

This Business Glossary should be maintained by the **Data Catalog Manager** (Jessica, initially) and reviewed quarterly by the **Data Governance Council**.

**Update Process**:
1. New business term identified by any employee
2. Submit to Data Catalog Manager for review
3. Data Catalog Manager drafts definition and identifies related terms
4. Present to Data Governance Council for approval
5. Add to glossary and communicate to organization
6. Implement in systems (reference tables, validation rules)

**Version Control**: This is Version 1.0 (Initial Release). Future versions should be date-stamped and change-logged.

---

*This Business Glossary provides a foundation for consistent terminology across SneakerPark's Enterprise Data Management initiative and will evolve as the business grows.*
