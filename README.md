# ⚡ PowerTech - Hệ thống E-Commerce Bán Lẻ Thiết Bị Công Nghệ

> PowerTech là một nền tảng thương mại điện tử chuyên nghiệp, được tinh chỉnh đặc biệt cho lĩnh vực bán lẻ linh kiện máy tính, PC Build và thiết bị công nghệ (Retail-Tech). Hệ thống mang đến giải pháp chuyển đổi số toàn diện, tối ưu hóa quy trình quản lý từ hiển thị sản phẩm, bán hàng, đến quản lý kho bãi và hỗ trợ chăm sóc khách hàng.

![.NET](https://img.shields.io/badge/.NET-10.0-512BD4?style=flat&logo=dotnet)
![SQL Server](https://img.shields.io/badge/SQL_Server-CC292B?style=flat&logo=microsoftsqlserver&logoColor=white)

---

## 📑 Mục lục

- [🌟 Giới thiệu](#-giới-thiệu)
- [✨ Tính năng nổi bật](#-tính-năng-nổi-bật)
- [🛠 Công nghệ sử dụng](#-công-nghệ-sử-dụng)
- [🚀 Hướng dẫn cài đặt](#-hướng-dẫn-cài-đặt)
- [💻 Cách chạy dự án](#-cách-chạy-dự-án)
- [📁 Cấu trúc dự án](#-cấu-trúc-dự-án)
- [🤝 Đóng góp](#-đóng-góp)

---

## 🌟 Giới thiệu

PowerTech được xây dựng với mục tiêu cung cấp giải pháp phần mềm hoàn chỉnh cho các doanh nghiệp kinh doanh linh kiện điện tử. Thay vì chỉ là một website bán hàng đơn thuần, PowerTech đóng vai trò như một hệ thống quản trị nội bộ ERP thu nhỏ với các module nghiệp vụ chuyên biệt:

- **Dành cho Khách hàng:** Trải nghiệm mua sắm mượt mà, bộ lọc thông minh, quản lý đơn hàng chuyên nghiệp.
- **Dành cho Nhân viên:** Công cụ POS bán hàng tại quầy, quản lý xuất nhập kho bãi, và hệ thống xử lý vé hỗ trợ (Support Tickets).
- **Dành cho Quản lý:** Báo cáo thống kê, kiểm soát nhân sự, phân quyền bảo mật chặt chẽ.

> [!NOTE]
> Dự án này được phát triển dưới dạng đồ án môn học với tiêu chuẩn code và kiến trúc sát với thực tế doanh nghiệp.

---

## ✨ Tính năng nổi bật

Hệ thống được thiết kế theo kiến trúc Modules, chia thành 6 phân hệ (Areas) với hệ thống phân quyền (Role-Based Access Control) độc lập:

### 1. Storefront (Giao diện người dùng)
- Giao diện (UI) mang phong cách Retail-Tech hiện đại.
- Bộ lọc sản phẩm đa chiều (Danh mục, Thương hiệu, Mức giá...).
- Hiển thị chi tiết thông số kỹ thuật (Specs) và trạng thái tồn kho thực tế.

### 2. Customer Area (Khách hàng)
- Quản lý giỏ hàng và thanh toán (Checkout flow).
- Theo dõi lịch sử đơn hàng, trạng thái vận chuyển và tính năng hủy đơn.
- Sổ địa chỉ giao hàng và hồ sơ cá nhân.

### 3. Sales Area (Nhân viên Bán hàng)
- Bảng điều khiển (Dashboard) theo dõi và xử lý đơn hàng trực tuyến.
- Tính năng POS hỗ trợ tạo đơn hàng nhanh tại cửa hàng.

### 4. Warehouse Area (Nhân viên Kho)
- Quản lý danh mục hàng hóa, theo dõi tồn kho và cảnh báo hết hàng.
- Xử lý các phiếu nhập/xuất kho với Audit Trail (lịch sử sửa đổi) rõ ràng.

### 5. Support Area (Nhân viên CSKH)
- Quản lý khiếu nại qua hệ thống Support Tickets.
- Kiểm duyệt và phản hồi các đánh giá (Reviews) từ người dùng.

### 6. Admin Panel (Ban Quản trị)
- Quản trị toàn bộ dữ liệu gốc (Master Data).
- Quản lý sơ đồ tổ chức, tài khoản nhân viên và cơ chế phân quyền nâng cao.

---

## 🛠 Công nghệ sử dụng

- **Frontend:** HTML5, CSS3 (Thiết kế độc quyền Retail-Tech Theme), JavaScript ES6+.
- **Backend:** ASP.NET Core MVC (Target Framework: .NET 10.0).
- **Cơ sở dữ liệu:** Microsoft SQL Server.
- **ORM:** Entity Framework Core (Tiếp cận Code First - Migration).
- **Bảo mật:** ASP.NET Core Identity (Multiple Roles & Claims).

---

## 🚀 Hướng dẫn cài đặt

Làm theo các bước sau để thiết lập môi trường và chạy dự án ở local.

### 1. Yêu cầu hệ thống
- [.NET 10.0 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) trở lên.
- [Microsoft SQL Server](https://www.microsoft.com/vi-vn/sql-server/sql-server-downloads) (hoặc SQL Server Express).
- IDE khuyên dùng: Visual Studio 2022, Rider hoặc VS Code.

### 2. Clone dự án

```bash
git clone https://github.com/TwotNguyenVN/PowerTech.git
cd PowerTech/PowerTech
```

### 3. Khôi phục các gói phụ thuộc (Restore dependencies)

```bash
dotnet restore
```

### 4. Khôi phục Cơ sở dữ liệu (Restore Database)

Dự án đã có sẵn toàn bộ dữ liệu mẫu và cấu trúc bảng. Bạn cần chạy script từ file `data.sql` để khởi tạo:
1. Mở SQL Server Management Studio (SSMS) hoặc công cụ quản trị SQL tương tự.
2. Kết nối tới SQL Server của bạn.
3. Mở file `data.sql` (nằm ở thư mục gốc của dự án) và nhấn **Execute** để chạy toàn bộ lệnh.

### 5. Cấu hình Chuỗi Kết Nối (Connection String)

Sau khi Database đã tạo thành công, bạn cần cấu hình chuỗi kết nối trong source code:
1. Tìm file `appsettings.example.json` trong thư mục `PowerTech`.
2. Đổi tên (hoặc copy) file này thành `appsettings.json`.
3. Mở file `appsettings.json` và điền đường dẫn thật của SQL Server vào chuỗi `DefaultConnection`.

Ví dụ:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=TEN_MAY_CHU_CUA_BAN;Database=TEN_DATABASE;User Id=sa;Password=MAT_KHAU_CUA_BAN;Encrypt=True;TrustServerCertificate=True"
  }
}
```

> [!IMPORTANT]
> - Thay thế các giá trị viết hoa bằng thông tin SQL Server thực tế của bạn.
> - Đảm bảo giữ nguyên cờ `TrustServerCertificate=True` nếu chạy ở môi trường localhost để tránh lỗi SSL.

---

## 💻 Cách chạy dự án

Sau khi đã cài đặt và cấu hình Database thành công, khởi động Web Server bằng lệnh:

```bash
dotnet run
```

- Website sẽ tự động lắng nghe trên cổng: `http://localhost:5000` hoặc `https://localhost:5001`.
- Mở trình duyệt và truy cập vào địa chỉ trên để xem dự án.

---

## 📁 Cấu trúc dự án

```text
PowerTech/
├── Areas/                   # Các phân hệ nghiệp vụ (Admin, Store, Sales, Warehouse...)
├── Controllers/             # Các Controllers dùng chung hoặc Storefront chính
├── Data/                    # DbContext, Migrations và logic Seeding
├── Models/
│   ├── Entities/            # Domain Models / Bảng CSDL
│   └── ViewModels/          # Data Transfer Objects (DTO) để bind data cho View
├── Views/                   # Giao diện chính của hệ thống
├── wwwroot/                 # Tài nguyên tĩnh (CSS, JS, Images, Uploads...)
├── appsettings.json         # File cấu hình môi trường
└── Program.cs               # Entry point & Cấu hình Services/Middleware
```

---

## 🤝 Đóng góp (Contributing)

PowerTech rất hoan nghênh sự đóng góp từ bạn! Để đóng góp, vui lòng làm theo các bước:

1. **Fork** repo này về tài khoản của bạn.
2. Tạo một branch mới: `git checkout -b feature/TenChucNang`.
3. Commit các thay đổi: `git commit -m 'Thêm tính năng TenChucNang'`.
4. Push branch lên Github: `git push origin feature/TenChucNang`.
5. Tạo một **Pull Request** mới.

---

*Developed by PowerTech Team. Mọi hình ảnh minh họa thuộc bản quyền của các hãng công nghệ.*
