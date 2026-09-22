# Cloudflare Provider Profile

This profile documents provider-specific abuse-reporting guidance for Cloudflare.

## Provider

- Name: Cloudflare, Inc.
- Commonly encountered ASN: AS13335
- Last verified: 2026-09-22

## Official abuse / security submission channels

Primary public abuse-reporting form:

```text
https://abuse.cloudflare.com/
```

Official reporting guidance:

```text
https://www.cloudflare.com/trust-hub/reporting-abuse/
https://developers.cloudflare.com/fundamentals/reference/report-abuse/
```

Cloudflare states that its online abuse form is the primary reporting channel.
For harmful or abusive activity that does not fit a more specific category,
use the form's **General** category when appropriate. Verify the live form
before submission.

## Cloudflare network-attribution nuance

Do not treat every AS13335 source address as an ordinary Cloudflare CDN edge
proxy.

Cloudflare publishes standard shared proxy network ranges, including:

```text
162.158.0.0/15
172.64.0.0/13
```

Cloudflare also documents that it uses other IP ranges for other products and
services.

Therefore distinguish:

```text
Cloudflare published proxy/anycast range
```

from:

```text
other Cloudflare / AS13335 service, egress, or product address space
```

For every live report, verify the exact source prefix using current BGP/RDAP
data and Cloudflare's official IP documentation.

## Recommended incident title

```text
Distributed automated HTTP scanning from Cloudflare / AS13335-associated source addresses
```

## Evidence checklist

- [ ] observation start/end timestamps with timezone
- [ ] total matching request count
- [ ] unique source-IP count
- [ ] reviewed source-IP list
- [ ] representative raw log lines
- [ ] method / URI distribution
- [ ] HTTP status distribution
- [ ] User-Agent distribution
- [ ] Referer distribution
- [ ] sensitive/configuration path probes if relevant
- [ ] behavior correlation across source IPs
- [ ] current BGP/RDAP attribution for each relevant prefix
- [ ] reproducible filtering rule
- [ ] separation of automatic detection from later manual enforcement
- [ ] SHA-256 checksums where practical

## Recommended wording

```text
We observed repeated automated HTTP scanning from multiple source addresses
currently associated with Cloudflare / AS13335 address space. The attached
evidence documents source IPs, timestamps, HTTP request characteristics,
behavioral correlation, and current network attribution.

Please investigate whether the reported source IPs can be correlated
internally, at the supplied timestamps, with specific Cloudflare services,
egress users, customer accounts, WARP/Zero Trust sessions, hosted resources,
or other common infrastructure.

We are not asserting that Cloudflare itself generated or directed this
traffic. Network attribution does not by itself identify the responsible user,
tenant, workload, or controller.
```

## Manual-enforcement boundary

A later manual Fail2Ban, firewall, or UFW ban is **not** evidence that the
address was automatically detected at the time of the original request.

Preserve separately:

```text
original request evidence
automatic detector / jail evidence
manual analyst review
manual backfill / enforcement action
```

Do not use a manual ban entry to backfill historical detection claims.

## Provider-side questions worth asking

Where relevant, ask Cloudflare to correlate:

- source IP + exact timestamp;
- the Cloudflare product or egress service responsible for the source address;
- WARP / Zero Trust egress session if applicable;
- customer/account/resource association if available;
- whether multiple reported source addresses map to common infrastructure,
  sessions, or users.

## Evidence boundary

Externally supportable:

```text
source IP -> timestamp -> observed request behavior -> BGP/RDAP attribution
```

Usually provider-internal:

```text
source IP + timestamp -> Cloudflare product/service -> egress/customer/resource
```

## Maintenance

1. Prefer Cloudflare's official abuse and documentation pages.
2. Re-check `https://abuse.cloudflare.com/` before every live submission.
3. Re-check Cloudflare's official IP-range documentation.
4. Do not treat AS13335 membership as proof of a specific Cloudflare product.
5. Keep non-Cloudflare campaign peers out of the Cloudflare source-IP field.
6. Do not paste real incident IPs, raw logs, ticket IDs, or private notes here.
