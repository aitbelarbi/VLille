#!/usr/bin/env python3
"""
Check which CityBike networks return 0 stations.

The API allows 300 requests/hour. With 795 networks use --delay 13 to stay safe.

Usage:
  python3 check_citybike_networks.py --delay 13          # safe (~3h, stays under 300/h)
  python3 check_citybike_networks.py --delay 13 --out results.json
"""

import argparse
import json
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

BASE_URL   = "https://api.citybik.es/v2"
TIMEOUT    = 12
MAX_RETRY  = 5
RETRY_WAIT = 2.0  # seconds between retries (doubles each attempt)


def get_with_retry(url: str) -> requests.Response:
    wait = RETRY_WAIT
    for attempt in range(MAX_RETRY):
        resp = requests.get(url, timeout=TIMEOUT)
        if resp.status_code != 429:
            return resp
        time.sleep(wait)
        wait *= 2
    return resp  # return last 429 if all retries exhausted


def fetch_networks() -> list:
    resp = get_with_retry(f"{BASE_URL}/networks")
    resp.raise_for_status()
    return resp.json()["networks"]


def check_network(network: dict) -> dict:
    network_id = network["id"]
    loc = network.get("location", {})
    base = {
        "id":      network_id,
        "name":    network.get("name", ""),
        "city":    loc.get("city", ""),
        "country": loc.get("country", ""),
    }
    try:
        resp = get_with_retry(f"{BASE_URL}/networks/{network_id}?fields=stations")
        if resp.status_code != 200:
            return {**base, "stations": -1, "error": f"HTTP {resp.status_code}"}
        count = len(resp.json()["network"]["stations"])
        return {**base, "stations": count}
    except requests.exceptions.Timeout:
        return {**base, "stations": -1, "error": "timeout"}
    except Exception as e:
        return {**base, "stations": -1, "error": str(e)}


def print_table(rows: list[dict], extra_col: str | None = None):
    for r in sorted(rows, key=lambda x: (x["country"], x["city"])):
        line = f"  {r['id']:<42} {r['name']:<28} {r['city']}, {r['country']}"
        if extra_col and extra_col in r:
            line += f"  — {r[extra_col]}"
        print(line)


def main():
    parser = argparse.ArgumentParser(description="Check empty CityBike networks")
    parser.add_argument("--workers", type=int, default=1, help="Concurrent requests (default: 1)")
    parser.add_argument("--delay", type=float, default=0.0, help="Seconds to wait between requests (use 13 to stay under 300 req/h)")
    parser.add_argument("--out", type=str, help="Save full results as JSON to this file")
    args = parser.parse_args()

    print("Fetching network list…")
    try:
        networks = fetch_networks()
    except Exception as e:
        print(f"Failed to fetch network list: {e}", file=sys.stderr)
        sys.exit(1)

    total = len(networks)
    print(f"Found {total} networks. Checking stations (workers={args.workers})…\n")

    results = []
    if args.delay > 0 or args.workers == 1:
        # Sequential with optional delay to respect rate limit
        for i, network in enumerate(networks, 1):
            print(f"\r  {i}/{total}", end="", flush=True)
            results.append(check_network(network))
            if args.delay > 0 and i < total:
                time.sleep(args.delay)
    else:
        done = 0
        with ThreadPoolExecutor(max_workers=args.workers) as executor:
            futures = {executor.submit(check_network, n): n for n in networks}
            for future in as_completed(futures):
                done += 1
                print(f"\r  {done}/{total}", end="", flush=True)
                results.append(future.result())

    print("\n")

    ok     = [r for r in results if r["stations"] > 0]
    empty  = [r for r in results if r["stations"] == 0]
    errors = [r for r in results if r["stations"] == -1]

    print(f"✅  {len(ok)} networks with stations")

    print(f"\n❌  {len(empty)} networks with 0 stations:")
    if empty:
        print_table(empty)
    else:
        print("  (none)")

    print(f"\n⚠️   {len(errors)} networks unreachable or errored:")
    if errors:
        print_table(errors, extra_col="error")
    else:
        print("  (none)")

    if args.out:
        with open(args.out, "w") as f:
            json.dump({"ok": ok, "empty": empty, "errors": errors}, f, indent=2, ensure_ascii=False)
        print(f"\nResults saved to {args.out}")


if __name__ == "__main__":
    main()
