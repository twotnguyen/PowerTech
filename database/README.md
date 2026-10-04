# database/

| File | Nội dung |
|---|---|
| `data.seed.sql` | Bản seed đã ẩn danh sinh từ `../data.sql`: không còn password hash, email → `@example.com`, SĐT → `09000000xx`, tên/địa chỉ thật → giá trị demo, ghi chú rác (`khong`, `null`) → NULL. Schema, view, proc giữ nguyên. **Không ai đăng nhập được** cho tới khi đặt lại mật khẩu. |
| `erd.md` | Sơ đồ ERD (Mermaid): toàn cảnh + 5 nhóm nghiệp vụ. |
| `data-integrity-report.md` | Kết quả kiểm tra toàn vẹn (tồn kho, SoldQuantity, phiếu nhập, FK…). |
| `fixes/001_fix_data_issues.sql` | Script T-SQL sửa 3 lỗi dữ liệu (SoldQuantity, phiếu PR-DEMO-004, OrderHistory thiếu). Mặc định chạy thử rồi ROLLBACK; đặt `@Commit = 1` để ghi thật. |
| `tools/` | Script tái tạo: `anonymize_seed.py`, `verify_seed.py`, `check_integrity.py` (+ `checks.sql`), `gen_erd.py`. Chỉ cần Python 3 và `sqlite3`. |

```
python3 database/tools/anonymize_seed.py   # sinh lại data.seed.sql
python3 database/tools/verify_seed.py      # xác nhận đã ẩn danh + cấu trúc không đổi
python3 database/tools/check_integrity.py  # báo cáo toàn vẹn
python3 database/tools/gen_erd.py          # sinh lại erd.md
```
