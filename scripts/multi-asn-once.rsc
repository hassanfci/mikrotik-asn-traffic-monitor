# RouterOS v7 read-only; one 5-second sample for selected configured ASNs.
# Edit list to match AS<number>-DOWN and AS<number>-UP Mangle comments.
:local asns {"15169";"32934";"13335"}
:local startDown [:toarray ""]
:local startUp [:toarray ""]
:local valid [:toarray ""]
:foreach asn in=$asns do={
    :local d [/ip firewall mangle find where comment=("AS" . $asn . "-DOWN")]
    :local u [/ip firewall mangle find where comment=("AS" . $asn . "-UP")]
    :if (([:len $d] = 1) && ([:len $u] = 1)) do={
        :set startDown ($startDown, [/ip firewall mangle get $d bytes])
        :set startUp ($startUp, [/ip firewall mangle get $u bytes])
        :set valid ($valid, $asn)
    } else={ :put ("SKIP AS" . $asn . " - missing or duplicate mangle rules") }
}
:if ([:len $valid] = 0) do={ :error "No valid ASN rule pairs" }
:delay 5s
:local idx 0
:foreach asn in=$valid do={
    :local d [/ip firewall mangle find where comment=("AS" . $asn . "-DOWN")]
    :local u [/ip firewall mangle find where comment=("AS" . $asn . "-UP")]
    :local d2 [/ip firewall mangle get $d bytes]
    :local u2 [/ip firewall mangle get $u bytes]
    :local d1 ($startDown->$idx)
    :local u1 ($startUp->$idx)
    :if (($d2 >= $d1) && ($u2 >= $u1)) do={
        :local downMbps ((($d2 - $d1) * 8) / 5000000)
        :local upMbps ((($u2 - $u1) * 8) / 5000000)
        :put ("AS" . $asn . " | DOWN " . $downMbps . " Mbps | UP " . $upMbps . " Mbps | TOTAL " . ($downMbps + $upMbps) . " Mbps")
    } else={ :put ("AS" . $asn . " | counter reset; retry") }
    :set idx ($idx + 1)
}
