# RouterOS v7 read-only; 5-second DOWN/UP sample for Google and Meta.
# Standard Mangle comments: AS15169-DOWN/UP and AS32934-DOWN/UP
# Standard address lists: ASN_AS15169 and ASN_AS32934
# All variables share the same :do scope for /import.
:do {
    :local asns {"15169";"32934"}
    :local startDown [:toarray ""]
    :local startUp [:toarray ""]
    :local valid [:toarray ""]
    :local downRules [:toarray ""]
    :local upRules [:toarray ""]
    :foreach asn in=$asns do={
        :local d [/ip firewall mangle find where comment=("AS" . $asn . "-DOWN")]
        :local u [/ip firewall mangle find where comment=("AS" . $asn . "-UP")]
        :if (([:len $d] = 1) && ([:len $u] = 1)) do={
            :set startDown ($startDown, [/ip firewall mangle get $d bytes])
            :set startUp ($startUp, [/ip firewall mangle get $u bytes])
            :set downRules ($downRules, $d)
            :set upRules ($upRules, $u)
            :set valid ($valid, $asn)
        } else={ :put ("SKIP AS" . $asn . " - missing or duplicate mangle rules") }
    }
    :if ([:len $valid] = 0) do={ :error "No valid ASN rule pairs" }
    :delay 5s
    :local idx 0
    :foreach asn in=$valid do={
        :local d ($downRules->$idx)
        :local u ($upRules->$idx)
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
}
