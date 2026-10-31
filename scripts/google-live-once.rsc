# RouterOS v7; read-only; import from router file root
# Keep all local variables in the same script scope.
:do {
    :local d [/ip firewall mangle find where comment="AS15169-DOWN"]
    :local u [/ip firewall mangle find where comment="AS15169-UP"]
    :if (([:len $d] != 1) || ([:len $u] != 1)) do={ :error "Expected exactly one DOWN and one UP rule" }
    :local d1 [/ip firewall mangle get $d bytes]
    :local u1 [/ip firewall mangle get $u bytes]
    :delay 5s
    :local d2 [/ip firewall mangle get $d bytes]
    :local u2 [/ip firewall mangle get $u bytes]
    :if (($d2 < $d1) || ($u2 < $u1)) do={ :error "Counter reset during measurement; retry" }
    :local downMbps ((($d2 - $d1) * 8) / 5000000)
    :local upMbps ((($u2 - $u1) * 8) / 5000000)
    :put ("Google AS15169 | DOWN: " . $downMbps . " Mbps | UP: " . $upMbps . " Mbps")
}
