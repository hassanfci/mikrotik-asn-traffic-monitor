# MikroTik ASN Monitor — বাংলা সেটআপ

1. Prefix List যাচাই: `/ip firewall address-list print count-only where list=ASN_AS15169`
2. DOWN rule: `src-address-list=ASN_AS15169`, comment `AS15169-DOWN`
3. UP rule: `dst-address-list=ASN_AS15169`, comment `AS15169-UP`
4. WinBox Files-এ `google-live-once.rsc` upload করে `/import file-name=google-live-once.rsc` চালান।
5. Output-এ শেষ ৫ সেকেন্ডের আনুমানিক DOWN এবং UP Mbps পাবেন।
6. একাধিক ASN-এর জন্য Mangle rule pair এবং `multi-asn-once.rsc`-এর `asns` list মিলিয়ে নিন।

**সতর্কতা:** Production core-এ বড় Address List এবং অনেক Mangle rule CPU load বাড়াতে পারে। `/tool profile` দেখুন। FastTrack/HW offload অকারণে বন্ধ করবেন না। এটি automatic Top 10 ASN discovery নয়।
