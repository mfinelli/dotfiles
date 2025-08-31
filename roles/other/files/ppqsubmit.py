#!/usr/bin/env python3
"""
pocket-portal ingest client

Usage:
  python ingest.py https://example.com
  python ingest.py --yes https://example.com
  python ingest.py                 # will prompt for URL interactively

Flags:
  -y, --yes    Run non-interactively (skip prompts). If used, you MUST pass the URL
               on the command line; otherwise the script errors.

Environment (required):
  POCKET_PORTAL_INGEST_URL   e.g. https://pocket-portal.example.com/ingest
  POCKET_PORTAL_INGEST_TOKEN Bearer token for the /ingest endpoint
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from typing import Any, Dict, Optional
from urllib.parse import urlparse
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError


def is_http_url(value: str) -> bool:
    """Return True iff value is an absolute http/https URL."""
    try:
        parsed = urlparse(value.strip())
        return parsed.scheme in ("http", "https") and bool(parsed.netloc)
    except Exception:
        return False


def prompt(label: str) -> Optional[str]:
    """Prompt once; treat empty string as None."""
    try:
        s = input(f"{label}: ").strip()
    except EOFError:
        s = ""
    return s if s else None


def build_payload(url: str, tags: Optional[str], collection: Optional[str], note: Optional[str]) -> Dict[str, Any]:
    """Only include the four allowed keys; omit nulls."""
    payload: Dict[str, Any] = {"url": url}
    if tags is not None:
        payload["tags"] = tags
    if note is not None:
        payload["note"] = note
    if collection is not None:
        payload["collection"] = collection
    return payload


def main() -> int:
    parser = argparse.ArgumentParser(description="Submit a link to pocket-portal /ingest")
    parser.add_argument("url", nargs="?", help="The URL to save (http/https). If omitted, you will be prompted (unless --yes).")
    parser.add_argument("-y", "--yes", action="store_true", help="Skip interactive prompts (non-interactive mode).")
    args = parser.parse_args()

    ingest_url = os.getenv("POCKET_PORTAL_INGEST_URL")
    token = os.getenv("POCKET_PORTAL_INGEST_TOKEN")

    if not ingest_url:
        print("Error: POCKET_PORTAL_INGEST_URL env var is required.", file=sys.stderr)
        return 2
    if not token:
        print("Error: POCKET_PORTAL_INGEST_TOKEN env var is required.", file=sys.stderr)
        return 2

    # Determine URL (positional arg or prompt)
    url_arg = args.url
    if args.yes:
        if not url_arg:
            print("Error: --yes was given but no URL argument provided.", file=sys.stderr)
            return 2
        if not is_http_url(url_arg):
            print("Error: URL must be an absolute http/https URL.", file=sys.stderr)
            return 2
        url_value = url_arg.strip()
        # Non-interactive: skip prompts; treat others as None
        tags = None
        collection = None
        note = None
    else:
        # Interactive
        if not url_arg:
            while True:
                url_in = prompt("URL")
                if url_in and is_http_url(url_in):
                    url_value = url_in.strip()
                    break
                print("Please enter a valid absolute http/https URL.")
        else:
            if not is_http_url(url_arg):
                print("Error: URL must be an absolute http/https URL.", file=sys.stderr)
                return 2
            url_value = url_arg.strip()

        tags = prompt("Tags (optional)")
        collection = prompt("Collection (optional)")
        note = prompt("Note (optional)")

    payload = build_payload(url_value, tags, collection, note)

    # Prepare request (standard library; no requests dependency)
    data = json.dumps(payload).encode("utf-8")
    req = Request(
        ingest_url,
        method="POST",
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )

    try:
        with urlopen(req, timeout=20) as resp:
            resp_body = resp.read()
            try:
                parsed = json.loads(resp_body.decode("utf-8"))
            except Exception:
                print(f"Error: non-JSON response (HTTP {resp.getcode()}): {resp_body!r}", file=sys.stderr)
                return 1

            if isinstance(parsed, dict) and parsed.get("ok") is True:
                link_id = parsed.get("id")
                print(f"Queued OK: id={link_id}")
                return 0
            else:
                print(f"Server error: {parsed}", file=sys.stderr)
                return 1

    except HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"HTTP {e.code}: {body}", file=sys.stderr)
        return 1
    except URLError as e:
        print(f"Network error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
