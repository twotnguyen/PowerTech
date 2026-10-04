#!/usr/bin/env python3
"""Generate database/erd.md (Mermaid) from the CREATE TABLE / FOREIGN KEY statements in data.sql."""
import re
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
txt = (ROOT / 'data.sql').read_text(encoding='utf-8-sig')

tables = {}   # name -> [(col, type, nullable)]
for m in re.finditer(r'CREATE TABLE \[dbo\]\.\[(\w+)\]\(\n(.*?)\n CONSTRAINT \[PK_\w+\] PRIMARY KEY CLUSTERED\s*\((.*?)\)WITH', txt, re.S):
    cols = []
    for line in m.group(2).split('\n'):
        mm = re.match(r'\t\[(\w+)\] \[(\w+)\](\([^)]*\))?\s*(?:IDENTITY\(\d+,\d+\))?\s*(?:NOT NULL|NULL)', line)
        if mm: cols.append((mm.group(1), mm.group(2), 'NOT NULL' not in line))
    tables[m.group(1)] = (cols, re.findall(r'\[(\w+)\]', m.group(3)))
fks = re.findall(r'ALTER TABLE \[dbo\]\.\[(\w+)\]\s+WITH (?:NO)?CHECK ADD\s+CONSTRAINT \[FK_\w+\] FOREIGN KEY\(\[(\w+)\]\)\s*REFERENCES \[dbo\]\.\[(\w+)\] \(\[(\w+)\]\)', txt)
def _unique_fk_cols():
    """Single-column unique indexes (a filtered index only counts when it is `IS NOT NULL`, otherwise it is not 1-1)."""
    res = set()
    for m in re.finditer(r'CREATE UNIQUE NONCLUSTERED INDEX \[\w+\] ON \[dbo\]\.\[(\w+)\]\s*\(\s*((?:\[\w+\] (?:ASC|DESC),?\s*)+)\)(.*?)\nGO', txt, re.S):
        cols = re.findall(r'\[(\w+)\]', m.group(2))
        if len(cols) == 1 and ('WHERE' not in m.group(3) or 'IS NOT NULL' in m.group(3)): res.add((m.group(1), cols[0]))
    return res
uniq = _unique_fk_cols()
fkcols = {(t, c) for t, c, _, _ in fks}

DOMAINS = {
 'Danh mục sản phẩm': ['Categories', 'Brands', 'Products', 'ProductImages', 'SpecificationDefinitions', 'ProductSpecifications', 'Reviews', 'ReviewImages'],
 'Bán hàng': ['AspNetUsers', 'UserAddresses', 'Carts', 'CartItems', 'Coupons', 'Orders', 'OrderItems', 'OrderHistory', 'Payments', 'Products'],
 'Kho và nhập hàng': ['Suppliers', 'PurchaseReceipts', 'PurchaseReceiptItems', 'StockTransactions', 'Products', 'AspNetUsers'],
 'Hỗ trợ khách hàng và thu cũ đổi mới': ['SupportTickets', 'TicketResponses', 'TradeInRequests', 'TradeInRequestImages', 'CannedResponses', 'FaqCategories', 'FaqArticles', 'Notifications', 'AspNetUsers', 'Orders', 'Categories', 'Brands'],
 'Tài khoản và phân quyền (ASP.NET Identity)': ['AspNetUsers', 'AspNetRoles', 'AspNetUserRoles', 'AspNetUserClaims', 'AspNetUserLogins', 'AspNetUserTokens', 'AspNetRoleClaims'],
}
def rel(child, col, parent):
    nullable = {c: n for c, _, n in tables[child][0]}[col]
    left = '|o' if nullable else '||'
    right = 'o|' if (child, col) in uniq else 'o{'
    return f'    {parent} {left}--{right} {child} : "{col}"'
def entity(name, full=True):
    cols, pk = tables[name]
    body = []
    for c, t, nullable in cols:
        keys = ','.join(k for k, ok in (('PK', c in pk), ('FK', (name, c) in fkcols)) if ok)
        if full or keys:
            body.append(f'        {t} {c}{" " + keys if keys else ""}')
    return f'    {name} {{\n' + '\n'.join(body) + '\n    }'
def diagram(names, full=True, only_inside=True):
    names = list(dict.fromkeys(names)); s = set(names)
    out = ['```mermaid', 'erDiagram']
    out += [entity(n, full) for n in names if n in tables]
    out += [rel(c, col, p) for c, col, p, _ in fks if c in s and p in s]
    return '\n'.join(out + ['```'])

md = ['# Sơ đồ ERD – TechZoneStoreDb (PowerTech)', '',
      '> Sinh tự động từ `data.sql` bằng `database/tools/gen_erd.py`. Mở bằng GitHub, VS Code (Markdown Preview Mermaid) hoặc https://mermaid.live.',
      '', f'**{len(tables)} bảng, {len(fks)} khóa ngoại.** Ký hiệu: `||--o{{` = bắt buộc một – nhiều, `|o--o{{` = khóa ngoại cho phép NULL, `||--o|` = một – một (FK có unique index).', '',
      '## 1. Toàn cảnh (chỉ khóa chính / khóa ngoại)', '', diagram(list(tables), full=False), '']
for i, (title, names) in enumerate(DOMAINS.items(), 2):
    md += [f'## {i}. {title}', '', diagram(names), '']
md += ['## Ghi chú thiết kế', '',
       '- `Orders` lưu **snapshot** người nhận/địa chỉ; `OrderItems` lưu snapshot tên, SKU, ảnh sản phẩm nên đổi `Products` không làm đổi đơn cũ.',
       '- `StockTransactions.ReferenceType` + `ReferenceId` là tham chiếu **đa hình** (không có FK): `PurchaseReceipt` → `PurchaseReceipts.Id`.',
       '- Không có FK trong DB cho: `SupportTickets.TradeInRequestId` (chỉ là cột tham chiếu), `OrderHistory.PerformedBy` (chuỗi tự do, ví dụ `Shipper: email`), `Orders.CouponId` có FK nhưng `Coupons.UsedCount` là số đếm lưu sẵn.',
       '- Các view `vw_Report_*`, `vw_AdminDashboard_*` và proc `sp_Report_*` đọc từ Orders, OrderItems, Products, Categories, Brands, StockTransactions, PurchaseReceipts, SupportTickets (không vẽ trong ERD).']
(ROOT / 'database' / 'erd.md').write_text('\n'.join(md), encoding='utf-8')
print(len(tables), 'tables', len(fks), 'fks', 'uniq-1to1', uniq & fkcols)
