/* Optional post-load validation queries. Read-only (SELECT only). */
USE BidNile;
GO

-- Row counts (Task 4 minimums)
SELECT 'Country' AS TableName, COUNT_BIG(*) AS RowCount FROM Geography.Country
UNION ALL SELECT 'City', COUNT_BIG(*) FROM Geography.City
UNION ALL SELECT 'Member', COUNT_BIG(*) FROM People.Member
UNION ALL SELECT 'Wallet', COUNT_BIG(*) FROM People.Wallet
UNION ALL SELECT 'Warehouse', COUNT_BIG(*) FROM Inventory.Warehouse
UNION ALL SELECT 'Employee', COUNT_BIG(*) FROM People.Employee
UNION ALL SELECT 'Category', COUNT_BIG(*) FROM Inventory.Category
UNION ALL SELECT 'Item', COUNT_BIG(*) FROM Inventory.Item
UNION ALL SELECT 'ItemPhoto', COUNT_BIG(*) FROM Inventory.ItemPhoto
UNION ALL SELECT 'Auction', COUNT_BIG(*) FROM Sales.Auction
UNION ALL SELECT 'Bid', COUNT_BIG(*) FROM Sales.Bid
UNION ALL SELECT 'AuctionFollower (Marketing)', COUNT_BIG(*) FROM Marketing.AuctionFollower;
GO

-- Every required auction status should appear
SELECT Status, COUNT(*) AS AuctionCount
FROM Sales.Auction
GROUP BY Status
ORDER BY Status;
GO

-- Confirm at least two distinct time-zone offsets
SELECT DISTINCT DATEPART(TZOFFSET, StartsAt) AS StartOffsetMinutes
FROM Sales.Auction
ORDER BY StartOffsetMinutes;
GO

-- Check that all item specifications contain valid JSON
SELECT ItemId, Specifications
FROM Inventory.Item
WHERE ISJSON(Specifications) <> 1;
GO

-- Check the member who sells and also bids (expected to return at least one row)
SELECT DISTINCT i.SellerMemberId AS MemberId
FROM Inventory.Item AS i
INNER JOIN Sales.Bid AS b
    ON b.MemberId = i.SellerMemberId;
GO

-- Check all wallets and warehouse manager assignments
SELECT m.MemberId, w.Balance, w.HeldAmount
FROM People.Member AS m
LEFT JOIN People.Wallet AS w ON w.MemberId = m.MemberId
WHERE w.MemberId IS NULL OR w.HeldAmount > w.Balance;
GO

SELECT WarehouseId, ManagerMemberId, ManagerSince
FROM Inventory.Warehouse
WHERE ManagerMemberId IS NULL OR ManagerSince IS NULL;
GO

-- Check schema placement after Task 3.12
SELECT SCHEMA_NAME(schema_id) AS SchemaName, name AS TableName
FROM sys.tables
WHERE name = 'AuctionFollower';
GO
