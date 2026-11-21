/* ============================================================
   BidNile Online Auctions
   SQL Server 2019+
   Task 2: CREATE
   Task 3: ALTER (run top-to-bottom on a fresh database)
   ============================================================ */

IF DB_ID(N'BidNile') IS NULL
    CREATE DATABASE BidNile;
GO
USE BidNile;
GO

/* Exactly four initial schemas */
CREATE SCHEMA Geography;
GO
CREATE SCHEMA People;
GO
CREATE SCHEMA Inventory;
GO
CREATE SCHEMA Sales;
GO

/* -------------------- Task 2: CREATE TABLES -------------------- */

CREATE TABLE Geography.Country
(
    CountryCode CHAR(2) NOT NULL,
    NameEn NVARCHAR(60) NOT NULL,
    NameAr NVARCHAR(60) NULL,
    PhoneCode VARCHAR(6) NOT NULL,
    CONSTRAINT PK_Country PRIMARY KEY (CountryCode),
    CONSTRAINT UQ_Country_NameEn UNIQUE (NameEn)
);
GO

CREATE TABLE Geography.City
(
    CityId INT IDENTITY(1,1) NOT NULL,
    Name NVARCHAR(60) NOT NULL,
    CountryCode CHAR(2) NOT NULL,
    CONSTRAINT PK_City PRIMARY KEY (CityId),
    CONSTRAINT UQ_City_Name_Country UNIQUE (Name, CountryCode)
);
GO

CREATE TABLE People.Member
(
    MemberId UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_Member_MemberId DEFAULT NEWSEQUENTIALID(),
    FullName NVARCHAR(100) NOT NULL,
    Email VARCHAR(254) NOT NULL,
    Mobile VARCHAR(16) NOT NULL,
    NationalId VARCHAR(20) NOT NULL,
    BirthDate DATE NOT NULL,
    IsVerified BIT NOT NULL CONSTRAINT DF_Member_IsVerified DEFAULT (0),
    RegisteredAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Member_RegisteredAt DEFAULT SYSUTCDATETIME(),
    CityId INT NOT NULL,
    InvitedByMemberId UNIQUEIDENTIFIER NULL,
    CONSTRAINT PK_Member PRIMARY KEY (MemberId),
    CONSTRAINT UQ_Member_Email UNIQUE (Email),
    CONSTRAINT UQ_Member_NationalId UNIQUE (NationalId),
    CONSTRAINT CK_Member_BirthDate CHECK (BirthDate <= DATEADD(YEAR, -18, CONVERT(date, GETDATE())))
);
GO

CREATE TABLE People.Wallet
(
    MemberId UNIQUEIDENTIFIER NOT NULL,
    Balance DECIMAL(12,2) NOT NULL CONSTRAINT DF_Wallet_Balance DEFAULT (0),
    HeldAmount DECIMAL(12,2) NOT NULL CONSTRAINT DF_Wallet_HeldAmount DEFAULT (0),
    Currency CHAR(3) NOT NULL CONSTRAINT DF_Wallet_Currency DEFAULT ('EGP'),
    UpdatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_Wallet_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Wallet PRIMARY KEY (MemberId),
    CONSTRAINT CK_Wallet_Balance CHECK (Balance >= 0),
    CONSTRAINT CK_Wallet_HeldAmount CHECK (HeldAmount >= 0 AND HeldAmount <= Balance)
);
GO

CREATE TABLE Inventory.Warehouse
(
    WarehouseId INT IDENTITY(1,1) NOT NULL,
    WarehouseName NVARCHAR(80) NOT NULL,
    Capacity INT NOT NULL,
    CityId INT NOT NULL,
    Latitude FLOAT NOT NULL,
    Longitude FLOAT NOT NULL,
    ManagerMemberId UNIQUEIDENTIFIER NULL,
    ManagerSince DATE NULL,
    CONSTRAINT PK_Warehouse PRIMARY KEY (WarehouseId),
    CONSTRAINT UQ_Warehouse_WarehouseName UNIQUE (WarehouseName),
    CONSTRAINT CK_Warehouse_Capacity CHECK (Capacity > 0),
    CONSTRAINT CK_Warehouse_Latitude CHECK (Latitude BETWEEN -90 AND 90),
    CONSTRAINT CK_Warehouse_Longitude CHECK (Longitude BETWEEN -180 AND 180),
    CONSTRAINT CK_Warehouse_ManagerPair CHECK
        ((ManagerMemberId IS NULL AND ManagerSince IS NULL) OR
         (ManagerMemberId IS NOT NULL AND ManagerSince IS NOT NULL))
);
GO

CREATE TABLE People.Employee
(
    MemberId UNIQUEIDENTIFIER NOT NULL,
    WarehouseId INT NOT NULL,
    EmployeeNumber INT NOT NULL,
    CONSTRAINT PK_Employee PRIMARY KEY (MemberId),
    CONSTRAINT UQ_Employee_EmployeeNumber UNIQUE (EmployeeNumber)
);
GO

CREATE TABLE Inventory.Category
(
    CategoryId INT NOT NULL,
    NameEn NVARCHAR(50) NOT NULL,
    NameAr NVARCHAR(50) NULL,
    Commission DECIMAL(4,2) NOT NULL,
    ParentCategoryId INT NULL,
    CONSTRAINT PK_Category PRIMARY KEY (CategoryId),
    CONSTRAINT UQ_Category_NameEn UNIQUE (NameEn),
    CONSTRAINT CK_Category_Commission CHECK (Commission BETWEEN 0 AND 30)
);
GO

CREATE TABLE Inventory.Item
(
    ItemId INT IDENTITY(1,1) NOT NULL,
    Title NVARCHAR(150) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    ConditionScore TINYINT NOT NULL
        CONSTRAINT CK_Item_ConditionScore CHECK (ConditionScore BETWEEN 1 AND 10),
    Specifications NVARCHAR(MAX) NOT NULL,
    SellerMemberId UNIQUEIDENTIFIER NOT NULL,
    InspectorMemberId UNIQUEIDENTIFIER NOT NULL,
    CategoryId INT NOT NULL,
    WarehouseId INT NULL,
    ListedAt DATETIME2(3) NOT NULL CONSTRAINT DF_Item_ListedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Item PRIMARY KEY (ItemId),
    CONSTRAINT CK_Item_Specifications_JSON CHECK (ISJSON(Specifications) = 1),
    CONSTRAINT CK_Item_SellerInspector CHECK (SellerMemberId <> InspectorMemberId)
);
GO

CREATE TABLE Inventory.ItemPhoto
(
    ItemId INT NOT NULL,
    Position TINYINT NOT NULL,
    PhotoUrl VARCHAR(500) NOT NULL,
    IsMain BIT NOT NULL CONSTRAINT DF_ItemPhoto_IsMain DEFAULT (0),
    CONSTRAINT PK_ItemPhoto PRIMARY KEY (ItemId, Position),
    CONSTRAINT CK_ItemPhoto_Position CHECK (Position BETWEEN 1 AND 20)
);
GO

CREATE TABLE Sales.Auction
(
    AuctionId INT IDENTITY(1,1) NOT NULL,
    ItemId INT NOT NULL,
    StartingPrice DECIMAL(12,2) NOT NULL,
    ReservePrice DECIMAL(12,2) NULL,
    BidIncrement DECIMAL(12,2) NOT NULL CONSTRAINT DF_Auction_BidIncrement DEFAULT (50.00),
    StartsAt DATETIMEOFFSET(0) NOT NULL,
    EndsAt DATETIMEOFFSET(0) NOT NULL,
    Status VARCHAR(20) NOT NULL CONSTRAINT DF_Auction_Status DEFAULT ('Draft'),
    CONSTRAINT PK_Auction PRIMARY KEY (AuctionId),
    CONSTRAINT CK_Auction_StartingPrice CHECK (StartingPrice > 0),
    CONSTRAINT CK_Auction_ReservePrice CHECK (ReservePrice IS NULL OR ReservePrice >= StartingPrice),
    CONSTRAINT CK_Auction_BidIncrement CHECK (BidIncrement > 0),
    CONSTRAINT CK_Auction_DateRange CHECK (EndsAt > StartsAt),
    CONSTRAINT CK_Auction_Status CHECK (Status IN ('Draft','Live','Ended','Cancelled'))
);
GO

CREATE TABLE Sales.Bid
(
    BidId BIGINT IDENTITY(1,1) NOT NULL,
    AuctionId INT NOT NULL,
    MemberId UNIQUEIDENTIFIER NOT NULL,
    Amount DECIMAL(12,2) NOT NULL,
    PlacedAt DATETIME2(3) NOT NULL CONSTRAINT DF_Bid_PlacedAt DEFAULT SYSUTCDATETIME(),
    IPAddress VARCHAR(45) NOT NULL,
    CONSTRAINT PK_Bid PRIMARY KEY (BidId),
    CONSTRAINT UQ_Bid_Auction_Amount UNIQUE (AuctionId, Amount),
    CONSTRAINT CK_Bid_Amount CHECK (Amount > 0)
);
GO

CREATE TABLE Sales.AuctionFollower
(
    MemberId UNIQUEIDENTIFIER NOT NULL,
    AuctionId INT NOT NULL,
    FollowedAt DATETIME2(3) NOT NULL CONSTRAINT DF_AuctionFollower_FollowedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_AuctionFollower PRIMARY KEY (MemberId, AuctionId)
);
GO

/* -------------------- Task 3: ALTER -------------------- */

/* 3.1 Connect everything. All FKs are added after table creation
   so the circular Employee <-> Warehouse relationship is possible. */
ALTER TABLE Geography.City
ADD CONSTRAINT FK_City_Country
FOREIGN KEY (CountryCode) REFERENCES Geography.Country(CountryCode);
GO

ALTER TABLE People.Member
ADD CONSTRAINT FK_Member_City
FOREIGN KEY (CityId) REFERENCES Geography.City(CityId);
GO

ALTER TABLE People.Member
ADD CONSTRAINT FK_Member_InvitedBy
FOREIGN KEY (InvitedByMemberId) REFERENCES People.Member(MemberId);
GO

ALTER TABLE People.Wallet
ADD CONSTRAINT FK_Wallet_Member
FOREIGN KEY (MemberId) REFERENCES People.Member(MemberId);
GO

ALTER TABLE Inventory.Warehouse
ADD CONSTRAINT FK_Warehouse_City
FOREIGN KEY (CityId) REFERENCES Geography.City(CityId);
GO

ALTER TABLE People.Employee
ADD CONSTRAINT FK_Employee_Member
FOREIGN KEY (MemberId) REFERENCES People.Member(MemberId);
GO

ALTER TABLE People.Employee
ADD CONSTRAINT FK_Employee_Warehouse
FOREIGN KEY (WarehouseId) REFERENCES Inventory.Warehouse(WarehouseId);
GO

ALTER TABLE Inventory.Warehouse
ADD CONSTRAINT FK_Warehouse_Manager
FOREIGN KEY (ManagerMemberId) REFERENCES People.Employee(MemberId);
GO

/* An employee manages at most one warehouse. A filtered unique index (not a
   plain UNIQUE) lets many warehouses keep a NULL manager while the circular
   Warehouse <-> Employee data is being loaded. */
CREATE UNIQUE INDEX UX_Warehouse_ManagerMemberId
ON Inventory.Warehouse(ManagerMemberId)
WHERE ManagerMemberId IS NOT NULL;
GO

ALTER TABLE Inventory.Category
ADD CONSTRAINT FK_Category_Parent
FOREIGN KEY (ParentCategoryId) REFERENCES Inventory.Category(CategoryId);
GO

ALTER TABLE Inventory.Item
ADD CONSTRAINT FK_Item_Seller
FOREIGN KEY (SellerMemberId) REFERENCES People.Member(MemberId);
GO

ALTER TABLE Inventory.Item
ADD CONSTRAINT FK_Item_Inspector
FOREIGN KEY (InspectorMemberId) REFERENCES People.Member(MemberId);
GO

ALTER TABLE Inventory.Item
ADD CONSTRAINT FK_Item_Category
FOREIGN KEY (CategoryId) REFERENCES Inventory.Category(CategoryId);
GO

ALTER TABLE Inventory.Item
ADD CONSTRAINT FK_Item_Warehouse
FOREIGN KEY (WarehouseId) REFERENCES Inventory.Warehouse(WarehouseId);
GO

ALTER TABLE Inventory.ItemPhoto
ADD CONSTRAINT FK_ItemPhoto_Item
FOREIGN KEY (ItemId) REFERENCES Inventory.Item(ItemId) ON DELETE CASCADE;
GO

ALTER TABLE Sales.Auction
ADD CONSTRAINT FK_Auction_Item
FOREIGN KEY (ItemId) REFERENCES Inventory.Item(ItemId);
GO

ALTER TABLE Sales.Bid
ADD CONSTRAINT FK_Bid_Auction
FOREIGN KEY (AuctionId) REFERENCES Sales.Auction(AuctionId);
GO

ALTER TABLE Sales.Bid
ADD CONSTRAINT FK_Bid_Member
FOREIGN KEY (MemberId) REFERENCES People.Member(MemberId);
GO

ALTER TABLE Sales.AuctionFollower
ADD CONSTRAINT FK_AuctionFollower_Member
FOREIGN KEY (MemberId) REFERENCES People.Member(MemberId);
GO

ALTER TABLE Sales.AuctionFollower
ADD CONSTRAINT FK_AuctionFollower_Auction
FOREIGN KEY (AuctionId) REFERENCES Sales.Auction(AuctionId);
GO

/* 3.2 App language: existing rows receive 'ar' */
ALTER TABLE People.Member
ADD AppLanguage CHAR(2) NOT NULL
    CONSTRAINT DF_Member_AppLanguage DEFAULT ('ar') WITH VALUES
    CONSTRAINT CK_Member_AppLanguage CHECK (AppLanguage IN ('ar', 'en'));
GO

/* 3.3 Featured flag */
ALTER TABLE Inventory.Item
ADD IsFeatured BIT NOT NULL
    CONSTRAINT DF_Item_IsFeatured DEFAULT (0) WITH VALUES;
GO

/* 3.4 Rename columns using sp_rename */
EXEC sp_rename N'Sales.Bid.IPAddress', N'DeviceIp', N'COLUMN';
GO
EXEC sp_rename N'Inventory.Warehouse.Capacity', N'MaxItems', N'COLUMN';
GO

/* 3.5 Increase FullName to 150 and keep NOT NULL */
ALTER TABLE People.Member
ALTER COLUMN FullName NVARCHAR(150) NOT NULL;
GO

/* 3.6 Change MaxItems to the smallest type that can hold 30,000.
   SMALLINT range is -32,768..32,767 (TINYINT only reaches 255).
   Expected error: the old CHECK depends on the column, so ALTER COLUMN fails
   until that constraint is dropped. Fix: drop it, change the type, re-create it
   with "> 0" kept and the new 30,000 business limit added.
   Rows above 30,000 (if any) are capped first so the new CHECK can be created. */
UPDATE Inventory.Warehouse
SET MaxItems = 30000
WHERE MaxItems > 30000;
GO
ALTER TABLE Inventory.Warehouse
DROP CONSTRAINT CK_Warehouse_Capacity;
GO
ALTER TABLE Inventory.Warehouse
ALTER COLUMN MaxItems SMALLINT NOT NULL;
GO
ALTER TABLE Inventory.Warehouse
ADD CONSTRAINT CK_Warehouse_MaxItems CHECK (MaxItems > 0 AND MaxItems <= 30000);
GO

/* 3.7 Replace commission CHECK: maximum is now 25% */
ALTER TABLE Inventory.Category
DROP CONSTRAINT CK_Category_Commission;
GO
ALTER TABLE Inventory.Category
ADD CONSTRAINT CK_Category_Commission CHECK (Commission BETWEEN 0 AND 25);
GO

/* 3.8 Allow PendingReview and make it the default */
ALTER TABLE Sales.Auction
DROP CONSTRAINT CK_Auction_Status;
GO
ALTER TABLE Sales.Auction
ADD CONSTRAINT CK_Auction_Status
CHECK (Status IN ('Draft','PendingReview','Live','Ended','Cancelled'));
GO
ALTER TABLE Sales.Auction
DROP CONSTRAINT DF_Auction_Status;
GO
ALTER TABLE Sales.Auction
ADD CONSTRAINT DF_Auction_Status DEFAULT ('PendingReview') FOR Status;
GO

/* 3.9 Optional BuyNowPrice, must be greater than StartingPrice.
   WITH CHECK validates existing rows; safe because the new column is NULL
   for existing rows and NULL passes this CHECK expression. */
ALTER TABLE Sales.Auction
ADD BuyNowPrice DECIMAL(12,2) NULL;
GO
ALTER TABLE Sales.Auction WITH CHECK
ADD CONSTRAINT CK_Auction_BuyNowPrice
CHECK (BuyNowPrice IS NULL OR BuyNowPrice > StartingPrice);
GO

/* 3.10 Mobile must be unique */
ALTER TABLE People.Member
ADD CONSTRAINT UQ_Member_Mobile UNIQUE (Mobile);
GO

/* 3.11 Add VerifiedAt, then remove old IsVerified.
   Drop the DEFAULT constraint first because it is attached to IsVerified. */
ALTER TABLE People.Member
ADD VerifiedAt DATETIME2(3) NULL;
GO
ALTER TABLE People.Member
DROP CONSTRAINT DF_Member_IsVerified;
GO
ALTER TABLE People.Member
DROP COLUMN IsVerified;
GO

/* 3.12 Create Marketing and transfer follower table */
CREATE SCHEMA Marketing;
GO
ALTER SCHEMA Marketing TRANSFER Sales.AuctionFollower;
GO

/* End of assignment DDL */
