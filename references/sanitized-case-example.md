# Sanitized Case Example

This is a synthetic example for demonstrating the Cloud Abuse Investigation Skill.

It does not represent a real incident, customer, cloud account, host, or source-IP dataset.

## Observed dataset

- Unique source IPs: 12
- AS64500: 8
- AS64501: 4
- Other ASNs: 0

Example source addresses use documentation-only ranges:

- 192.0.2.10
- 192.0.2.11
- 198.51.100.24
- 203.0.113.18

## Observed consistency signals

The filtered requests show several automation indicators:

- multiple rotating source IP addresses;
- repeated access to a small set of endpoints;
- identical or highly similar User-Agent strings;
- similar request structure;
- source addresses concentrated in a small number of origin ASNs.

## Supported conclusion

A suitable external description is:

> Distributed automated HTTP traffic / apparent abuse originating from address space announced by the identified ASNs.

## Attribution boundary

The evidence supports:

source IP → BGP origin ASN → network operator

The evidence does not independently prove:

source IP → cloud tenant → instance → workload → operator / attacker

Provider-side allocation records would normally be required to establish those relationships.

Do not infer that the network operator itself generated or directed the traffic solely from ASN attribution.
