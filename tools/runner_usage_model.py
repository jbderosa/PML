#!/usr/bin/env python3
"""PML v2.6 — GitHub Actions billable-minutes model (per month), not jobs/day.

GitHub facts used (verified 2026-09-28, docs.github.com "GitHub Actions billing" + GitHub pricing notes):
  * GitHub Free: 2,000 included minutes/month for PRIVATE repos (Linux 1x multiplier).
  * Standard GitHub-hosted runners are free in PUBLIC repos.
  * Minutes are counted per JOB and rounded UP to the whole minute.
  * Self-hosted runners: currently free; a $0.002/min platform charge announced for 2026 was postponed
    (would not apply to public repos).

Model: each invocation is ONE job (the workflow has one job). duration = overhead + items*per_item +
doorbell_step (if rings) ; billed = ceil(duration/60). Retries add re-runs.  Simulated minute-by-minute over
30 days with Poisson-ish arrival of PY items and doorbell rings, coalesced by the engine's dispatch rules
(one run in flight, min interval between dispatches, py_units_per_run batch cap).
"""
import math
import random
import sys

DAYS = 30
FREE_PRIVATE = 2000


def simulate(name, *, cron_min, dispatch=True, min_interval=10, py_items_day=150, rings_day=0,
             overhead_s=35, per_item_s=3.0, ring_step_s=4, batch_cap=25, retry_rate=0.03, seed=1):
    rnd = random.Random(seed)
    minutes = DAYS * 24 * 60
    py_rate = py_items_day / (24 * 60)
    ring_rate = rings_day / (24 * 60)
    pend_py = pend_rings = 0
    last_dispatch = -10 ** 9
    busy_until = -1
    runs = billed = 0
    for t in range(minutes):
        pend_py += sum(1 for _ in range(3) if rnd.random() < py_rate / 3)
        pend_rings += sum(1 for _ in range(3) if rnd.random() < ring_rate / 3)
        cron = cron_min and t % cron_min == 0
        want = dispatch and (pend_py or pend_rings) and t - last_dispatch >= min_interval
        if t >= busy_until and (cron or want):
            if want and not cron:
                last_dispatch = t
            items = min(pend_py, batch_cap)
            dur = overhead_s + items * per_item_s + (ring_step_s if pend_rings else 0)
            pend_py -= items
            pend_rings = 0
            b = math.ceil(dur / 60)
            runs += 1
            billed += b
            if rnd.random() < retry_rate:
                runs += 1
                billed += b
            busy_until = t + b
    return {"scenario": name, "runs": runs, "billed_min": billed, "private_ok": billed <= FREE_PRIVATE}


SCENARIOS = [
    ("A. cron 30 min only (v2.5 fallback alone)", dict(cron_min=30, dispatch=False)),
    ("B. cron 30 + PY dispatch (min 10 min), 150 PY items/day", dict(cron_min=30, py_items_day=150)),
    ("C. cron 60 + PY dispatch (min 60 min), 150 items/day", dict(cron_min=60, min_interval=60, py_items_day=150)),
    ("D. EVENT: 400 rings/day via runner, dispatch min 10", dict(cron_min=30, py_items_day=150, rings_day=400)),
    ("E. EVENT: 400 rings/day, dispatch min 5", dict(cron_min=30, py_items_day=150, rings_day=400, min_interval=5)),
    ("F. heavy PY: 1,000 items/day, cron 30 + dispatch 10", dict(cron_min=30, py_items_day=1000)),
    ("G. B with slow jobs (8 s/item) — rounding pushes runs to 2+ min", dict(cron_min=30, py_items_day=150, per_item_s=8)),
]


def main(out=sys.stdout):
    out.write("| Scenario | Runs/month | Billed min/month | Fits private free tier (2,000)? | Public repo |\n")
    out.write("|---|---:|---:|:---:|:---:|\n")
    rows = []
    for name, kw in SCENARIOS:
        r = simulate(name, **kw)
        rows.append(r)
        out.write("| %s | %d | %d | %s | free |\n" % (name, r["runs"], r["billed_min"], "yes" if r["private_ok"] else "**NO**"))
    return rows


if __name__ == "__main__":
    main()
