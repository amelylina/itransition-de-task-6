import json
from pathlib import Path
from common import RAW_DIR, copy_from_rows, truncate_locale_rows, download_file

CENSUS_URL = "https://api.census.gov/data/2010/surname?get=NAME,COUNT&RANK&RANK=1:2000"

def main():
    print("Loading en_US last names...")
    file_name = "us_last.json"
    file = RAW_DIR / file_name
    if not file.exists():
        download_file(CENSUS_URL, file)
    with open(file=file, mode="r", encoding="utf-8") as f:
        data:list[list] = json.load(f)

    if data[0] == ['NAME', 'COUNT', 'RANK']:
        data.pop(0)
    top = sorted(data, key=lambda x: int(x[2]))[:2000]

    rows_to_insert = []
    for rank, row in enumerate(top, start=1):
        name, count, _ = row
        weight = max(1, 2001 - rank)
        rows_to_insert.append(("en_US", "last", "u", name.title(), weight))

    truncate_locale_rows(table="names", locale="en_US", extra_filter={"name_type": "last"})
    copy_from_rows(
        table="names",
        columns=["locale", "name_type", "gender", "value", "freq_weight"],
        rows=rows_to_insert,
    )

if __name__=="__main__":
    main()