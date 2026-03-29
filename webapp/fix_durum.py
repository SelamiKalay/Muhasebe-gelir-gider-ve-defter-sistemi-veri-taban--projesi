import sqlite3, os

db_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'muhasebe.db')
db = sqlite3.connect(db_path)
cur = db.cursor()

cur.execute("UPDATE MuhasebeFisleri SET Durum='Aktif' WHERE Durum IN ('Pasif','Iptal')")
print(f"Guncellenen fis sayisi: {cur.rowcount}")

db.commit()

toplam = cur.execute("SELECT COUNT(*) FROM MuhasebeFisleri").fetchone()[0]
aktif = cur.execute("SELECT COUNT(*) FROM MuhasebeFisleri WHERE Durum='Aktif'").fetchone()[0]
print(f"Toplam fis: {toplam}")
print(f"Aktif fis: {aktif}")

db.close()
