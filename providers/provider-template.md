# Provider Profile Template

Copy this file when adding a new cloud, hosting, ISP, CDN, proxy, or network
provider.

## Provider

- Name: `<provider name>`
- Region / product scope: `<if relevant>`
- Last verified: `<YYYY-MM-DD>`

## Official abuse / security submission channels

Primary form or work-order URL:

```text
<official URL>
```

Optional additional channels:

```text
<security email, CERT page, abuse portal, documentation URL>
```

Notes:

- State whether authentication is required.
- Record known category IDs or routing parameters if they matter.
- Mark console/deep links as changeable and verify them before live use.

## Recommended incident title

```text
<neutral, evidence-based title>
```

## Form-specific field requirements

Document only requirements that are useful for preparing a report, such as:

- IP delimiter: comma / semicolon / newline;
- maximum IP count;
- maximum text length;
- required timestamps / timezone;
- attachment size or file-type limits;
- ticket category or product selector.

## Evidence checklist

- [ ] observation start/end timestamps with timezone
- [ ] total request count
- [ ] unique source-IP count
- [ ] source-IP list
- [ ] representative raw log lines
- [ ] method / URI distribution
- [ ] HTTP status distribution
- [ ] User-Agent distribution
- [ ] Referer distribution if relevant
- [ ] BGP/RDAP/WHOIS attribution evidence
- [ ] reproducible filtering rule
- [ ] SHA-256 checksums where practical

## Recommended wording

```text
We observed suspicious / automated / distributed automated traffic from the
listed source addresses. The attached material documents externally observable
source IPs, timestamps, request characteristics, and network attribution.
Please investigate whether these addresses can be correlated internally with
customer accounts, resources, NAT/proxy infrastructure, or common workloads.
```

## Attribution boundary

Do not write that a provider, tenant, instance, or individual is responsible
unless the evidence directly supports that conclusion.

Externally supportable in many cases:

```text
source IP -> BGP/RDAP attribution -> network operator
```

Usually provider-internal:

```text
source IP + timestamp -> allocation -> customer/account -> workload/operator
```

## Maintenance

When updating this profile:

1. Prefer official provider pages and portals.
2. Record the verification date.
3. Do not paste real incident logs, credentials, tenant IDs, or ticket IDs.
4. Keep temporary outage information out of the permanent profile unless it is
   clearly marked as historical.
