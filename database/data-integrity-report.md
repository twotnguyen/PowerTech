# Báo cáo kiểm tra toàn vẹn dữ liệu – TechZoneStoreDb

Nguồn: `data.sql` (kết quả trên `data.seed.sql` giống hệt). Chạy lại: `python3 database/tools/check_integrity.py [file.sql]`
(nạp các câu `INSERT` vào SQLite trong bộ nhớ rồi chạy `database/tools/checks.sql`). Số liệu bên dưới là kết quả thực tế của lần chạy đó.

## Tóm tắt

| # | Kiểm tra | Kết quả |
|---|---|---|
| 1 | `StockQuantity` = tổng nhập − tổng xuất trong `StockTransactions` | ❌ lệch **134/134** sản phẩm (xem mục 1) |
| 2 | `SoldQuantity` = tổng `OrderItems.Quantity` | ⚠️ khớp **nếu tính cả đơn đã hủy** (163 = 163); chỉ tính đơn Completed thì lệch 5 sản phẩm |
| 3 | Mỗi dòng sổ kho: `Before ± Quantity = After` | ✅ 273/273 |
| 4 | Sổ kho liên tục theo từng sản phẩm (`Before` = `After` dòng trước) | ❌ 4 dòng đứt chuỗi |
| 5 | `Orders.Subtotal` = tổng `OrderItems.LineTotal`; đơn nào cũng có dòng hàng | ✅ 36/36 |
| 6 | `PurchaseReceipts` tổng tiền = tổng dòng phiếu | ❌ 1/7 phiếu lệch 3.518.000 |
| 7 | `PurchaseReceiptItems` khớp giao dịch IMPORT tương ứng | ✅ 134/134 (cùng phiếu + sản phẩm + số lượng) |
| 8 | Khóa ngoại mồ côi | ✅ 0 (38/44 FK có dữ liệu; 6 FK thuộc bảng rỗng) |
| 9 | Trùng lặp trên unique index | ✅ 0 (kể cả index có `WHERE`) |
| 10 | `Coupons.UsedCount` = số đơn dùng coupon | ✅ GIAM10: 7 = 7, KM50K: 0 = 0 |
| 11 | Thông số kỹ thuật thuộc đúng danh mục của sản phẩm | ✅ 1.317/1.317 |
| 12 | Giá khuyến mãi ≤ giá gốc | ✅ |
| 13 | `OrderHistory` có đủ, dòng cuối khớp `OrderStatus` | ❌ 11 đơn không có lịch sử, 1 đơn lệch trạng thái |
| 14 | Đơn `Paid` có bản ghi `Payments` | ❌ bảng `Payments` **rỗng** nhưng có 34 đơn `Paid` |
| 15 | Ảnh sản phẩm | ⚠️ 14 sản phẩm không có dòng `ProductImages` |

## 1. Tồn kho không khớp sổ kho

Mọi sản phẩm đều lệch (nhiều nhất là 100). Lệch này có quy luật, không phải ngẫu nhiên:

```
StockQuantity = 100 (tồn đầu kỳ, không nằm trong sổ kho) + Σ IMPORT − Σ EXPORT − SoldQuantity
```

Công thức đúng cho **132/134** sản phẩm. Ý nghĩa:

- **Tồn đầu kỳ 100 không có giao dịch ghi lại**, nên không thể dựng lại tồn kho chỉ từ `StockTransactions`.
- **Bán hàng không tạo giao dịch kho.** 134 giao dịch EXPORT đều có `ReferenceType = 'DemoExport'` (222 đơn vị, ghi chú "de can bang ton kho ban dau"), không cái nào tham chiếu đơn hàng. 163 đơn vị đã bán chỉ trừ thẳng vào `Products.StockQuantity`.
- Hai ngoại lệ của công thức:

| Id | SKU | StockQuantity | Công thức cho | Ghi chú |
|---|---|---|---|---|
| 8 | CPU-AMD-R9-9950X | 0 | 100 | Giao dịch #275 nhập 10 với `Before = 0`, trong khi dòng trước đó có `After = 6` |
| 102 | ACC-APPLE-SMARTKEYBOARD-IPAD129-4GEN | 100 | 95 | Hai lần nhập thủ công (#271, #272) bắt đầu từ `Before = 100` |

**Đứt chuỗi sổ kho (4 dòng):** #271 (SP 102), #273 (SP 23), #274 (SP 69), #275 (SP 8). Cả 5 giao dịch nhập thủ công (#271–#275, ghi chú "Nhập kho thủ công") không có `ReferenceId`/phiếu nhập, và giá trị `Before` lấy từ tồn kho hiện tại của sản phẩm chứ không phải từ dòng sổ kho trước đó.

**Đề xuất:** thêm giao dịch `OPENING` (hoặc phiếu nhập đầu kỳ) cho 100 đơn vị tồn đầu; ghi `EXPORT` với `ReferenceType = 'Order'` khi giao hàng; tính `BeforeQuantity` từ sổ kho hoặc khóa dòng sản phẩm khi nhập thủ công. Riêng sản phẩm 8 và 102 cần đối soát thực tế.

## 2. SoldQuantity và đơn đã hủy

- Tổng `SoldQuantity` = 163 = tổng số lượng trên **mọi** đơn (kể cả Cancelled).
- Chỉ tính đơn `Completed` thì tổng là 158. Chênh 5 đơn vị nằm ở 2 đơn bị hủy (đơn 3 và 5):

| Sản phẩm | SoldQuantity | Chỉ đơn Completed |
|---|---|---|
| 10 (CPU-AMD-R9-9950X-TRAY) | 2 | 1 |
| 17 (RAM-TEAMGROUP-TFORCE-DELTA-16G-3600-BLACK) | 1 | 0 |
| 21 (CMP96GX5M2B6600C32) | 1 | 0 |
| 22 (GPU-ASUS-ROGMATRIX-RTX4090-24G) | 3 | 2 |
| 71 (KB-DAREU-EK75-RT-BLACK) | 1 | 0 |

Kết hợp với công thức ở mục 1 (công thức khớp khi `SoldQuantity` gồm cả đơn hủy), có thể suy ra **hủy đơn không hoàn lại tồn kho và không giảm `SoldQuantity`**. Đây là suy luận từ dữ liệu, cần xác nhận lại trong code hủy đơn. Các view `vw_AdminDashboard_TopProducts`... nên kiểm tra xem dùng `SoldQuantity` hay tính từ đơn.

## 3. Phiếu nhập PR-DEMO-004 lệch tiền

`PurchaseReceipts.Id = 1`: `Subtotal = TotalAmount = 466.988.000`, nhưng 4 dòng chi tiết cộng lại `463.470.000` (lệch 3.518.000). 6 phiếu còn lại khớp, và `LineTotal = Quantity × ImportPrice` đúng ở cả 134 dòng, nên sai nằm ở tiêu đề phiếu hoặc thiếu một dòng chi tiết.

## 4. Lịch sử đơn hàng và thanh toán

- **11 đơn không có `OrderHistory`:** đơn 1, 2, 3, 4 (đơn web đầu tiên) và 10, 16, 17, 18, 20, 29, 30 (đơn POS tại quầy).
- **Đơn 35** `Completed` nhưng dòng lịch sử cuối là `Processing`.
- **Lệch múi giờ:** `OrderHistory.CreatedAt` luôn muộn hơn `Orders.CreatedAt` đúng **7 giờ** (15/15 dòng Pending). Nhiều khả năng đơn lưu UTC còn lịch sử lưu giờ Việt Nam (mã đơn `PT-20260409-…` cũng theo giờ VN). Nên thống nhất một múi giờ.
- **`Payments` không có dòng nào** (script không có `INSERT` cho bảng này), trong khi 34/36 đơn là `Paid`. Các view/proc `vw_AdminDashboard_PaymentSummary` và `sp_Report_PaymentStatus` đọc bảng này có thể trả kết quả trống.

## 5. Ảnh sản phẩm

14 sản phẩm không có dòng nào trong `ProductImages`: Loa (Id 122–126) và PC bộ (Id 127–135). Chúng vẫn có `ThumbnailUrl`. Ngoài ra 95 sản phẩm có `ThumbnailUrl` (`…/thumb.jpg`) khác ảnh `IsPrimary` (`…/gallery-1.jpg`); đây có vẻ là quy ước đặt tên chứ không phải lỗi.

## Những gì đã kiểm tra và đạt

Khóa ngoại không mồ côi, unique index không trùng, tổng tiền đơn hàng đúng, sổ kho đúng từng dòng, phiếu nhập khớp giao dịch nhập, coupon khớp, thông số khớp danh mục. Các CHECK constraint (tổng tiền = Subtotal + phí ship − giảm giá, `LineTotal = đơn giá × số lượng`, giá khuyến mãi) được SQL Server cưỡng chế khi tạo (`WITH CHECK`, không có `NOCHECK`). Tôi không chạy lại riêng từng CHECK trên SQLite.

## Giới hạn

Kiểm tra chạy trên SQLite từ các câu `INSERT`, nên kiểm tra dữ liệu chứ không kiểm tra cú pháp T-SQL của script. Mọi kết luận về nguyên nhân (mục 2) là suy luận từ dữ liệu, không đọc code ứng dụng.
