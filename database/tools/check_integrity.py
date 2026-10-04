#!/usr/bin/env python3
"""Load data.sql (or the seed) into an in-memory SQLite and run checks.sql.
Usage: python3 database/tools/check_integrity.py [path/to/script.sql]"""
import subprocess, sys, tempfile, os
from pathlib import Path
import loaddb
ROOT = Path(__file__).resolve().parents[2]
src = sys.argv[1] if len(sys.argv) > 1 else str(ROOT / 'data.sql')
with tempfile.TemporaryDirectory() as d:
    db = os.path.join(d, 'x.db'); loaddb.load(src, db)
    print(subprocess.run(['sqlite3', db], stdin=open(Path(__file__).with_name('checks.sql')), capture_output=True, text=True).stdout)
