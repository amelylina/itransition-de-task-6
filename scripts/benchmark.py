import statistics
import time
from common import get_connection

SIZES = [10, 100, 1000, 10000]
RUNS_PER_SIZE = 5
LOCALES = ["en_US", "de_DE"]

def bench_one(conn, locale: str, seed: int, batch: int, size: int) -> tuple[float, float]:
    with conn.cursor() as cur:
        cur.execute("SELECT 1")

    t0 = time.perf_counter()
    with conn.cursor() as cur:
        cur.execute(
            "SELECT * FROM fn_generate_batch(%s, %s, %s, %s)",
            (seed, batch, locale, size),
        )
        rows = cur.fetchall()
    t1 = time.perf_counter()
    roundtrip = t1 - t0
    assert len(rows) == size, f"expected {size} rows, got {len(rows)}"

    with conn.cursor() as cur:
        cur.execute(
            "EXPLAIN (ANALYZE, TIMING ON, FORMAT JSON) "
            "SELECT * FROM fn_generate_batch(%s, %s, %s, %s)",
            (seed, batch, locale, size),
        )
        plan = cur.fetchone()[0]
    exec_ms = plan[0]["Execution Time"]
    server = exec_ms / 1000.0

    return server, roundtrip


def main():
    print(f"{'Locale':>6} {'Size':>6} {'Server s':>10} {'RT s':>10} {'Server u/s':>12} {'RT u/s':>10}")
    print("-" * 60)

    with get_connection() as conn:
        for locale in LOCALES:
            for size in SIZES:
                server_times = []
                rt_times = []
                for run in range(RUNS_PER_SIZE):
                    s, rt = bench_one(conn, locale, seed=42, batch=run, size=size)
                    server_times.append(s)
                    rt_times.append(rt)

                s_med = statistics.median(server_times)
                rt_med = statistics.median(rt_times)
                s_ups = size / s_med
                rt_ups = size / rt_med

                print(f"{locale:>6} {size:>6} {s_med:>10.3f} {rt_med:>10.3f} "
                    f"{s_ups:>12.0f} {rt_ups:>10.0f}")


if __name__ == "__main__":
    main()