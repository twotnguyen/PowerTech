# Sơ đồ ERD – TechZoneStoreDb (PowerTech)

> Sinh tự động từ `data.sql` bằng `database/tools/gen_erd.py`. Mở bằng GitHub, VS Code (Markdown Preview Mermaid) hoặc https://mermaid.live.

**36 bảng, 44 khóa ngoại.** Ký hiệu: `||--o{` = bắt buộc một – nhiều, `|o--o{` = khóa ngoại cho phép NULL, `||--o|` = một – một (FK có unique index).

## 1. Toàn cảnh (chỉ khóa chính / khóa ngoại)

```mermaid
erDiagram
    Orders {
        int Id PK
        nvarchar UserId FK
        int CouponId FK
    }
    AspNetUsers {
        nvarchar Id PK
        nvarchar CreatedByUserId FK
    }
    OrderItems {
        int Id PK
        int OrderId FK
        int ProductId FK
    }
    Categories {
        int Id PK
        int ParentCategoryId FK
    }
    Brands {
        int Id PK
    }
    Products {
        int Id PK
        int CategoryId FK
        int BrandId FK
    }
    StockTransactions {
        int Id PK
        int ProductId FK
        nvarchar PerformedByUserId FK
    }
    Payments {
        int Id PK
        int OrderId FK
    }
    SupportTickets {
        int Id PK
        nvarchar UserId FK
        int OrderId FK
        nvarchar AssignedToUserId FK
    }
    AspNetRoles {
        nvarchar Id PK
    }
    Suppliers {
        int Id PK
    }
    PurchaseReceipts {
        int Id PK
        int SupplierId FK
        nvarchar CreatedByUserId FK
    }
    AspNetUserRoles {
        nvarchar UserId PK,FK
        nvarchar RoleId PK,FK
    }
    PurchaseReceiptItems {
        int Id PK
        int PurchaseReceiptId FK
        int ProductId FK
    }
    __EFMigrationsHistory {
        nvarchar MigrationId PK
    }
    AspNetRoleClaims {
        int Id PK
        nvarchar RoleId FK
    }
    AspNetUserClaims {
        int Id PK
        nvarchar UserId FK
    }
    AspNetUserLogins {
        nvarchar LoginProvider PK
        nvarchar ProviderKey PK
        nvarchar UserId FK
    }
    AspNetUserTokens {
        nvarchar UserId PK,FK
        nvarchar LoginProvider PK
        nvarchar Name PK
    }
    CannedResponses {
        int Id PK
    }
    CartItems {
        int Id PK
        int CartId FK
        int ProductId FK
    }
    Carts {
        int Id PK
        nvarchar UserId FK
    }
    Coupons {
        int Id PK
    }
    FaqArticles {
        int Id PK
        int CategoryId FK
    }
    FaqCategories {
        int Id PK
    }
    Notifications {
        uniqueidentifier Id PK
        nvarchar UserId FK
    }
    OrderHistory {
        int Id PK
        int OrderId FK
    }
    ProductImages {
        int Id PK
        int ProductId FK
    }
    ProductSpecifications {
        int Id PK
        int ProductId FK
        int SpecDefinitionId FK
    }
    ReviewImages {
        int Id PK
        int ReviewId FK
    }
    Reviews {
        int Id PK
        int ProductId FK
        nvarchar UserId FK
    }
    SpecificationDefinitions {
        int Id PK
        int CategoryId FK
    }
    TicketResponses {
        int Id PK
        int TicketId FK
        nvarchar UserId FK
    }
    TradeInRequestImages {
        int Id PK
        int TradeInRequestId FK
    }
    TradeInRequests {
        int Id PK
        nvarchar UserId FK
        int CategoryId FK
        int BrandId FK
    }
    UserAddresses {
        int Id PK
        nvarchar UserId FK
    }
    AspNetRoles ||--o{ AspNetRoleClaims : "RoleId"
    AspNetUsers ||--o{ AspNetUserClaims : "UserId"
    AspNetUsers ||--o{ AspNetUserLogins : "UserId"
    AspNetRoles ||--o{ AspNetUserRoles : "RoleId"
    AspNetUsers ||--o{ AspNetUserRoles : "UserId"
    AspNetUsers |o--o{ AspNetUsers : "CreatedByUserId"
    AspNetUsers ||--o{ AspNetUserTokens : "UserId"
    Carts ||--o{ CartItems : "CartId"
    Products ||--o{ CartItems : "ProductId"
    AspNetUsers |o--o| Carts : "UserId"
    Categories |o--o{ Categories : "ParentCategoryId"
    FaqCategories ||--o{ FaqArticles : "CategoryId"
    AspNetUsers ||--o{ Notifications : "UserId"
    Orders ||--o{ OrderHistory : "OrderId"
    Orders ||--o{ OrderItems : "OrderId"
    Products ||--o{ OrderItems : "ProductId"
    AspNetUsers ||--o{ Orders : "UserId"
    Coupons |o--o{ Orders : "CouponId"
    Orders ||--o{ Payments : "OrderId"
    Products ||--o{ ProductImages : "ProductId"
    Brands ||--o{ Products : "BrandId"
    Categories ||--o{ Products : "CategoryId"
    Products ||--o{ ProductSpecifications : "ProductId"
    SpecificationDefinitions ||--o{ ProductSpecifications : "SpecDefinitionId"
    Products ||--o{ PurchaseReceiptItems : "ProductId"
    PurchaseReceipts ||--o{ PurchaseReceiptItems : "PurchaseReceiptId"
    AspNetUsers ||--o{ PurchaseReceipts : "CreatedByUserId"
    Suppliers ||--o{ PurchaseReceipts : "SupplierId"
    Reviews ||--o{ ReviewImages : "ReviewId"
    AspNetUsers ||--o{ Reviews : "UserId"
    Products ||--o{ Reviews : "ProductId"
    Categories ||--o{ SpecificationDefinitions : "CategoryId"
    AspNetUsers |o--o{ StockTransactions : "PerformedByUserId"
    Products ||--o{ StockTransactions : "ProductId"
    AspNetUsers |o--o{ SupportTickets : "AssignedToUserId"
    AspNetUsers ||--o{ SupportTickets : "UserId"
    Orders |o--o{ SupportTickets : "OrderId"
    AspNetUsers ||--o{ TicketResponses : "UserId"
    SupportTickets ||--o{ TicketResponses : "TicketId"
    TradeInRequests ||--o{ TradeInRequestImages : "TradeInRequestId"
    AspNetUsers |o--o{ TradeInRequests : "UserId"
    Brands |o--o{ TradeInRequests : "BrandId"
    Categories ||--o{ TradeInRequests : "CategoryId"
    AspNetUsers ||--o{ UserAddresses : "UserId"
```

## 2. Danh mục sản phẩm

```mermaid
erDiagram
    Categories {
        int Id PK
        int ParentCategoryId FK
        nvarchar Name
        nvarchar Slug
        nvarchar Description
        int DisplayOrder
        bit IsActive
        datetime2 CreatedAt
        datetime2 UpdatedAt
        nvarchar ImageUrl
    }
    Brands {
        int Id PK
        nvarchar Name
        nvarchar Slug
        nvarchar Description
        nvarchar Country
        nvarchar LogoUrl
        bit IsActive
        datetime2 CreatedAt
        datetime2 UpdatedAt
    }
    Products {
        int Id PK
        nvarchar SKU
        nvarchar Name
        nvarchar Slug
        int CategoryId FK
        int BrandId FK
        decimal Price
        decimal DiscountPrice
        int StockQuantity
        int SoldQuantity
        nvarchar ShortDescription
        nvarchar Description
        nvarchar ThumbnailUrl
        int WarrantyMonths
        bit IsFeatured
        bit IsActive
        datetime2 CreatedAt
        datetime2 UpdatedAt
    }
    ProductImages {
        int Id PK
        int ProductId FK
        nvarchar ImageUrl
        nvarchar AltText
        bit IsPrimary
        int SortOrder
        datetime2 CreatedAt
    }
    SpecificationDefinitions {
        int Id PK
        int CategoryId FK
        nvarchar SpecName
        nvarchar DisplayName
        nvarchar DataType
        nvarchar Unit
        nvarchar GroupName
        int SortOrder
        bit IsFilterable
        bit IsRequired
        bit IsActive
        datetime2 CreatedAt
    }
    ProductSpecifications {
        int Id PK
        int ProductId FK
        int SpecDefinitionId FK
        nvarchar ValueText
        decimal ValueNumber
        bit ValueBoolean
        nvarchar DisplayValue
        datetime2 CreatedAt
    }
    Reviews {
        int Id PK
        int ProductId FK
        nvarchar UserId FK
        tinyint Rating
        nvarchar Comment
        bit IsApproved
        datetime2 CreatedAt
        datetime2 UpdatedAt
    }
    ReviewImages {
        int Id PK
        int ReviewId FK
        nvarchar ImageUrl
        datetime2 CreatedAt
    }
    Categories |o--o{ Categories : "ParentCategoryId"
    Products ||--o{ ProductImages : "ProductId"
    Brands ||--o{ Products : "BrandId"
    Categories ||--o{ Products : "CategoryId"
    Products ||--o{ ProductSpecifications : "ProductId"
    SpecificationDefinitions ||--o{ ProductSpecifications : "SpecDefinitionId"
    Reviews ||--o{ ReviewImages : "ReviewId"
    Products ||--o{ Reviews : "ProductId"
    Categories ||--o{ SpecificationDefinitions : "CategoryId"
```

## 3. Bán hàng

```mermaid
erDiagram
    AspNetUsers {
        nvarchar Id PK
        nvarchar UserName
        nvarchar NormalizedUserName
        nvarchar Email
        nvarchar NormalizedEmail
        bit EmailConfirmed
        nvarchar PasswordHash
        nvarchar SecurityStamp
        nvarchar ConcurrencyStamp
        nvarchar PhoneNumber
        bit PhoneNumberConfirmed
        bit TwoFactorEnabled
        datetimeoffset LockoutEnd
        bit LockoutEnabled
        int AccessFailedCount
        nvarchar FullName
        nvarchar AvatarUrl
        bit IsActive
        bit MustChangePassword
        nvarchar CreatedByUserId FK
        datetime2 CreatedAt
        datetime2 UpdatedAt
        decimal WalletBalance
    }
    UserAddresses {
        int Id PK
        nvarchar UserId FK
        nvarchar ReceiverName
        nvarchar PhoneNumber
        nvarchar Province
        nvarchar District
        nvarchar Ward
        nvarchar StreetAddress
        bit IsDefault
        datetime2 CreatedAt
        datetime2 UpdatedAt
    }
    Carts {
        int Id PK
        nvarchar UserId FK
        datetime2 CreatedAt
        datetime2 UpdatedAt
        nvarchar CookieId
    }
    CartItems {
        int Id PK
        int CartId FK
        int ProductId FK
        int Quantity
        decimal UnitPrice
    }
    Coupons {
        int Id PK
        nvarchar Code
        int Type
        decimal Value
        decimal MinOrderValue
        decimal MaxDiscountAmount
        datetime2 StartDate
        datetime2 EndDate
        int UsageLimit
        int UsedCount
        bit IsActive
        datetime2 CreatedAt
        datetime2 UpdatedAt
    }
    Orders {
        int Id PK
        nvarchar OrderCode
        nvarchar UserId FK
        nvarchar ReceiverName
        nvarchar PhoneNumber
        nvarchar ShippingAddress
        nvarchar OrderStatus
        nvarchar PaymentStatus
        nvarchar PaymentMethod
        decimal Subtotal
        decimal ShippingFee
        decimal DiscountAmount
        decimal TotalAmount
        datetime2 CreatedAt
        datetime2 UpdatedAt
        nvarchar Note
        nvarchar InternalNote
        int DeliveryFailCount
        int CouponId FK
    }
    OrderItems {
        int Id PK
        int OrderId FK
        int ProductId FK
        nvarchar ProductNameSnapshot
        decimal UnitPrice
        int Quantity
        decimal LineTotal
        nvarchar ProductSkuSnapshot
        nvarchar ProductImageSnapshot
    }
    OrderHistory {
        int Id PK
        int OrderId FK
        nvarchar Status
        nvarchar Note
        nvarchar Action
        nvarchar PerformedBy
        datetime2 CreatedAt
    }
    Payments {
        int Id PK
        int OrderId FK
        nvarchar PaymentMethod
        nvarchar PaymentStatus
        decimal Amount
        nvarchar TransactionCode
        datetime2 PaidAt
        datetime2 CreatedAt
        nvarchar Note
        nvarchar GatewayProvider
        nvarchar RawResponse
        datetime2 UpdatedAt
    }
    Products {
        int Id PK
        nvarchar SKU
        nvarchar Name
        nvarchar Slug
        int CategoryId FK
        int BrandId FK
        decimal Price
        decimal DiscountPrice
        int StockQuantity
        int SoldQuantity
        nvarchar ShortDescription
        nvarchar Description
        nvarchar ThumbnailUrl
        int WarrantyMonths
        bit IsFeatured
        bit IsActive
        datetime2 CreatedAt
        datetime2 UpdatedAt
    }
    AspNetUsers |o--o{ AspNetUsers : "CreatedByUserId"
    Carts ||--o{ CartItems : "CartId"
    Products ||--o{ CartItems : "ProductId"
    AspNetUsers |o--o| Carts : "UserId"
    Orders ||--o{ OrderHistory : "OrderId"
    Orders ||--o{ OrderItems : "OrderId"
    Products ||--o{ OrderItems : "ProductId"
    AspNetUsers ||--o{ Orders : "UserId"
    Coupons |o--o{ Orders : "CouponId"
    Orders ||--o{ Payments : "OrderId"
    AspNetUsers ||--o{ UserAddresses : "UserId"
```

## 4. Kho và nhập hàng

```mermaid
erDiagram
    Suppliers {
        int Id PK
        nvarchar Name
        nvarchar ContactName
        nvarchar PhoneNumber
        nvarchar Email
        nvarchar Address
        nvarchar TaxCode
        bit IsActive
        datetime2 CreatedAt
        datetime2 UpdatedAt
    }
    PurchaseReceipts {
        int Id PK
        nvarchar ReceiptCode
        int SupplierId FK
        nvarchar CreatedByUserId FK
        datetime2 ReceiptDate
        nvarchar Status
        decimal Subtotal
        decimal TotalAmount
        nvarchar Note
    }
    PurchaseReceiptItems {
        int Id PK
        int PurchaseReceiptId FK
        int ProductId FK
        int Quantity
        decimal ImportPrice
        decimal LineTotal
    }
    StockTransactions {
        int Id PK
        int ProductId FK
        nvarchar PerformedByUserId FK
        nvarchar TransactionType
        int Quantity
        nvarchar ReferenceType
        int ReferenceId
        int BeforeQuantity
        int AfterQuantity
        nvarchar Note
        datetime2 CreatedAt
    }
    Products {
        int Id PK
        nvarchar SKU
        nvarchar Name
        nvarchar Slug
        int CategoryId FK
        int BrandId FK
        decimal Price
        decimal DiscountPrice
        int StockQuantity
        int SoldQuantity
        nvarchar ShortDescription
        nvarchar Description
        nvarchar ThumbnailUrl
        int WarrantyMonths
        bit IsFeatured
        bit IsActive
        datetime2 CreatedAt
        datetime2 UpdatedAt
    }
    AspNetUsers {
        nvarchar Id PK
        nvarchar UserName
        nvarchar NormalizedUserName
        nvarchar Email
        nvarchar NormalizedEmail
        bit EmailConfirmed
        nvarchar PasswordHash
        nvarchar SecurityStamp
        nvarchar ConcurrencyStamp
        nvarchar PhoneNumber
        bit PhoneNumberConfirmed
        bit TwoFactorEnabled
        datetimeoffset LockoutEnd
        bit LockoutEnabled
        int AccessFailedCount
        nvarchar FullName
        nvarchar AvatarUrl
        bit IsActive
        bit MustChangePassword
        nvarchar CreatedByUserId FK
        datetime2 CreatedAt
        datetime2 UpdatedAt
        decimal WalletBalance
    }
    AspNetUsers |o--o{ AspNetUsers : "CreatedByUserId"
    Products ||--o{ PurchaseReceiptItems : "ProductId"
    PurchaseReceipts ||--o{ PurchaseReceiptItems : "PurchaseReceiptId"
    AspNetUsers ||--o{ PurchaseReceipts : "CreatedByUserId"
    Suppliers ||--o{ PurchaseReceipts : "SupplierId"
    AspNetUsers |o--o{ StockTransactions : "PerformedByUserId"
    Products ||--o{ StockTransactions : "ProductId"
```

## 5. Hỗ trợ khách hàng và thu cũ đổi mới

```mermaid
erDiagram
    SupportTickets {
        int Id PK
        nvarchar TicketCode
        nvarchar UserId FK
        int OrderId FK
        nvarchar Title
        nvarchar Content
        nvarchar Status
        nvarchar Priority
        nvarchar AssignedToUserId FK
        datetime2 CreatedAt
        datetime2 UpdatedAt
        datetime2 ClosedAt
        int Rating
        nvarchar Feedback
        nvarchar AttachmentUrl
        int TradeInRequestId
        nvarchar GuestName
        nvarchar GuestEmail
        nvarchar GuestPhone
    }
    TicketResponses {
        int Id PK
        int TicketId FK
        nvarchar UserId FK
        nvarchar Message
        bit IsInternal
        datetime2 CreatedAt
        nvarchar AttachmentUrl
    }
    TradeInRequests {
        int Id PK
        nvarchar UserId FK
        int CategoryId FK
        int BrandId FK
        nvarchar OtherBrandName
        nvarchar ModelName
        nvarchar Condition
        nvarchar Status
        decimal QuotedPrice
        nvarchar ContactName
        nvarchar ContactPhone
        nvarchar ContactEmail
        nvarchar Note
        datetime2 CreatedAt
    }
    TradeInRequestImages {
        int Id PK
        int TradeInRequestId FK
        nvarchar ImageUrl
    }
    CannedResponses {
        int Id PK
        nvarchar Title
        nvarchar Content
        datetime2 CreatedAt
    }
    FaqCategories {
        int Id PK
        nvarchar Name
        int DisplayOrder
    }
    FaqArticles {
        int Id PK
        int CategoryId FK
        nvarchar Title
        nvarchar Content
        int ViewCount
        datetime2 CreatedAt
    }
    Notifications {
        uniqueidentifier Id PK
        nvarchar UserId FK
        nvarchar Title
        nvarchar Message
        nvarchar TargetUrl
        nvarchar Type
        bit IsRead
        datetime2 CreatedAt
    }
    AspNetUsers {
        nvarchar Id PK
        nvarchar UserName
        nvarchar NormalizedUserName
        nvarchar Email
        nvarchar NormalizedEmail
        bit EmailConfirmed
        nvarchar PasswordHash
        nvarchar SecurityStamp
        nvarchar ConcurrencyStamp
        nvarchar PhoneNumber
        bit PhoneNumberConfirmed
        bit TwoFactorEnabled
        datetimeoffset LockoutEnd
        bit LockoutEnabled
        int AccessFailedCount
        nvarchar FullName
        nvarchar AvatarUrl
        bit IsActive
        bit MustChangePassword
        nvarchar CreatedByUserId FK
        datetime2 CreatedAt
        datetime2 UpdatedAt
        decimal WalletBalance
    }
    Orders {
        int Id PK
        nvarchar OrderCode
        nvarchar UserId FK
        nvarchar ReceiverName
        nvarchar PhoneNumber
        nvarchar ShippingAddress
        nvarchar OrderStatus
        nvarchar PaymentStatus
        nvarchar PaymentMethod
        decimal Subtotal
        decimal ShippingFee
        decimal DiscountAmount
        decimal TotalAmount
        datetime2 CreatedAt
        datetime2 UpdatedAt
        nvarchar Note
        nvarchar InternalNote
        int DeliveryFailCount
        int CouponId FK
    }
    Categories {
        int Id PK
        int ParentCategoryId FK
        nvarchar Name
        nvarchar Slug
        nvarchar Description
        int DisplayOrder
        bit IsActive
        datetime2 CreatedAt
        datetime2 UpdatedAt
        nvarchar ImageUrl
    }
    Brands {
        int Id PK
        nvarchar Name
        nvarchar Slug
        nvarchar Description
        nvarchar Country
        nvarchar LogoUrl
        bit IsActive
        datetime2 CreatedAt
        datetime2 UpdatedAt
    }
    AspNetUsers |o--o{ AspNetUsers : "CreatedByUserId"
    Categories |o--o{ Categories : "ParentCategoryId"
    FaqCategories ||--o{ FaqArticles : "CategoryId"
    AspNetUsers ||--o{ Notifications : "UserId"
    AspNetUsers ||--o{ Orders : "UserId"
    AspNetUsers |o--o{ SupportTickets : "AssignedToUserId"
    AspNetUsers ||--o{ SupportTickets : "UserId"
    Orders |o--o{ SupportTickets : "OrderId"
    AspNetUsers ||--o{ TicketResponses : "UserId"
    SupportTickets ||--o{ TicketResponses : "TicketId"
    TradeInRequests ||--o{ TradeInRequestImages : "TradeInRequestId"
    AspNetUsers |o--o{ TradeInRequests : "UserId"
    Brands |o--o{ TradeInRequests : "BrandId"
    Categories ||--o{ TradeInRequests : "CategoryId"
```

## 6. Tài khoản và phân quyền (ASP.NET Identity)

```mermaid
erDiagram
    AspNetUsers {
        nvarchar Id PK
        nvarchar UserName
        nvarchar NormalizedUserName
        nvarchar Email
        nvarchar NormalizedEmail
        bit EmailConfirmed
        nvarchar PasswordHash
        nvarchar SecurityStamp
        nvarchar ConcurrencyStamp
        nvarchar PhoneNumber
        bit PhoneNumberConfirmed
        bit TwoFactorEnabled
        datetimeoffset LockoutEnd
        bit LockoutEnabled
        int AccessFailedCount
        nvarchar FullName
        nvarchar AvatarUrl
        bit IsActive
        bit MustChangePassword
        nvarchar CreatedByUserId FK
        datetime2 CreatedAt
        datetime2 UpdatedAt
        decimal WalletBalance
    }
    AspNetRoles {
        nvarchar Id PK
        nvarchar Name
        nvarchar NormalizedName
        nvarchar ConcurrencyStamp
        nvarchar Description
        bit IsActive
        datetime2 CreatedAt
    }
    AspNetUserRoles {
        nvarchar UserId PK,FK
        nvarchar RoleId PK,FK
    }
    AspNetUserClaims {
        int Id PK
        nvarchar UserId FK
        nvarchar ClaimType
        nvarchar ClaimValue
    }
    AspNetUserLogins {
        nvarchar LoginProvider PK
        nvarchar ProviderKey PK
        nvarchar ProviderDisplayName
        nvarchar UserId FK
    }
    AspNetUserTokens {
        nvarchar UserId PK,FK
        nvarchar LoginProvider PK
        nvarchar Name PK
        nvarchar Value
    }
    AspNetRoleClaims {
        int Id PK
        nvarchar RoleId FK
        nvarchar ClaimType
        nvarchar ClaimValue
    }
    AspNetRoles ||--o{ AspNetRoleClaims : "RoleId"
    AspNetUsers ||--o{ AspNetUserClaims : "UserId"
    AspNetUsers ||--o{ AspNetUserLogins : "UserId"
    AspNetRoles ||--o{ AspNetUserRoles : "RoleId"
    AspNetUsers ||--o{ AspNetUserRoles : "UserId"
    AspNetUsers |o--o{ AspNetUsers : "CreatedByUserId"
    AspNetUsers ||--o{ AspNetUserTokens : "UserId"
```

## Ghi chú thiết kế

- `Orders` lưu **snapshot** người nhận/địa chỉ; `OrderItems` lưu snapshot tên, SKU, ảnh sản phẩm nên đổi `Products` không làm đổi đơn cũ.
- `StockTransactions.ReferenceType` + `ReferenceId` là tham chiếu **đa hình** (không có FK): `PurchaseReceipt` → `PurchaseReceipts.Id`.
- Không có FK trong DB cho: `SupportTickets.TradeInRequestId` (chỉ là cột tham chiếu), `OrderHistory.PerformedBy` (chuỗi tự do, ví dụ `Shipper: email`), `Orders.CouponId` có FK nhưng `Coupons.UsedCount` là số đếm lưu sẵn.
- Các view `vw_Report_*`, `vw_AdminDashboard_*` và proc `sp_Report_*` đọc từ Orders, OrderItems, Products, Categories, Brands, StockTransactions, PurchaseReceipts, SupportTickets (không vẽ trong ERD).