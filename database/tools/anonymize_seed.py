#!/usr/bin/env python3
"""Build an anonymized seed (database/data.seed.sql) from the SSMS script data.sql.

Only INSERT statements are rewritten; schema, views and procedures are copied as-is.
Usage: python3 database/tools/anonymize_seed.py [data.sql] [out.sql]
"""
import hashlib, re, sys
from pathlib import Path
import sqlparse

ROOT = Path(__file__).resolve().parents[2]
SRC = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'data.sql'
DST = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / 'database' / 'data.seed.sql'

EMAIL = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
PHONE = re.compile(r"(?<!\d)0\d{9,10}(?!\d)")
PHONE_COLS = {'PhoneNumber', 'ContactPhone', 'GuestPhone'}
JUNK = {'khong', 'null'}                       # placeholder text typed into Note fields
# real person (the developer's own test data) -> neutral demo values
REAL_NAMES = ['TÌNH 4851_NGUYỄN NGỌC', 'Nguyễn Ngọc Tình', 'Tớ Tên Tình']
REAL_NAME_EXACT = {'tình'}                     # whole-value only: "Tình trạng" must survive
DEMO_NAME = 'Khách Hàng Demo'
REAL_ADDR = re.compile(r"(?i)^(lê đức thọ|93/17 nguy[eễ]n th[iị] t[uú])")
DEMO_ADDR = '123 Đường Demo, Phường 5, Gò Vấp, TP.HCM'
DEMO_STREET = '123 Đường Demo'
NAME_COLS = {'ReceiverName', 'FullName', 'ContactName', 'GuestName'}

lines, rows = sqlparse.parse(SRC)

# ---- build stable maps from AspNetUsers (case-insensitive emails) ----
emails, n_cust = {}, 0
def map_email(e):
    global n_cust
    k = e.lower()
    if k not in emails:
        local, dom = k.split('@')
        if dom.startswith('powertech.') or dom == 'vendor.vn':
            new = f'{local}@example.com'
            if new in emails.values(): new = f'{local}.{dom.split(".")[-1]}@example.com'
        else:
            n_cust += 1; new = f'user{n_cust}@example.com'
        emails[k] = new
    return emails[k]

phones = {}
def map_phone(p):
    if p not in phones: phones[p] = f'09{len(phones) + 1:08d}'
    return phones[p]

def fix_text(s, col):
    if s.lower() in JUNK: return None
    if s in REAL_NAME_EXACT: return DEMO_NAME
    for n in REAL_NAMES: s = s.replace(n, DEMO_NAME)
    def em(m):
        new = map_email(m.group(0))
        return new.upper() if m.group(0).isupper() else new
    s = EMAIL.sub(em, s)
    if col in PHONE_COLS or col == 'Content': s = PHONE.sub(lambda m: map_phone(m.group(0)), s)
    return s

# deterministic fake stamps, so re-running gives an identical file
def stamp(uid): return hashlib.sha256(uid.encode()).hexdigest()[:32].upper()

def lit(s): return "N'" + s.replace("'", "''") + "'"

out_stmts = {}   # first_line_idx -> (last_line_idx, new_text)
stats = {'rows_changed': 0, 'junk_nulled': 0, 'hash_removed': 0}
for first, last, table, cols, raw in rows:
    new = list(raw)
    for k, (c, r) in enumerate(zip(cols, raw)):
        v = sqlparse.decode(r)
        if not isinstance(v, str): continue
        if table == 'AspNetUsers' and c == 'PasswordHash': new[k] = 'NULL'; stats['hash_removed'] += 1; continue
        if table == 'AspNetUsers' and c == 'SecurityStamp':
            new[k] = lit(stamp(sqlparse.decode(raw[cols.index('Id')]))); continue
        if table == 'Orders' and c == 'ShippingAddress' and REAL_ADDR.match(v): new[k] = lit(DEMO_ADDR); continue
        if table == 'UserAddresses' and c == 'StreetAddress' and REAL_ADDR.match(v): new[k] = lit(DEMO_STREET); continue
        if c in ('Id', 'UserId', 'ConcurrencyStamp', 'NormalizedName') or table == '__EFMigrationsHistory': continue
        nv = fix_text(v, c)
        if nv is None:
            new[k] = 'NULL'; stats['junk_nulled'] += 1
        elif nv != v:
            new[k] = lit(nv)
    if new != raw:
        stats['rows_changed'] += 1
        prefix = re.match(r'^INSERT \[dbo\]\.\[\w+\] \([^)]*\) VALUES \(', '\n'.join(lines[first-1:last])).group(0)
        out_stmts[first-1] = (last-1, prefix + ', '.join(new) + ')')

header = [
    '-- =====================================================================',
    '-- ANONYMIZED SEED generated from data.sql by database/tools/anonymize_seed.py',
    '--  * AspNetUsers.PasswordHash = NULL  -> nobody can log in until a password is set',
    '--    (use "Forgot password" or UserManager.AddPasswordAsync / ResetPasswordAsync)',
    '--  * Emails -> *@example.com, phones -> 09000000xx, real names/addresses -> demo values',
    '--  * Placeholder notes ("khong", "null") -> NULL',
    '--  * Schema, views and stored procedures are unchanged.',
    '-- =====================================================================',
]
res, i = list(header), 0
while i < len(lines):
    if i in out_stmts:
        last, text = out_stmts[i]; res.append(text); i = last + 1
    else:
        res.append(lines[i]); i += 1
DST.parent.mkdir(parents=True, exist_ok=True)
DST.write_text('\n'.join(res), encoding='utf-8')
print(stats, 'emails:', len(emails), 'phones:', len(phones))
for k, v in emails.items(): print('  ', k, '->', v)
