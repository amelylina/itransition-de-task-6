from scripts.common import get_connection
from scripts.load_us_first_names import main as load_us_first
from scripts.load_us_last_names import main as load_us_last
from scripts.load_de_names import main as load_de_names
from scripts.load_us_cities import main as load_us_cities
from scripts.load_de_cities import main as load_de_cities

def seed_middle_names():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                DELETE FROM names WHERE name_type = 'middle';
                INSERT INTO names (locale, name_type, gender, value, freq_weight)
                SELECT locale, 'middle', gender, value,
                    GREATEST(freq_weight / 10, 1)
                FROM names WHERE name_type = 'first';
            """)
        conn.commit()

def rebuild_cache():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT fn_rebuild_picker_cache();")
        conn.commit()

def main():
    load_us_first()
    load_us_last()
    load_de_names()
    seed_middle_names()
    load_us_cities()
    load_de_cities()
    rebuild_cache()
    print("All data loaded and cache rebuilt.")

if __name__ == "__main__":
    main()