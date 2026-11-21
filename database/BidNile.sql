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

