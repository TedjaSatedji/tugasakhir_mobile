import sqlite3

conn = sqlite3.connect('app.db')
cur = conn.cursor()

cur.execute('PRAGMA table_info(characters)')
cols = [row[1] for row in cur.fetchall()]
print('Existing columns:', cols)

if 'coins' not in cols:
    cur.execute('ALTER TABLE characters ADD COLUMN coins INTEGER NOT NULL DEFAULT 0')
    print('Added: coins')
if 'shop_upgrades' not in cols:
    cur.execute('ALTER TABLE characters ADD COLUMN shop_upgrades TEXT NOT NULL DEFAULT "{}"')
    print('Added: shop_upgrades')
if 'owned_frames' not in cols:
    cur.execute('ALTER TABLE characters ADD COLUMN owned_frames TEXT NOT NULL DEFAULT "[]"')
    print('Added: owned_frames')

conn.commit()
conn.close()
print('Migration complete.')
