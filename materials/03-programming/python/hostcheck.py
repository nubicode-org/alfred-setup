#!/usr/bin/env python3
"""Check that hosts resolve and that a TCP port answers. Exits 1 if any host fails."""

import argparse
import socket
import sys
from dataclasses import dataclass


@dataclass
class Result:
    host: str
    ok: bool
    detail: str


def check(host: str, port: int, timeout: float) -> Result:
    try:
        address = socket.gethostbyname(host)
    except socket.gaierror as err:
        return Result(host, False, f"does not resolve ({err.strerror})")
    try:
        with socket.create_connection((address, port), timeout=timeout):
            return Result(host, True, f"{address}:{port} answered")
    except OSError as err:
        return Result(host, False, f"{address}:{port} {err.strerror or 'timed out'}")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("hosts", nargs="+", help="host names to check")
    parser.add_argument("--port", type=int, default=443, help="TCP port to try (default: 443)")
    parser.add_argument("--timeout", type=float, default=3.0, help="seconds per host (default: 3)")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    results = [check(host, args.port, args.timeout) for host in args.hosts]
    for r in results:
        print(f"{'ok  ' if r.ok else 'FAIL'}  {r.host:<30} {r.detail}")
    return 0 if all(r.ok for r in results) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
