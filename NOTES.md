# BidNile — NOTES

## 1. The four initial schemas and why
- **Geography**: `Country`, `City` — geographic reference data is grouped together.
- **People**: `Member`, `Wallet`, `Employee` — account, wallet, and staff identity data.
- **Inventory**: `Warehouse`, `Category`, `Item`, `ItemPhoto` — physical stock and product catalogue.
- **Sales**: `Auction`, `Bid`, `AuctionFollower` — auction activity and bidding.
- In Task 3.12, the assignment explicitly creates a fifth schema, `Marketing`, and transfers `AuctionFollower` into it.

## 2. Relationship types and mapping
- **1:1**: `Member` to `Wallet`; `Wallet.MemberId` is both PK and FK.
- **1:N**: `Country` to `City`; `City` to `Member`; `Warehouse` to `Employee`; `Category` to child categories; `Member` to listed items; `Item` to auctions over time; `Auction` to bids.
- **M:N**: `Member` to `Auction` through `AuctionFollower`; also members place bids on auctions through `Bid`.
- **Recursive**: `Member.InvitedByMemberId` references `Member.MemberId`; `Category.ParentCategoryId` references `Category.CategoryId`.
- **Circular**: `Employee.WarehouseId` references `Warehouse`, while `Warehouse.ManagerMemberId` references `Employee`.
- **Weak entity**: `ItemPhoto`; its composite PK is `(ItemId, Position)` and its FK uses `ON DELETE CASCADE`.

## 3. Why GUID for members and BIGINT for bids? Why FLOAT for GPS but DECIMAL for money? Why DATETIMEOFFSET for auctions?
- `UNIQUEIDENTIFIER` supports IDs generated on a mobile device before reaching the server and avoids relying on a server-side sequence.
- `BIGINT` supports a bid counter expected to exceed 2.1 billion.
- `FLOAT` is suitable for approximate GPS measurements; `DECIMAL` stores exact monetary values.
- `DATETIMEOFFSET` preserves each auction's local UTC offset (Cairo, Riyadh, Dubai).

## 4. Why can't the circular relationship be created inside CREATE TABLE?
Because each table depends on the other table existing first. Create both tables with the FK columns first, then add the two foreign-key constraints afterward using `ALTER TABLE`.

## 5. The order used to fill tables, and why
1. `Country`
2. `City`
3. `Member`
4. `Warehouse`
5. `Employee`
6. Update `Warehouse.ManagerMemberId` after employees exist
7. `Wallet`
8. `Category`
9. `Item`
10. `ItemPhoto`
11. `Auction`
12. `Bid`
13. `AuctionFollower`

This order follows parent rows before dependent rows. The manager link is circular, so insert warehouses with a NULL manager first, insert employees, then update each warehouse manager and its ManagerSince date. A filtered unique index ensures one employee cannot manage multiple warehouses while allowing temporary NULL manager values during initial loading.

## 6. Errors in 3.6 and 3.11, and how they were fixed
- **3.6**: `ALTER COLUMN MaxItems SMALLINT` fails because the `> 0` CHECK constraint (still named `CK_Warehouse_Capacity`) depends on the column. `SMALLINT` (max 32,767) is the smallest type that holds 30,000; `TINYINT` only reaches 255. Fix: drop the CHECK, change the type, then re-create it as `CK_Warehouse_MaxItems` keeping `> 0` and adding the new `<= 30000` business limit (any existing value above 30,000 is capped first so the CHECK can be created).
- **3.11**: Dropping `IsVerified` fails because `DF_Member_IsVerified` (its DEFAULT) is attached to it. Fix: drop that DEFAULT constraint first, then drop the column.
- **3.2** (not an error, but worth knowing): the `ar`/`en` rule is a CHECK added in the same single statement as the NOT NULL column with its default.

## 7. Hand trace for [1, 2, 3, 4]
Input: `[1, 2, 3, 4]`

| Index | Prefix (left product) | Suffix (right product) | Answer |
|---:|---:|---:|---:|
| 0 | 1 | 24 | 24 |
| 1 | 1 | 12 | 12 |
| 2 | 2 | 4 | 8 |
| 3 | 6 | 1 | 6 |

Output: `[24, 12, 8, 6]`.
