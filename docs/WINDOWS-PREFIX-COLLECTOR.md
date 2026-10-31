# Windows ASN Prefix Collector — বাংলা Setup Guide

## Step 1: Python Script ডাউনলোড করুন

GitHub-এর [Interactive Windows Script](../tools/asn_collector.py) খুলে **Download raw file** নির্বাচন করুন। ফাইলের নাম `asn_collector.py` রেখে Desktop-এ Save করুন। Windows-এ Python 3.9+ ইনস্টল থাকতে হবে; CMD-তে `py --version` দিয়ে পরীক্ষা করতে পারেন।

## Step 2: Script চালান

Windows CMD খুলে শুধু নিচের Command চালান:

```cmd
py "%USERPROFILE%\Desktop\asn_collector.py"
```

এরপর আপনার পছন্দের ASN লিখুন। উদাহরণ:

```text
Enter ASN (example AS3333): AS3333
```

Script সফলভাবে চললে Desktop-এ **`AS3333_mikrotik.rsc`** নামে ফাইল তৈরি হবে। এটি RIPEstat API থেকে সম্প্রতি পর্যবেক্ষিত IPv4 prefixes ব্যবহার করে। API/network error হলে ফাইল তৈরি হবে না।

> Desktop যদি OneDrive-এ redirect করা থাকে, তাহলে Desktop path ভিন্ন হতে পারে। সে ক্ষেত্রে CMD command ও script-এর output path পরিবর্তন করতে হবে।

## Step 3: MikroTik-এ Import

Generated `.rsc` ফাইলটি আগে Text Editor-এ খুলে Prefix এবং Address List Name যাচাই করুন। এই interactive script `ASN_AS3333` ধরনের Address List Name ব্যবহার করে, যা DIT-CORE-এর `ASN_AS15169` naming convention-এর সঙ্গে মেলে।

WinBox → Files-এ Upload করে Terminal-এ:

```routeros
/import file-name=AS3333_mikrotik.rsc
```

তারপর:

```routeros
/ip firewall address-list print count-only where list=ASN_AS3333
```

**সতর্কতা:** Import শুধু entry যোগ করে। পুরোনো Prefix নিজে থেকে remove হয় না এবং বারবার Import করলে duplicate entry হতে পারে। Production MikroTik-এ আগে Backup এবং CPU ব্যবহার যাচাই করুন।

## Alternative: Multiple ASN Command Line Collector

একাধিক ASN একসঙ্গে নিতে [tools/asn_to_mikrotik.py](../tools/asn_to_mikrotik.py) ব্যবহার করুন:

```cmd
py tools\asn_to_mikrotik.py 15169 32934 13335
```

এই alternative script-এর generated list নাম `AS15169`, কিন্তু interactive script-এর নাম `ASN_AS15169`। তাই অন্য script-এর Output আপনার existing Mangle Rule-এ ব্যবহার করার আগে নাম মিলিয়ে নিন।

Data হলো recently observed BGP announcements, নিশ্চিত real-time origin-AS table নয়।
