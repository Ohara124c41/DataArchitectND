# Metadata Extraction for Enterprise Data Catalog

## Table: usr.users

### Data Dictionary
| Column Name | Data Type | Nullable | Key | Description |
|------------|-----------|----------|-----|-------------|
| UserID | INT | NOT NULL | PK | Unique identifier for user account |
| FirstName | VARCHAR(50) | NOT NULL | | User's first name |
| LastName | VARCHAR(50) | NOT NULL | | User's last name |
| Email | VARCHAR(50) | NOT NULL | | User's email address for account |
| Address | VARCHAR(50) | NOT NULL | | User's street address |
| ZipCode | VARCHAR(10) | NOT NULL | | User's postal zip code |

### Business Metadata
- **Schema**: usr (User Service)
- **Table Name**: users
- **Business Name**: User Accounts
- **Description**: Stores account information for both buyers and sellers who transact on SneakerPark platform
- **Subject Area**: Customers
- **Data Classification**: Confidential
- **Retention Period**: 7 years (unless deletion requested by customer)
- **Data Owner**: User Service team
- **Update Frequency**: Real-time (on account creation/updates)
- **Source System**: User Service
- **System Uptime Requirement**: 99.999%

---

## Table: usr.creditcards

### Data Dictionary
| Column Name | Data Type | Nullable | Key | Description |
|------------|-----------|----------|-----|-------------|
| CreditCardID | INT | NOT NULL | PK | Unique identifier for credit card record |
| CreditCardNumber | VARCHAR(50) | NOT NULL | | Credit card number (should be encrypted) |
| CreditCardExpirationDate | DATE | NOT NULL | | Credit card expiration date |
| UserID | INT | NOT NULL | FK | Reference to user who owns the card |

### Business Metadata
- **Schema**: usr (User Service)
- **Table Name**: creditcards
- **Business Name**: Payment Methods
- **Description**: Stores credit card payment methods associated with user accounts for order processing
- **Subject Area**: Customers
- **Data Classification**: Highly Confidential (PCI-DSS)
- **Retention Period**: 7 years (unless deletion requested by customer)
- **Data Owner**: User Service team
- **Update Frequency**: Real-time (on payment method add/update)
- **Source System**: User Service
- **System Uptime Requirement**: 99.999%

---

## Table: li.listings

### Data Dictionary
| Column Name | Data Type | Nullable | Key | Description |
|------------|-----------|----------|-----|-------------|
| ListingID | INT | NOT NULL | PK | Unique identifier for listing |
| SellerID | INT | NOT NULL | FK | Reference to user creating listing (seller) |
| ProductID | INT | NOT NULL | | Reference to physical item being listed |
| ShoeType | VARCHAR(50) | NULL | | Type/style of shoe (e.g., sneaker, boot) |
| Brand | VARCHAR(50) | NULL | | Shoe brand manufacturer name |
| Color | VARCHAR(15) | NULL | | Primary color of the shoe |
| Gender | CHAR(1) | NULL | | Target gender (M/F/U for unisex) |
| Size | VARCHAR(4) | NULL | | Shoe size |
| Condition | VARCHAR(50) | NOT NULL | | Condition of shoe (new, used, etc.) |
| ListingPrice | DECIMAL(8,2) | NOT NULL | | Asking price or starting bid amount |
| ListingType | VARCHAR(20) | NOT NULL | | Type of listing (auction, buy-now, etc.) |
| ListingCreateDate | DATE | NOT NULL | | Date listing was created |
| ListingEndDate | DATE | NULL | | Date listing ends or ended |

### Business Metadata
- **Schema**: li (Listing Service)
- **Table Name**: listings
- **Business Name**: Active and Historical Listings
- **Description**: Seller-created listings for authenticated items available for purchase or bidding
- **Subject Area**: Listings
- **Data Classification**: Internal
- **Retention Period**: Deleted 2 years post-expiration (aggregated metrics retained)
- **Data Owner**: Listing Service team
- **Update Frequency**: Real-time (on listing create/update)
- **Source System**: Listing Service
- **System Uptime Requirement**: 99.99%

---

## Table: op.Orders

### Data Dictionary
| Column Name | Data Type | Nullable | Key | Description |
|------------|-----------|----------|-----|-------------|
| OrderID | INT | NOT NULL | PK | Unique identifier for order |
| BuyerID | INT | NOT NULL | FK | Reference to user placing order (buyer) |
| CreditCardID | INT | NOT NULL | FK | Reference to payment method used |
| ShippingCost | DECIMAL(5,2) | NOT NULL | | Cost to ship order to buyer |
| TaxRatePercent | SMALLINT | NOT NULL | | Tax rate percentage applied to order |
| TotalAmount | DECIMAL(8,2) | NOT NULL | | Total order amount including tax and shipping |
| ShippingAddress | VARCHAR(100) | NULL | | Delivery address for order |
| ShippingZipCode | VARCHAR(10) | NOT NULL | | Delivery zip code for order |
| OrderDate | TIMESTAMP | NOT NULL | | Date and time order was placed |
| Status | VARCHAR(50) | NULL | | Current status of order (processing, shipped, etc.) |

### Business Metadata
- **Schema**: op (Order Processing Service)
- **Table Name**: Orders
- **Business Name**: Customer Orders
- **Description**: Purchase transactions including buyer, payment, and shipping information
- **Subject Area**: Orders
- **Data Classification**: Confidential
- **Retention Period**: 7 years (unless deletion requested by customer)
- **Data Owner**: Order Processing team
- **Update Frequency**: Real-time (on order placement/updates)
- **Source System**: Order Processing Service
- **System Uptime Requirement**: 99.999%

---

## Table: op.OrderItems

### Data Dictionary
| Column Name | Data Type | Nullable | Key | Description |
|------------|-----------|----------|-----|-------------|
| OrderID | INT | NOT NULL | PK, FK | Reference to parent order |
| ListingID | INT | NOT NULL | PK, FK | Reference to listing being purchased |
| ListingSoldPrice | DECIMAL(8,2) | NULL | | Final sale price of the listing |

### Business Metadata
- **Schema**: op (Order Processing Service)
- **Table Name**: OrderItems
- **Business Name**: Order Line Items
- **Description**: Individual listings/items included in customer orders (junction table)
- **Subject Area**: Orders
- **Data Classification**: Confidential
- **Retention Period**: 7 years (unless deletion requested by customer)
- **Data Owner**: Order Processing team
- **Update Frequency**: Real-time (on order placement)
- **Source System**: Order Processing Service
- **System Uptime Requirement**: 99.999%

---

## Table: op.OrderShipments

### Data Dictionary
| Column Name | Data Type | Nullable | Key | Description |
|------------|-----------|----------|-----|-------------|
| ShipmentID | INT | NOT NULL | PK | Unique identifier for shipment record |
| OrderID | INT | NOT NULL | FK | Reference to order being shipped |
| Carrier | VARCHAR(50) | NOT NULL | | Shipping carrier name (UPS, FedEx, etc.) |
| TrackingNumber | VARCHAR(30) | NULL | | Carrier tracking number for package |
| OrderShipDate | DATE | NOT NULL | | Date order was shipped |

### Business Metadata
- **Schema**: op (Order Processing Service)
- **Table Name**: OrderShipments
- **Business Name**: Order Shipment Tracking
- **Description**: Shipping and tracking information for orders sent to buyers
- **Subject Area**: Orders
- **Data Classification**: Confidential
- **Retention Period**: 7 years (unless deletion requested by customer)
- **Data Owner**: Order Processing team
- **Update Frequency**: Real-time (on shipment creation/updates)
- **Source System**: Order Processing Service
- **System Uptime Requirement**: 99.999%

---

## Table: im.Items

### Data Dictionary
| Column Name | Data Type | Nullable | Key | Description |
|------------|-----------|----------|-----|-------------|
| ItemID | INT | NOT NULL | PK | Unique identifier assigned upon warehouse receipt |
| ItemName | VARCHAR(100) | NOT NULL | | Descriptive name of the item |
| SellerID | INT | NOT NULL | | Reference to seller who shipped item |
| Type | VARCHAR(50) | NOT NULL | | Type/category of footwear |
| BrandName | VARCHAR(100) | NOT NULL | | Brand manufacturer name |
| Color | VARCHAR(15) | NOT NULL | | Primary color of the item |
| Size | VARCHAR(4) | NOT NULL | | Shoe size |
| Sex | VARCHAR(10) | NOT NULL | | Target gender/sex |
| Condition | VARCHAR(50) | NOT NULL | | Physical condition of item |
| ItemStatus | VARCHAR(50) | NULL | | Current status (received, authenticated, listed, returned) |
| ArrivalDate | DATE | NULL | | Date item arrived at warehouse |

### Business Metadata
- **Schema**: im (Inventory Management System)
- **Table Name**: Items
- **Business Name**: Warehouse Inventory
- **Description**: Physical sneaker inventory at SneakerPark warehouse awaiting authentication and listing
- **Subject Area**: Inventory
- **Data Classification**: Internal
- **Retention Period**: Current data only (no historical tracking)
- **Data Owner**: Warehouse Operations team
- **Update Frequency**: Batch (nightly exports), Real-time within system
- **Source System**: Inventory Management System
- **System Uptime Requirement**: 99%

---

## Table: cs.CustomerServiceRequests

### Data Dictionary
| Column Name | Data Type | Nullable | Key | Description |
|------------|-----------|----------|-----|-------------|
| ID | INT | NOT NULL | PK | Unique identifier for service request |
| UserID | INT | NOT NULL | | Reference to user submitting request |
| FirstName | VARCHAR(50) | NOT NULL | | First name of requester (denormalized) |
| LastName | VARCHAR(50) | NOT NULL | | Last name of requester (denormalized) |
| ContactReason | VARCHAR(50) | NOT NULL | | Reason for contacting support |
| Email | VARCHAR(50) | NULL | | Contact email (may differ from account email) |
| Phone | VARCHAR(50) | NULL | | Contact phone number |
| OrderID | INT | NULL | | Reference to related order if applicable |
| Resolution | VARCHAR(50) | NOT NULL | | How the request was resolved |
| ContactMethod | VARCHAR(50) | NOT NULL | | How customer contacted support (phone, email, chat) |

### Business Metadata
- **Schema**: cs (Customer Service Application)
- **Table Name**: CustomerServiceRequests
- **Business Name**: Customer Support Tickets
- **Description**: Records of customer support interactions from calls, emails, and other channels
- **Subject Area**: Customers
- **Data Classification**: Confidential
- **Retention Period**: 7 years (part of customer data)
- **Data Owner**: Customer Service team
- **Update Frequency**: Batch (nightly exports), Real-time within system
- **Source System**: Customer Service Application
- **System Uptime Requirement**: 99.999%

---

## Cross-System Relationships

### Integrated Systems
- User Service (usr) ↔ Listing Service (li) via SellerID
- User Service (usr) ↔ Order Processing (op) via BuyerID, CreditCardID
- Listing Service (li) ↔ Order Processing (op) via ListingID

### Isolated Systems (Batch Integration)
- Inventory Management (im) - ProductID should link to li.listings, SellerID to usr.users
- Customer Service (cs) - UserID should link to usr.users, OrderID to op.Orders

### Data Quality Concerns
- **Denormalization**: cs.CustomerServiceRequests duplicates user data
- **Weak References**: im.Items.SellerID and li.listings.ProductID may not have FK constraints
- **Inconsistent Naming**: Gender vs Sex, Brand vs BrandName, Size formats
- **NULL Handling**: Several optional fields that may cause data quality issues

---

## Subject Area Summary

### Customers (3 tables)
- usr.users
- usr.creditcards
- cs.CustomerServiceRequests

### Inventory (1 table)
- im.Items

### Listings (1 table)
- li.listings

### Orders (3 tables)
- op.Orders
- op.OrderItems
- op.OrderShipments

---

*This metadata will be transferred to the Excel template for the Enterprise Data Catalog deliverable.*
