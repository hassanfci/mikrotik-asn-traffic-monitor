# MikroTik ASN Traffic Monitor (RouterOS v7)

Read-only, 5-second approximate DOWN/UP Mbps measurement using existing Mangle counters. Works with **Google AS15169** and **Meta AS32934**, matching the DIT-CORE WinBox setup.

**Status:** Google counter calculation was tested interactively; the packaged import scripts and current Google+Meta combination have not yet been verified on a production router.

## Standard naming (use for both ASNs)

| Service | Address list | DOWN Mangle comment | UP Mangle comment |
| --- | --- | --- | --- |
| Google AS15169 | `ASN_AS15169` | `AS15169-DOWN` | `AS15169-UP` |
| Meta AS32934 | `ASN_AS32934` | `AS32934-DOWN` | `AS32934-UP` |

Mangle rules use `chain=forward action=passthrough`, DOWN `src-address-list`, and UP `dst-address-list`. Existing rules should be reused, **not duplicated**.

## Windows / WinBox setup

1. Ensure the relevant IPv4 prefix address lists exist and are refreshed separately.
2. Confirm both Google and Meta Mangle rule pairs match the table above.
3. Download [multi-asn-once.rsc](scripts/multi-asn-once.rsc), upload it into the router's WinBox **Files** root.
4. Run:
   ```routeros
   /import file-name=multi-asn-once.rsc
   ```
5. Read Google and Meta five-second sample Mbps output. Missing ASN rule pairs are skipped.

For Google-only sampling, upload [google-live-once.rsc](scripts/google-live-once.rsc) and run `/import file-name=google-live-once.rsc`.

## Verify

```routeros
/ip firewall address-list print count-only where list=ASN_AS15169
/ip firewall address-list print count-only where list=ASN_AS32934
/ip firewall mangle print stats where comment~"AS15169"
/ip firewall mangle print stats where comment~"AS32934"
/tool profile
```

## Important scope and safety

- Monitoring scripts only read counters; they do **not** add rules or change firewall settings.
- `scripts/example-mangle-rules.rsc` is **illustrative only**, contains ADD commands and must **not** be blindly imported into production.
- These are **not** ASN-native Torch measurements. Stale prefixes, MOAS, overlapping CDN prefixes and unmatched traffic may distort results.
- Counters include matching forward traffic, not necessarily only customer flows. FastTrack or HW offload may bypass counters.
- Large address lists and Mangle rules add CPU overhead at ISP core throughput. Do not disable acceleration merely for these measurements.
- Counter resets during a sample invalidate it; test updated scripts in a lab before production use.
- See [বাংলা setup guide](docs/SETUP-BN.md). This is not automatic top-ASN discovery.

## References

- [RouterOS scripting](https://help.mikrotik.com/docs/spaces/ROS/pages/47579229/Scripting)
- [RouterOS Mangle](https://help.mikrotik.com/docs/spaces/ROS/pages/48660587/Mangle)

## License

[MIT](LICENSE).
