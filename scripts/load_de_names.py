import csv
from common import PROJECT_ROOT, copy_from_rows, truncate_locale_rows

SEED_DIR = PROJECT_ROOT / "data" / "seed"
FIRST_NAMES_FILE = SEED_DIR / "de_firstnames.csv"
LAST_NAMES_FILE = SEED_DIR / "de_surnames.csv"

def load_first_names() -> list[tuple]:
    rows = []
    with FIRST_NAMES_FILE.open("r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for r in reader:
            name = r["name"].strip()
            gender = r["gender"].strip().lower()
            rank = int(r["rank"])
            if gender not in ("m", "f", "u"):
                print(f"  [warn] skipping {gender!r} for {name!r}")
                continue
            rows.append((rank, gender, name))

    total = len(rows)
    insert_rows = []
    for rank, gender, name in rows:
        weight = max(1, total + 1 - rank)
        insert_rows.append(("de_DE", "first", gender, name, weight))
    return insert_rows

def load_last_names() -> list[tuple]:
    rows = []
    with LAST_NAMES_FILE.open("r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for r in reader:
            name = r["name"].strip()
            rank = int(r["rank"])
            rows.append((rank, name))

    total = len(rows)
    insert_rows = []
    for rank, name in rows:
        weight = max(1, total + 1 - rank)
        insert_rows.append(("de_DE", "last", "u", name, weight))
    return insert_rows

def main():
    print("Loading de_DE first names...")
    first_rows = load_first_names()

    print("Loading de_DE last names...")
    last_rows = load_last_names()

    truncate_locale_rows("names", locale="de_DE", extra_filter={"name_type": "first"})
    truncate_locale_rows("names", locale="de_DE", extra_filter={"name_type": "last"})

    copy_from_rows(
        table="names",
        columns=["locale", "name_type", "gender", "value", "freq_weight"],
        rows=first_rows + last_rows,
    )

if __name__ == "__main__":
    main()