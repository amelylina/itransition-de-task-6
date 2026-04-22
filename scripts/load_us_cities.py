import csv
from common import PROJECT_ROOT, copy_from_rows, truncate_locale_rows

CITIES_FILE = PROJECT_ROOT / "data" / "seed" / "us_cities.csv"

def main():
    print("Loading en_US cities...")
    rows = []
    with CITIES_FILE.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rank = int(r["rank"])
            rows.append((
                "en_US",
                r["city"],
                r["region"],
                r["postal_code"],
                max(1, 501 - rank),
            ))

    truncate_locale_rows("cities", locale="en_US")
    copy_from_rows(
        "cities",
        ["locale", "city", "region", "postal_code", "freq_weight"],
        rows,
    )

if __name__ == "__main__":
    main()