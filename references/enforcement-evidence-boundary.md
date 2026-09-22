# Detection and Enforcement Evidence Boundary

## Core rule

A local ban is not independent evidence that the underlying traffic was
malicious.

Keep these stages separate:

```text
original request
-> detector/filter match
-> jail threshold
-> automatic enforcement
```

and:

```text
analyst review
-> manual backfill ban
```

A manual backfill ban must never be rewritten as historical automatic
detection.

## Fail2Ban-specific validation

An internal Fail2Ban ban record does not necessarily prove firewall
enforcement was materialized.

When control-path validation matters, verify:

```text
filter match
-> jail threshold
-> registered action
-> nft/iptables rule
-> packet-path hook
-> unban cleanup
```

Use documentation-only synthetic IPs for enforcement tests.

## Log-semantic drift

Security hardening can change log shapes even when probing continues.

After authentication, proxy, CDN, or web-stack changes:

1. replay historical detector tests;
2. inspect new unmatched log forms;
3. confirm regex coverage;
4. validate thresholds separately from regex coverage;
5. rerun synthetic enforcement tests where appropriate.
