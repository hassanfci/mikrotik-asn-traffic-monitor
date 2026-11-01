# Windows ASN Prefix Collector — সম্পূর্ণ বাংলা গাইড

এই গাইডে **Step 1: Script তৈরি → Step 2: Script চালানো → Step 3: MikroTik-এ Import** সব একসঙ্গে রয়েছে।

**প্রয়োজন:** Windows, Python 3.9+ এবং ইন্টারনেট। CMD-তে `py --version` দিয়ে Python পরীক্ষা করুন।

## Step 1: ASN Prefix Collector তৈরি করুন

Windows CMD-তে লিখুন:

```cmd
notepad "%USERPROFILE%\Desktop\asn_collector.py"
```

Notepad খুললে নিচের **সম্পূর্ণ Python Code** কপি-পেস্ট করে **Ctrl+S** দিয়ে Save করুন।

```python
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
```

**বিকল্প:** পুরো Code কপি না করে GitHub থেকে [asn_collector.py](../tools/asn_collector.py) ফাইলটি Download করে Desktop-এ একই নামে রাখুন।

## Step 2: Script চালান

CMD-তে লিখুন:

```cmd
py "%USERPROFILE%\Desktop\asn_collector.py"
```

এরপর আপনার পছন্দের ASN লিখুন, যেমন:

```text
Enter ASN (example AS3333): AS3333
```

সফল হলে **Desktop-এ `AS3333_mikrotik.rsc`** ফাইল তৈরি হবে। Output-এ Prefix count-ও দেখা যাবে। Script RIPEstat API থেকে সম্প্রতি পর্যবেক্ষিত IPv4 prefixes সংগ্রহ করে।

> Windows Desktop যদি OneDrive-তে redirect করা থাকে, CMD-তে script-এর path এবং script-এর output location ঠিক করতে হবে।

## Step 3: MikroTik RouterOS v7-এ Import

1. তৈরি হওয়া `.rsc` ফাইল Notepad-এ খুলে **Prefix এবং List Name যাচাই** করুন।
2. WinBox → Files-এ ফাইলটি Upload করুন।
3. Terminal-এ লিখুন:

```routeros
/import file-name=AS3333_mikrotik.rsc
```

4. Address List পরীক্ষা করুন:

```routeros
/ip firewall address-list print count-only where list=ASN_AS3333
```

এই interactive script `ASN_AS3333` format ব্যবহার করে, অর্থাৎ DIT-CORE-এর `ASN_AS15169` Mangle naming convention-এর সঙ্গে মেলে।

### Important: Production Safety

- Python Script নিজে Router-এর কোনো Configuration পরিবর্তন করে না। কিন্তু **`.rsc` Import Address List-এ entry যোগ করে**।
- Import পুরোনো Prefix মুছে দেয় না; বারবার Import করলে Duplicate হতে পারে।
- API-তে recently observed BGP Prefix পাওয়া যায়, guaranteed live origin ASN mapping নয়।
- Production ISP Core-এ Import-এর আগে backup, preview এবং CPU usage যাচাই করুন।
- বড় Prefix List এবং Mangle rules দিয়ে সব ASN একসঙ্গে monitor করলে CPU load বাড়তে পারে।

## Alternative: Multiple ASNs in one command

[CLI Prefix Collector](../tools/asn_to_mikrotik.py) ব্যবহার করে:

```cmd
py tools\asn_to_mikrotik.py 15169 32934 13335
```

**Naming difference:** CLI version সাধারণত `AS15169` list তৈরি করে, interactive version `ASN_AS15169` তৈরি করে। Router-এর Mangle rule-এর সঙ্গে মিলিয়ে Import করুন।
