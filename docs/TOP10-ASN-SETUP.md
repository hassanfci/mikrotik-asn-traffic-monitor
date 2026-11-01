# Top 10 ASN Live Traffic Ranking (RouterOS v7)

**Status: experimental; review and lab-test before using on a production ISP core.**

This is a **read-only, one-shot 5-second sampled Top 10 ranking of selected ASNs**, not an automatic discovery of every ASN. It uses the existing Mangle byte counters and does not add or modify any rules.

## Prerequisites

- IPv4 address-list prefixes previously collected for each ASN (e.g. `ASN_AS15169`).
- Exactly one enabled `forward` Mangle `action=passthrough` rule per direction, named `AS15169-DOWN` and `AS15169-UP`. The **DOWN rule must match source address list**, and **UP rule destination address list**.
- Repeat this pattern for other ASNs before adding them to the script.
- Existing FastTrack or HW offload can cause counters to miss traffic.

Example expected rules for AS15169 (these are examples, **do not paste blindly**):

```routeros
/ip firewall mangle add chain=forward action=passthrough src-address-list=ASN_AS15169 comment="AS15169-DOWN"
/ip firewall mangle add chain=forward action=passthrough dst-address-list=ASN_AS15169 comment="AS15169-UP"
```

If rules already exist, **do not add duplicates**. Verify with:

```routeros
/ip firewall mangle print detail where comment~"AS15169"
/ip firewall mangle print stats where comment~"AS15169"
/tool profile
```

## Install and run

1. Download [top10-asn-live.rsc](../scripts/top10-asn-live.rsc).
2. Edit the first line `:local asns {"15169";"32934";"13335"}` to include **only ASNs with working DOWN and UP rules**.
3. Upload via WinBox → Files.
4. Run:

```routeros
/import file-name=top10-asn-live.rsc
```

The script reads starting bytes, waits five seconds, then calculates Mbps and prints highest total (DOWN+UP) first. It skips missing/duplicate rules and counters reset during the sample.

Sample layout (illustrative numbers):

```text
=== TOP ASN (selected rule pairs, 5s average, Mbps) ===
1. AS15169 | DOWN 327 Mbps | UP 82 Mbps | TOTAL 409 Mbps
```

## Safety and accuracy

- This is ranking by traffic for **configured ASNs**, not all Internet ASNs.
- The `forward` chain counts matching traffic through the router. Without appropriate interface filtering, it can include non-subscriber traffic.
- Overlapping prefixes can lead to double counting across ASN address lists.
- High throughput and many Mangle rules may increase CPU. Test with `/tool profile`.
- Approximate Mbps uses a 5-second delay; task scheduling and router load may affect precision.
- The script does not reset counters or change routes, queues or firewall settings.
