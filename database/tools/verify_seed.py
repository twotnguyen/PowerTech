#!/usr/bin/env python3
"""Sanity checks that data.seed.sql is anonymized and structurally identical to data.sql."""
import re, sys
from pathlib import Path
import sqlparse
ROOT = Path(__file__).resolve().parents[2]
_, a = sqlparse.parse(ROOT / 'data.sql'); _, b = sqlparse.parse(ROOT / 'database' / 'data.seed.sql')
text = (ROOT / 'database' / 'data.seed.sql').read_text(encoding='utf-8')
errs = []
if [(r[2], r[3]) for r in a] != [(r[2], r[3]) for r in b]: errs.append('table/column layout differs')
if len(a) != len(b): errs.append(f'row count {len(a)} vs {len(b)}')
for pat, what in [(r"AQAAAA", 'password hash'), (r"gmail\.com", 'gmail'), (r"vendor\.vn|powertech\.(vn|com)", 'old domains'),
                  (r"0369861439|0901111111|0903333331", 'old phones'), (r"(?i)nguy[eễ]n ng[oọ]c t[iì]nh|T[ÌI]NH 4851|nguyenngoctinh|lê đức thọ|93/17", 'real name/address'),
                  (r"N'(khong|null)'", 'junk notes')]:
    n = len(re.findall(pat, text, re.I))
    if n: errs.append(f'{n}x {what} still present')
# every non-PII column must be byte-identical
PII = {'Email','NormalizedEmail','UserName','NormalizedUserName','PasswordHash','SecurityStamp','PhoneNumber','FullName','ReceiverName','ShippingAddress','StreetAddress',
       'ContactName','ContactPhone','ContactEmail','GuestName','GuestEmail','GuestPhone','Content','PerformedBy','Note','Message','Title'}
diff = {}
for ra, rb in zip(a, b):
    for c, x, y in zip(ra[3], ra[4], rb[4]):
        if x != y: diff.setdefault((ra[2], c), 0); diff[(ra[2], c)] += 1
unexpected = {k: v for k, v in diff.items() if k[1] not in PII}
if unexpected: errs.append(f'unexpected columns changed: {unexpected}')
print('changed columns:'); [print('  ', k, v) for k, v in sorted(diff.items())]
print('GO count', text.count('\nGO'), 'vs', Path(ROOT/'data.sql').read_text(encoding='utf-8-sig').count('\nGO'))
print('FAIL: ' + '; '.join(errs) if errs else 'OK: seed is anonymized and structurally identical')
sys.exit(bool(errs))
