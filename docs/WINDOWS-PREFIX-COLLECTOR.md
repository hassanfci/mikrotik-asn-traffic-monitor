# Windows Python prefix collector

The original Windows prefix collector is at [tools/asn_to_mikrotik.py](../tools/asn_to_mikrotik.py).

Run from Windows CMD (Python 3.9+):

```bat
py tools\asn_to_mikrotik.py 15169 32934 13335
```

This uses Python's **standard library only** and the RIPEstat announced-prefixes endpoint. It creates `AS15169.rsc`, `AS32934.rsc`, etc., in your current working folder.

For a separate output directory:

```bat
py tools\asn_to_mikrotik.py 15169 --out output
```

## Important list-name mismatch

The original script exports firewall address lists named `AS15169`, but the DIT-CORE example Mangle rules use `ASN_AS15169`. **These names do not match**: imported lists named `AS15169` will not be counted by existing `ASN_AS15169` rules.

Before importing, open the generated `.rsc` file and change `list=AS15169` to `list=ASN_AS15169` (and likewise for other ASN values if using that naming scheme). Verify the output file and backup your router first.

Importing a generated file is additive, not a safe sync: it does **not** remove stale prefixes and may duplicate entries if repeatedly imported. No router configuration is changed by running the Python script itself.

Data reflects recently observed BGP announcements, not guaranteed real-time current routes. Verify mapping and CPU before deploying to an ISP production core.
