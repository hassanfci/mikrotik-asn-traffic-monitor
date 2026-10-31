#!/usr/bin/env python3
"""Export recently observed IPv4 prefixes for ASNs into MikroTik RouterOS v7 .rsc files.
Uses RIPEstat announced-prefixes API. Python standard library only.
This does NOT connect to or modify a router.
"""
import argparse
from datetime import datetime, timezone, timedelta
from ipaddress import ip_network
from pathlib import Path
import json
import sys
from urllib.parse import urlencode
from urllib.request import Request, urlopen

API = 'https://stat.ripe.net/data/announced-prefixes/data.json'

def dt(value):
    if not value:
        return None
    if isinstance(value, (float, int)):
        return datetime.fromtimestamp(value, timezone.utc)
    try:
        parsed = datetime.fromisoformat(str(value).replace('Z', '+00:00'))
        return parsed.replace(tzinfo=timezone.utc) if parsed.tzinfo is None else parsed.astimezone(timezone.utc)
    except (ValueError, TypeError, OverflowError):
        return None

def collect(asn, hours, min_peers):
    url = API + '?' + urlencode({'resource': f'AS{asn}', 'min_peers_seeing': min_peers})
    request = Request(url, headers={'User-Agent': 'asn-to-routeros/1.0 (RIPEstat API)', 'Accept': 'application/json'})
    with urlopen(request, timeout=45) as resp:
        payload = json.load(resp)
    if payload.get('status') != 'ok' or not isinstance(payload.get('data', {}).get('prefixes'), list):
        raise ValueError(f'API status invalid: {payload.get("status")}')
    data = payload['data']
    latest = dt(data.get('latest_time')) or dt(data.get('query_endtime'))
    if not latest:
        raise ValueError('API did not provide a usable latest_time/query_endtime')
    cutoff = latest - timedelta(hours=hours)
    prefixes = set()
    for item in data['prefixes']:
        try:
            network = ip_network(item['prefix'], strict=False)
        except (KeyError, ValueError, TypeError):
            continue
        if network.version != 4:
            continue
        timelines = item.get('timelines', [])
        if not isinstance(timelines, list):
            continue
        if any((dt(t.get('endtime')) or latest) >= cutoff for t in timelines if isinstance(t, dict)):
            prefixes.add(network)
    return sorted(prefixes, key=lambda p: (int(p.network_address), p.prefixlen)), latest

def main():
    parser = argparse.ArgumentParser(description='RIPEstat ASN -> MikroTik address-list .rsc')
    parser.add_argument('asns', nargs='+', help='ASN(s), e.g. 15169 32934 or AS13335')
    parser.add_argument('--hours', type=int, default=48, help='Observation window relative to RIPE latest data (default: 48)')
    parser.add_argument('--min-peers', type=int, default=10, help='Minimum RIS peers seeing a prefix (default: 10)')
    parser.add_argument('--out', default='.', help='Output directory (default: current folder)')
    args = parser.parse_args()
    if not (1 <= args.hours <= 336 and 1 <= args.min_peers <= 10000):
        parser.error('--hours must be 1..336 and --min-peers must be 1..10000')
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    failed = False
    for raw_asn in args.asns:
        value = raw_asn.upper().removeprefix('AS')
        if not value.isdecimal() or not 1 <= int(value) <= 4294967295:
            print(f'Invalid ASN: {raw_asn}', file=sys.stderr)
            failed = True
            continue
        asn = str(int(value))
        try:
            prefixes, latest = collect(asn, args.hours, args.min_peers)
            if not prefixes:
                raise ValueError('No recently observed IPv4 prefixes; no file generated')
            outfile = out / f'AS{asn}.rsc'
            lines = [f'# AS{asn} recently observed IPv4 prefixes from RIPEstat',
                     f'# RIPE latest data: {latest.isoformat()}; window: {args.hours}h; min peers: {args.min_peers}',
                     '# Import adds entries only. It does not remove old ones or replace an existing list.',
                     '/ip firewall address-list']
            lines += [f'add list=AS{asn} address={network} comment="RIPEstat AS{asn}"' for network in prefixes]
            outfile.write_text('\n'.join(lines) + '\n', encoding='utf-8')
            age = datetime.now(timezone.utc) - latest
            print(f'AS{asn}: {len(prefixes)} IPv4 prefixes -> {outfile} (RIPE latest: {latest.isoformat()})')
            if age > timedelta(days=3):
                print(f'WARNING: RIPE dataset timestamp is {age.days} days old. Check freshness before import.', file=sys.stderr)
        except Exception as exc:
            print(f'AS{asn}: ERROR: {exc}', file=sys.stderr)
            failed = True
    return 1 if failed else 0

if __name__ == '__main__':
    sys.exit(main())
