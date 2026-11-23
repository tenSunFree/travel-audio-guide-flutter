#!/usr/bin/env python3
"""Validate Flutter Web Dart defines without logging configuration values.

Usage: python scripts/validate_web_env.py env/web-staging.json
Only checks syntax and policy; it does not ping the endpoints.
"""
import ipaddress
import json
import sys
from pathlib import Path
from urllib.parse import urlparse

REQUIRED = ("SUPABASE_URL", "SUPABASE_PUBLISHABLE_KEY", "BACKEND_BASE_URL", "TAIPEI_API_BASE_URL")
URL_KEYS = ("SUPABASE_URL", "BACKEND_BASE_URL", "TAIPEI_API_BASE_URL")
PLACEHOLDERS = ("YOUR_", "REPLACE_ME", "example.com")
FORBIDDEN_HOSTS = {"localhost", "127.0.0.1", "0.0.0.0", "10.0.2.2"}
DIRECT_TAIPEI_HOSTS = {"www.travel.taipei", "travel.taipei"}


def is_public_host(host):
    """IP literals must be globally routable; hostnames fall through to other checks."""
    try:
        return ipaddress.ip_address(host).is_global
    except ValueError:
        return True


def validate(data):
    errors = []
    if not isinstance(data, dict):
        return ["root must be a JSON object"]
    for key in REQUIRED:
        value = data.get(key)
        if not isinstance(value, str) or not value.strip():
            errors.append(f"{key} is missing, empty, or not a string")
        elif any(p.lower() in value.lower() for p in PLACEHOLDERS):
            errors.append(f"{key} contains a placeholder")

    for key in URL_KEYS:
        value = data.get(key)
        if not isinstance(value, str) or not value.strip():
            continue
        try:
            parsed = urlparse(value.strip())
            host = parsed.hostname
            port = parsed.port  # validates bad port values
            if (parsed.scheme != "https" or not host or host in FORBIDDEN_HOSTS
                    or not is_public_host(host)
                    or parsed.username is not None or parsed.password is not None
                    or parsed.query or parsed.fragment or port == 0):
                errors.append(f"{key} must be a valid public HTTPS URL without credentials/query/fragment")
        except ValueError:
            errors.append(f"{key} is not a valid URL")
            continue

        if key == "TAIPEI_API_BASE_URL":
            if host in DIRECT_TAIPEI_HOSTS:
                errors.append("TAIPEI_API_BASE_URL must point to a CORS proxy, not travel.taipei")
            if parsed.path.rstrip('/') != "/open-api":
                errors.append("TAIPEI_API_BASE_URL path must be exactly /open-api")
    return errors


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python scripts/validate_web_env.py env/web-staging.json")
    path = Path(sys.argv[1])
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise SystemExit(f"Cannot read valid JSON at {path}: {type(exc).__name__}") from exc
    errors = validate(data)
    if errors:
        raise SystemExit("Invalid " + str(path) + ":\n - " + "\n - ".join(errors))
    print("OK: Web environment validated (endpoint reachability not checked).")


if __name__ == "__main__":
    main()