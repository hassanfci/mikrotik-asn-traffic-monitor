# EXAMPLE ONLY — do not import on an existing production router.
# Existing matching rules should be reused; duplicate rules distort counters.
# Address list name = ASN_AS<number>, Mangle comment = AS<number>-DOWN/UP
/ip firewall mangle add chain=forward action=passthrough src-address-list=ASN_AS15169 comment="AS15169-DOWN"
/ip firewall mangle add chain=forward action=passthrough dst-address-list=ASN_AS15169 comment="AS15169-UP"
/ip firewall mangle add chain=forward action=passthrough src-address-list=ASN_AS32934 comment="AS32934-DOWN"
/ip firewall mangle add chain=forward action=passthrough dst-address-list=ASN_AS32934 comment="AS32934-UP"
