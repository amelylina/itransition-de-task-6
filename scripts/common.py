# common.py
import os
from pathlib import Path
from dotenv import load_dotenv
import psycopg as pg
from psycopg import sql
import requests

load_dotenv()

DATABASE_URL = os.environ["DATABASE_URL"]

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_ROOT / 'data' / 'raw'
PROCESSED_DIR = PROJECT_ROOT / 'data' / 'processed'
RAW_DIR.mkdir(parents=True, exist_ok=True)
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

def get_connection():
    return pg.connect(DATABASE_URL)

def copy_from_rows(table: str, columns: list[str], rows:list[tuple]):
    if not rows:
        print(f"[SKIP] no rows to insert into {table}")
        return
    
    stmt = sql.SQL("COPY {tbl} ({cols}) FROM STDIN").format(
        tbl=sql.Identifier(table),
        cols=sql.SQL(", ").join(map(sql.Identifier, columns)),
    )
    with get_connection() as conn:
        with conn.cursor() as cur:
            with cur.copy(stmt) as cp:
                for row in rows:
                    cp.write_row(row)
        conn.commit()
    print(f"[OK] Inserted {len(rows)} rows into {table}")

def truncate_locale_rows(table: str, locale: str | None = None, extra_filter: dict | None = None):
    with get_connection() as conn:
        with conn.cursor() as cur:
            if locale is None and not extra_filter:
                cur.execute(sql.SQL("TRUNCATE {} RESTART IDENTITY CASCADE").format(sql.Identifier(table)))
                print(f"[CLEAN] truncated {table}")
                conn.commit()
                return

            conditions = []
            params = []
            if locale is not None:
                conditions.append(sql.SQL("locale = %s"))
                params.append(locale)
            if extra_filter:
                for col, val in extra_filter.items():
                    conditions.append(sql.SQL("{} = %s").format(sql.Identifier(col)))
                    params.append(val)

            stmt = sql.SQL("DELETE FROM {} WHERE ").format(sql.Identifier(table)) + sql.SQL(" AND ").join(conditions)
            cur.execute(stmt, params)
            print(f"[CLEAN] deleted from {table} ({cur.rowcount} rows)")
        conn.commit()

def download_file(url:str, local_file:Path):
    resp = requests.get(
        url,
        headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"},
        timeout=60,
    )
    resp.raise_for_status()
    local_file.write_bytes(resp.content)
    return
