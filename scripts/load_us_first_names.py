from pathlib import Path
import requests
from collections import defaultdict

from common import RAW_DIR, copy_from_rows, truncate_locale_rows, download_file

SSA_URL = "https://raw.githubusercontent.com/hackerb9/ssa-baby-names/refs/heads/main/raw-data/yob2020.txt"
TOP_N_PER_GENDER = 1000

def parse_file(file: Path) -> list[tuple[str, str, int]]:
    with file.open("r", encoding="utf-8") as f:
        rows = []
        for line in f:
            parts = line.strip().split(",")
            if len(parts) != 3:
                continue
            name, sex, count = parts
            rows.append((name, sex.lower(), int(count)))
    return rows

def main():
    print("Loading en_US first names...")
    file_name = "us_first.csv"
    file = RAW_DIR / file_name
    if not file.exists():
        download_file(SSA_URL, file)
    raw = parse_file(file)

    by_gender: dict[str, list[tuple[str, int]]] = defaultdict(list)
    for name, sex, count in raw:
        by_gender[sex].append((name, count))

    rows_to_insert = []
    for gender in ("m", "f"):
        top = sorted(by_gender[gender], key=lambda x: -x[1])[:TOP_N_PER_GENDER]
        for name, count in top:
            weight = max(1, count // 10)
            rows_to_insert.append(("en_US", "first", gender, name, weight))

    truncate_locale_rows(table="names", locale="en_US", extra_filter={"name_type": "first"})
    copy_from_rows(
        table="names",
        columns=["locale", "name_type", "gender", "value", "freq_weight"],
        rows=rows_to_insert,
    )

if __name__ == "__main__":
    main()