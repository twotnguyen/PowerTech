/* =====================================================================
   001_fix_data_issues.sql          Database: TechZoneStoreDb (SQL Server)
   Sửa 3 lỗi dữ liệu nêu trong database/data-integrity-report.md:
     [2] Products.SoldQuantity đang tính cả đơn Cancelled/Returned
     [3] PurchaseReceipts.Subtotal/TotalAmount lệch so với tổng dòng chi tiết (PR-DEMO-004)
     [5] OrderHistory thiếu dòng (11 đơn không có lịch sử, đơn 35 thiếu dòng Completed)

   CÁCH DÙNG
     * Mặc định @Commit = 0: script chạy hết, in trước/sau rồi ROLLBACK (chạy thử, không đổi gì).
     * Xem kết quả ổn thì đổi @Commit = 1 và chạy lại. Script chạy lại nhiều lần vẫn an toàn.
     * Sao lưu DB trước khi commit.

   KHÔNG làm (cố ý):
     * Không hoàn lại tồn kho cho đơn đã hủy: đó là quyết định nghiệp vụ. Phần cuối script
       in danh sách sản phẩm bị ảnh hưởng (5 đơn vị) để bạn tự quyết định.
     * Không đổi múi giờ: các dòng lịch sử thêm mới dùng giờ VN (UTC+7) giống dòng sẵn có,
       tức Orders.CreatedAt + 7 giờ.
   ===================================================================== */
USE [TechZoneStoreDb];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Commit BIT = 0;          -- <== đổi thành 1 để ghi thật

BEGIN TRAN;

/* ---------------------------------------------------------------------
   [2] SoldQuantity = tổng số lượng của các đơn còn hiệu lực
       (loại Cancelled, Returned)
   --------------------------------------------------------------------- */
PRINT N'--- [2] SoldQuantity: trước khi sửa (chỉ các sản phẩm lệch) ---';
;WITH expected AS (
    SELECT p.Id,
           ISNULL(SUM(CASE WHEN o.OrderStatus NOT IN (N'Cancelled', N'Returned') THEN i.Quantity END), 0) AS ExpectedSold
    FROM dbo.Products p
    LEFT JOIN dbo.OrderItems i ON i.ProductId = p.Id
    LEFT JOIN dbo.Orders o     ON o.Id = i.OrderId
    GROUP BY p.Id
)
SELECT p.Id, p.SKU, p.SoldQuantity AS SoldHienTai, e.ExpectedSold AS SoldDung
FROM dbo.Products p JOIN expected e ON e.Id = p.Id
WHERE p.SoldQuantity <> e.ExpectedSold;

;WITH expected AS (
    SELECT p.Id,
           ISNULL(SUM(CASE WHEN o.OrderStatus NOT IN (N'Cancelled', N'Returned') THEN i.Quantity END), 0) AS ExpectedSold
    FROM dbo.Products p
    LEFT JOIN dbo.OrderItems i ON i.ProductId = p.Id
    LEFT JOIN dbo.Orders o     ON o.Id = i.OrderId
    GROUP BY p.Id
)
UPDATE p
   SET p.SoldQuantity = e.ExpectedSold,
       p.UpdatedAt    = SYSUTCDATETIME()
FROM dbo.Products p JOIN expected e ON e.Id = p.Id
WHERE p.SoldQuantity <> e.ExpectedSold;
PRINT N'[2] Số sản phẩm đã sửa SoldQuantity: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));

/* ---------------------------------------------------------------------
   [3] Phiếu nhập: tổng tiền theo tổng các dòng chi tiết.
       (Giá trị đúng là tổng dòng: LineTotal = Quantity * ImportPrice đúng ở mọi dòng
        và số lượng các dòng khớp đủ giao dịch IMPORT trong StockTransactions.)
       TotalAmount được dịch cùng mức chênh nên mọi khoản phụ (nếu có) vẫn giữ nguyên.
   --------------------------------------------------------------------- */
PRINT N'--- [3] Phiếu nhập lệch tiền: trước khi sửa ---';
SELECT r.Id, r.ReceiptCode, r.Subtotal, r.TotalAmount, s.ItemsTotal, r.Subtotal - s.ItemsTotal AS Chenh
FROM dbo.PurchaseReceipts r
JOIN (SELECT PurchaseReceiptId, SUM(LineTotal) AS ItemsTotal FROM dbo.PurchaseReceiptItems GROUP BY PurchaseReceiptId) s
  ON s.PurchaseReceiptId = r.Id
WHERE r.Subtotal <> s.ItemsTotal;

UPDATE r
   SET r.TotalAmount = r.TotalAmount + (s.ItemsTotal - r.Subtotal),
       r.Subtotal    = s.ItemsTotal
FROM dbo.PurchaseReceipts r
JOIN (SELECT PurchaseReceiptId, SUM(LineTotal) AS ItemsTotal FROM dbo.PurchaseReceiptItems GROUP BY PurchaseReceiptId) s
  ON s.PurchaseReceiptId = r.Id
WHERE r.Subtotal <> s.ItemsTotal;
PRINT N'[3] Số phiếu nhập đã sửa: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));

/* ---------------------------------------------------------------------
   [5] OrderHistory: bổ sung dòng còn thiếu (đánh dấu PerformedBy = 'System (data backfill)')
       a) Đơn web (mã PT-...) chưa có lịch sử  -> thêm dòng 'Pending' lúc tạo đơn
       b) Đơn chưa có lịch sử, hoặc dòng lịch sử cuối khác OrderStatus
          -> thêm 1 dòng với trạng thái hiện tại, lúc UpdatedAt (hoặc CreatedAt)
       Giờ lưu theo giờ VN: UTC + 7 (giống các dòng lịch sử sẵn có).
   --------------------------------------------------------------------- */
PRINT N'--- [5] Đơn thiếu / lệch lịch sử: trước khi sửa ---';
;WITH last_h AS (
    SELECT OrderId, Status,
           ROW_NUMBER() OVER (PARTITION BY OrderId ORDER BY CreatedAt DESC, Id DESC) AS rn
    FROM dbo.OrderHistory
)
SELECT o.Id, o.OrderCode, o.OrderStatus, h.Status AS LichSuCuoi
FROM dbo.Orders o LEFT JOIN last_h h ON h.OrderId = o.Id AND h.rn = 1
WHERE h.Status IS NULL OR h.Status <> o.OrderStatus;

-- a) dòng 'Pending' cho đơn web chưa có lịch sử
INSERT INTO dbo.OrderHistory (OrderId, Status, Note, Action, PerformedBy, CreatedAt)
SELECT o.Id, N'Pending', N'Đơn hàng được khởi tạo thành công qua website.',
       N'Khách hàng tạo đơn hàng', N'System (data backfill)',
       DATEADD(HOUR, 7, o.CreatedAt)
FROM dbo.Orders o
WHERE o.OrderCode LIKE N'PT-%'
  AND NOT EXISTS (SELECT 1 FROM dbo.OrderHistory h WHERE h.OrderId = o.Id);
PRINT N'[5a] Dòng Pending đã thêm: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));

-- b) dòng trạng thái hiện tại cho đơn mà lịch sử cuối không khớp
;WITH last_h AS (
    SELECT OrderId, Status,
           ROW_NUMBER() OVER (PARTITION BY OrderId ORDER BY CreatedAt DESC, Id DESC) AS rn
    FROM dbo.OrderHistory
)
INSERT INTO dbo.OrderHistory (OrderId, Status, Note, Action, PerformedBy, CreatedAt)
SELECT o.Id, o.OrderStatus,
       CASE
           WHEN o.OrderCode LIKE N'POS-%' THEN N'Đơn hàng tạo tại quầy và hoàn tất thanh toán.'
           WHEN o.OrderStatus = N'Completed' THEN N'Đơn hàng đã hoàn tất.'
           WHEN o.OrderStatus = N'Cancelled' THEN N'Đơn hàng đã bị hủy.'
           ELSE N'Chuyển trạng thái sang: ' + o.OrderStatus
       END,
       CASE
           WHEN o.OrderCode LIKE N'POS-%' THEN N'Bán hàng tại quầy'
           ELSE N'Hệ thống cập nhật trạng thái'
       END,
       N'System (data backfill)',
       DATEADD(HOUR, 7, ISNULL(o.UpdatedAt, o.CreatedAt))
FROM dbo.Orders o
LEFT JOIN last_h h ON h.OrderId = o.Id AND h.rn = 1
WHERE h.Status IS NULL OR h.Status <> o.OrderStatus;
PRINT N'[5b] Dòng trạng thái đã thêm: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));

/* ---------------------------------------------------------------------
   Kiểm tra sau khi sửa (tất cả phải trả 0 dòng)
   --------------------------------------------------------------------- */
PRINT N'--- Kiểm tra sau khi sửa: mọi truy vấn dưới đây phải trả 0 dòng ---';
;WITH expected AS (
    SELECT p.Id, ISNULL(SUM(CASE WHEN o.OrderStatus NOT IN (N'Cancelled', N'Returned') THEN i.Quantity END), 0) AS ExpectedSold
    FROM dbo.Products p LEFT JOIN dbo.OrderItems i ON i.ProductId = p.Id LEFT JOIN dbo.Orders o ON o.Id = i.OrderId
    GROUP BY p.Id)
SELECT N'[2] Sold lệch' AS Loi, p.Id, p.SoldQuantity, e.ExpectedSold
FROM dbo.Products p JOIN expected e ON e.Id = p.Id WHERE p.SoldQuantity <> e.ExpectedSold;

SELECT N'[3] Phiếu nhập lệch' AS Loi, r.Id, r.ReceiptCode, r.Subtotal, s.ItemsTotal
FROM dbo.PurchaseReceipts r
JOIN (SELECT PurchaseReceiptId, SUM(LineTotal) AS ItemsTotal FROM dbo.PurchaseReceiptItems GROUP BY PurchaseReceiptId) s ON s.PurchaseReceiptId = r.Id
WHERE r.Subtotal <> s.ItemsTotal;

;WITH last_h AS (
    SELECT OrderId, Status, ROW_NUMBER() OVER (PARTITION BY OrderId ORDER BY CreatedAt DESC, Id DESC) AS rn FROM dbo.OrderHistory)
SELECT N'[5] Lịch sử thiếu/lệch' AS Loi, o.Id, o.OrderCode, o.OrderStatus, h.Status
FROM dbo.Orders o LEFT JOIN last_h h ON h.OrderId = o.Id AND h.rn = 1
WHERE h.Status IS NULL OR h.Status <> o.OrderStatus;

/* ---------------------------------------------------------------------
   Thông tin cho bạn tự quyết: tồn kho của các đơn đã hủy KHÔNG được hoàn lại.
   Nếu hàng thực tế chưa xuất khỏi kho thì cần cộng lại cột "SoLuongChuaHoan".
   --------------------------------------------------------------------- */
PRINT N'--- Tồn kho chưa hoàn lại từ đơn Cancelled/Returned (không tự sửa) ---';
SELECT p.Id, p.SKU, p.StockQuantity, SUM(i.Quantity) AS SoLuongChuaHoan
FROM dbo.OrderItems i
JOIN dbo.Orders o   ON o.Id = i.OrderId AND o.OrderStatus IN (N'Cancelled', N'Returned')
JOIN dbo.Products p ON p.Id = i.ProductId
GROUP BY p.Id, p.SKU, p.StockQuantity;

IF @Commit = 1
BEGIN
    COMMIT TRAN;
    PRINT N'==> ĐÃ COMMIT.';
END
ELSE
BEGIN
    ROLLBACK TRAN;
    PRINT N'==> CHẠY THỬ: đã ROLLBACK, chưa có gì thay đổi. Đặt @Commit = 1 để ghi thật.';
END
GO
