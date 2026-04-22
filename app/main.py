from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import psycopg
import os

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://faker:faker@localhost:5432/sqlfaker"
)

app = FastAPI()

@app.get("/", response_class=HTMLResponse)
def index():
    with psycopg.connect(DATABASE_URL) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT version(), now()")
            version, now = cur.fetchone()
    return f"""
    <h1>SQL Faker — plumbing check</h1>
    <p><strong>Postgres version:</strong> {version}</p>
    <p><strong>Server time:</strong> {now}</p>
    """
