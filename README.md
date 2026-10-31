# MikroTik ASN Traffic Monitor (RouterOS v7)

Lightweight ASN-based traffic monitoring with RouterOS v7 Mangle counters. Measures approximate download/upload Mbps over a 5-second interval from existing firewall rules.

**Status:** Counter method confirmed on DIT-CORE for Google AS15169 (one sample: 327 Mbps down / 82 Mbps up). Packaged scripts are not production-tested; lab-test first.

## Features
- One-shot 5-second DOWN/UP Mbps monitor for AS15169.
- Multi-ASN one-shot monitor for manually configured ASNs.
- Read-only monitoring scripts: no firewall, route or address-list edits.
- Python and external server not needed for reading counters.
- Bangla setup guide in [docs/SETUP-BN.md](docs/SETUP-BN.md).

## Quick start
1. Have an IPv4 prefix list named `ASN_AS15169`. Refresh it separately; origin-AS assignments are not permanent.
2. Ensure existing Mangle rules have exactly these comments: `AS15169-DOWN`, `AS15169-UP`.
3. DOWN matches `src-address-list=ASN_AS15169`; UP matches `dst-address-list=ASN_AS15169`. Review `scripts/example-mangle-rules.rsc` before adding any rules.
4. Upload `scripts/google-live-once.rsc` into WinBox **Files** and run:

```routeros
/import file-name=google-live-once.rsc
```

For selected multiple ASNs, edit the `asns` array in `scripts/multi-asn-once.rsc`, upload and import:

```routeros
/import file-name=multi-asn-once.rsc
```

## Working terminal example
The following download-only command was tested interactively:

```routeros
:local d [/ip firewall mangle find where comment="AS15169-DOWN"]; :local old [/ip firewall mangle get $d bytes]; :delay 5s; :local new [/ip firewall mangle get $d bytes]; :put ("Google Download: " . ((($new - $old) * 8) / 5000000) . " Mbps")
```

### Example output
```text
Google AS15169 | DOWN: 327 Mbps | UP: 82 Mbps
```

## Verify rules
```routeros
/ip firewall address-list print count-only where list=ASN_AS15169
/ip firewall mangle print detail where comment~"AS15169"
/ip firewall mangle print stats where comment~"AS15169"
/tool profile
```

## Limitations / safety
- This is **not ASN-native Torch**. It approximates origin ASN via manually maintained prefix lists.
- Traffic belongs to all matching forwarded IPv4 packets unless you further scope rules to actual subscriber interfaces. **Do not assume counters represent customer-only traffic.**
- FastTrack and HW offload may bypass counters; don't disable production acceleration just for monitoring.
- Prefix overlaps, MOAS, CDNs and stale datasets can cause over/under-counting.
- Large lists and many Mangle rules cost CPU on a high-throughput ISP core. Review CPU usage and test in lab.
- Counter reset during measurement makes readings invalid.
- Multi-ASN script is **not** automatic Top-10 discovery, and does not rank ASNs.
- Monitoring scripts only read counters. The example Mangle script **adds rules** and must never be imported blindly.

## Documentation
- [RouterOS scripting](https://help.mikrotik.com/docs/spaces/ROS/pages/47579229/Scripting)
- [RouterOS Mangle](https://help.mikrotik.com/docs/spaces/ROS/pages/48660587/Mangle)

## License
[MIT](LICENSE).