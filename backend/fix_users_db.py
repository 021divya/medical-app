import sqlite3

# Apne sql_app.db ka sahi path yahan likho
conn = sqlite3.connect("sql_app.db")
cursor = conn.cursor()

# Pehle dekho kya hai abhi
print("=== BEFORE FIX ===")
cursor.execute("SELECT id, full_name, email, role FROM users")
for r in cursor.fetchall():
    print(r)

# ─────────────────────────────────────────────
# Fix: Jo users galat hain unka full_name aur
# email swap tha — ab sahi karo
# ─────────────────────────────────────────────
cursor.execute("""
    UPDATE users
    SET full_name = email,
        email = full_name
    WHERE email NOT LIKE '%@%'
""")

conn.commit()

# Verify
print("\n=== AFTER FIX ===")
cursor.execute("SELECT id, full_name, email, role FROM users")
for r in cursor.fetchall():
    print(r)

conn.close()
print("\n✅ Done! DB fix ho gayi.")