from pathlib import Path
from scripts.common import get_connection, PROJECT_ROOT

SQL_DIR = PROJECT_ROOT / "sql"

SQL_FILES = sorted(SQL_DIR.glob("*.sql"))

def main():
    print(f"Initializing database from {len(SQL_FILES)} SQL files...")
    with get_connection() as conn:
        with conn.cursor() as cur:
            for path in SQL_FILES:
                print(f"  [run] {path.name}")
                sql = path.read_text(encoding="utf-8")
                cur.execute(sql)
        conn.commit()
    print("Done.")

if __name__ == "__main__":
    main()