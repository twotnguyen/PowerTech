import sqlite3, sqlparse, sys
def load(path, db=':memory:'):
    lines, rows = sqlparse.parse(path)
    con = sqlite3.connect(db); done=set()
    for ln,_,t,c,raw in rows:
        if t not in done:
            con.execute(f'create table "{t}" ({",".join(chr(34)+x+chr(34) for x in c)})'); done.add(t)
        con.execute(f'insert into "{t}" values ({",".join("?"*len(c))})', [sqlparse.decode(r) for r in raw])
    con.commit(); return con, rows
if __name__=='__main__':
    load('/Users/twot/Documents/CODE/PowerTech/data.sql','/private/tmp/claude-501/-Users-twot-Documents-CODE-PowerTech/4c79c87b-f515-4709-9e18-967b28b1e7a6/scratchpad/orig.db')
