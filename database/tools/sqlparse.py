import re
INS = re.compile(r'^INSERT \[dbo\]\.\[(\w+)\] \(([^)]*)\) VALUES \(', re.S)

def split_values(s):
    """s = text after 'VALUES (' up to and incl final ')'. returns list of raw value strings."""
    vals, i, n, depth, start, inq = [], 0, len(s), 0, 0, False
    while i < n:
        c = s[i]
        if inq:
            if c == "'":
                if i+1 < n and s[i+1] == "'": i += 2; continue
                inq = False
        else:
            if c == "'": inq = True
            elif c == '(': depth += 1
            elif c == ')':
                if depth == 0:
                    vals.append(s[start:i].strip()); return vals
                depth -= 1
            elif c == ',' and depth == 0:
                vals.append(s[start:i].strip()); start = i+1
        i += 1
    raise ValueError('unterminated')

def decode(raw):
    if raw == 'NULL': return None
    m = re.fullmatch(r"N?'(.*)'", raw, re.S)
    if m: return m.group(1).replace("''", "'")
    m = re.fullmatch(r"CAST\((.*) AS (\w+)(\([^)]*\))?\)", raw, re.S)
    if m: return decode(m.group(1).strip()) if m.group(1).strip().startswith(("N'", "'")) else float(m.group(1))
    if re.fullmatch(r'-?\d+', raw): return int(raw)
    if re.fullmatch(r'-?\d+\.\d+', raw): return float(raw)
    return raw

def parse(path):
    """yield (lineno, table, cols, rawvals) for every INSERT; statements may span lines."""
    with open(path, encoding='utf-8-sig') as f: lines = f.read().split('\n')
    out = []; i = 0
    while i < len(lines):
        if lines[i].startswith('INSERT [dbo]'):
            buf = lines[i]; j = i
            while True:
                m = INS.match(buf)
                try:
                    raw = split_values(buf[m.end():]); break
                except ValueError:
                    j += 1; buf += '\n' + lines[j]
            cols = [c.strip(' []') for c in m.group(2).split(',')]
            assert len(cols) == len(raw), (i+1, m.group(1), len(cols), len(raw))
            out.append((i+1, j+1, m.group(1), cols, raw))
            i = j
        i += 1
    return lines, out
