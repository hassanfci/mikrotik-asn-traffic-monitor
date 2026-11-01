# RouterOS v7 — read-only one-shot Top 10 ASN ranking (5-second sample).
# Edit only the asns array. Requires AS<asn>-DOWN and AS<asn>-UP Mangle comments.
# Monitoring only; does not create/modify firewall rules.
:do {
    :local asns {"15169";"32934";"13335"}
    :local names [:toarray ""]
    :local downRules [:toarray ""]
    :local upRules [:toarray ""]
    :local downStart [:toarray ""]
    :local upStart [:toarray ""]
    :foreach asn in=$asns do={
        :local d [/ip firewall mangle find where comment=("AS" . $asn . "-DOWN")]
        :local u [/ip firewall mangle find where comment=("AS" . $asn . "-UP")]
        :if (([:len $d] = 1) && ([:len $u] = 1)) do={
            :set names ($names, $asn)
            :set downRules ($downRules, $d)
            :set upRules ($upRules, $u)
            :set downStart ($downStart, [/ip firewall mangle get $d bytes])
            :set upStart ($upStart, [/ip firewall mangle get $u bytes])
        } else={
            :put ("SKIP AS" . $asn . " - missing or duplicate DOWN/UP rule")
        }
    }
    :local n [:len $names]
    :if ($n = 0) do={ :error "No valid ASN rule pairs found" }
    :delay 5s
    :local downs [:toarray ""]
    :local ups [:toarray ""]
    :local totals [:toarray ""]
    :for i from=0 to=($n - 1) do={
        :local d2 [/ip firewall mangle get ($downRules->$i) bytes]
        :local u2 [/ip firewall mangle get ($upRules->$i) bytes]
        :local d1 ($downStart->$i)
        :local u1 ($upStart->$i)
        :local dl -1
        :local ul -1
        :local total -1
        :if (($d2 >= $d1) && ($u2 >= $u1)) do={
            :set dl ((($d2 - $d1) * 8) / 5000000)
            :set ul ((($u2 - $u1) * 8) / 5000000)
            :set total ($dl + $ul)
        }
        :set downs ($downs, $dl)
        :set ups ($ups, $ul)
        :set totals ($totals, $total)
    }
    :put "=== TOP ASN (selected rule pairs, 5s average, Mbps) ==="
    :local printed "|"
    :local limit 10
    :if ($n < $limit) do={ :set limit $n }
    :for rank from=1 to=$limit do={
        :local bestIndex -1
        :local bestTotal -1
        :for i from=0 to=($n - 1) do={
            :local a ($names->$i)
            :local t ($totals->$i)
            :if (([:typeof [:find $printed ("|" . $a . "|")]] = "nil") && ($t >= 0)) do={
                :if ($t > $bestTotal) do={
                    :set bestTotal $t
                    :set bestIndex $i
                }
            }
        }
        :if ($bestIndex >= 0) do={
            :local a ($names->$bestIndex)
            :put ($rank . ". AS" . $a . " | DOWN " . ($downs->$bestIndex) . " Mbps | UP " . ($ups->$bestIndex) . " Mbps | TOTAL " . ($totals->$bestIndex) . " Mbps")
            :set printed ($printed . $a . "|")
        }
    }
    :put "Note: ranking covers only configured ASNs; matching forwarded IPv4 traffic, not necessarily customer-only."
} on-error={ :put "ASN monitor failed: verify rule comments, counters and RouterOS v7 syntax." }
