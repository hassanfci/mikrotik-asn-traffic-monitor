# EXAMPLE ONLY - do not run blindly on production.
# ASN_AS15169 must contain current IPv4 prefixes.
# Ensure rules are not already installed: avoid duplicate comments.
/ip firewall mangle add chain=forward action=passthrough src-address-list=ASN_AS15169 comment="AS15169-DOWN"
/ip firewall mangle add chain=forward action=passthrough dst-address-list=ASN_AS15169 comment="AS15169-UP"
