# MikroTik ASN Monitor — বাংলা সেটআপ (Google + Meta)

## একই Naming Format

| Service | ASN | Address List | DOWN comment | UP comment |
| --- | --- | --- | --- | --- |
| Google | 15169 | `ASN_AS15169` | `AS15169-DOWN` | `AS15169-UP` |
| Meta | 32934 | `ASN_AS32934` | `AS32934-DOWN` | `AS32934-UP` |

DOWN rule-এ `src-address-list=ASN_AS<number>`; UP rule-এ `dst-address-list=ASN_AS<number>` ব্যবহার করুন। দুটি rule-এর chain=`forward` ও action=`passthrough` হবে।

## Import

1. WinBox **IP → Firewall → Mangle**-এ চারটি comment ও Address List মিলিয়ে দেখুন।
2. WinBox **Files**-এ GitHub-এর `scripts/multi-asn-once.rsc` upload করুন।
3. Terminal-এ চালান:
   ```routeros
   /import file-name=multi-asn-once.rsc
   ```
4. Google ও Meta-এর পাঁচ সেকেন্ডের আনুমানিক DOWN/UP Mbps দেখাবে। Rule missing থাকলে সেই ASN skip হবে।

শুধু Google-এর জন্য `google-live-once.rsc` import করা যায়।

## Verification

```routeros
/ip firewall address-list print count-only where list=ASN_AS15169
/ip firewall address-list print count-only where list=ASN_AS32934
/ip firewall mangle print stats where comment~"AS15169"
/ip firewall mangle print stats where comment~"AS32934"
/tool profile
```

**সতর্কতা:** এই monitoring script read-only। `scripts/example-mangle-rules.rsc`-এ ADD commands আছে, তাই বিদ্যমান production rules-এর ওপর import করবেন না। Prefix list নিয়মিত refresh করতে হবে। CPU, FastTrack/HW-offload ও counter accuracy যাচাই করুন। RouterOS device-এ import করে নতুন version এখনও production-tested নয়।
