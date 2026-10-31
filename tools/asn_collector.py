#!/usr/bin/env python3
"""Interactive Windows ASN to MikroTik .rsc converter (Python 3.9+)."""
import ipaddress
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen

def parse_time(value):
    if not value:
        return None
    try:
        d = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        return d.replace(tzinfo=timezone.utc) if d.tzinfo is None else d.astimezone(timezone.utc)
    except (TypeError, ValueError):
        return None

def main():
    raw = input("Enter ASN (example AS3333): ").strip().upper()
    number = raw.removeprefix("AS")
    if not number.isdecimal() or not 1 <= int(number) <= 4294967295:
        raise ValueError("Invalid ASN. Enter e.g. AS3333 or 3333.")
    asn = "AS" + str(int(number))
    url = "https://stat.ripe.net/data/announced-prefixes/data.json?" + urlencode({
        "resource": asn, "min_peers_seeing": 10
    })
    request = Request(url, headers={"User-Agent": "asn-collector-windows/1.0"})
    with urlopen(request, timeout=45) as response:
        payload = json.load(response)
    data = payload.get("data", {})
    if payload.get("status") != "ok" or not isinstance(data.get("prefixes"), list):
        raise RuntimeError("RIPEstat response is invalid.")
    latest = parse_time(data.get("latest_time")) or parse_time(data.get("query_endtime"))
    if latest is None:
        raise RuntimeError("RIPEstat did not provide a usable data timestamp.")
    cutoff = latest - timedelta(hours=48)
    networks = set()
    for item in data["prefixes"]:
        try:
            network = ipaddress.ip_network(item["prefix"], strict=False)
            if network.version != 4:
                continue
            timeline = item.get("timelines", [])
            if any((parse_time(t.get("endtime")) or latest) >= cutoff
                   for t in timeline if isinstance(t, dict)):
                networks.add(network)
        except (KeyError, ValueError, TypeError):
            continue
    if not networks:
        raise RuntimeError("No recently observed IPv4 prefixes. Existing router lists remain unchanged.")
    ordered = sorted(networks, key=lambda p: (int(p.network_address), p.prefixlen))
    output = Path.home() / "Desktop" / (asn + "_mikrotik.rsc")
    if not output.parent.is_dir():
        raise RuntimeError("Desktop directory not found. On OneDrive-redirected desktops, update the output path.")
    lines = [
        "# RIPEstat recently observed IPv4 prefixes for " + asn,
        "# Latest RIPEstat timestamp: " + latest.isoformat(),
        "# Additive import, does NOT remove old/duplicate entries.",
        "/ip firewall address-list"
    ]
    lines.extend('add list=ASN_' + asn + ' address=' + str(n) +
                 ' comment="RIPEstat ' + asn + '"' for n in ordered)
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("Saved:", output)
    print("Prefix count:", len(ordered))
    print("MikroTik address-list name: ASN_" + asn)
    if datetime.now(timezone.utc) - latest > timedelta(days=3):
        print("WARNING: RIPEstat data is more than 3 days old. Verify before import.")

if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print("ERROR:", exc)
        raise SystemExit(1)
