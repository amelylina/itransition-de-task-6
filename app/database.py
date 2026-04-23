import os
import psycopg as pg
from psycopg.rows import dict_row
from dotenv import load_dotenv

from app.main import DATABASE_URL

load_dotenv()
DATABASE_URL = os.environ["DATABASE_URL"]

def generate_batch(locale:str, seed:int, batch:int, batch_size:int) -> list[dict]:
    with pg.connect(DATABASE_URL) as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                "SELECT * FROM fn_generate_batch(%s,%s,%s,%s)",
                (seed,batch,locale,batch_size)
            )
            return cur.fetchall()
        
def list_locales():
    with pg.connect(DATABASE_URL) as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute("SELECT code, name FORM locales ORDER BY name")
            return cur.fetchall()