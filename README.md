# Cloud Abuse Investigation Skill

A reusable, evidence-first workflow for investigating suspicious HTTP traffic originating from cloud, hosting, proxy, or other network infrastructure.

The project turns filtered web-server logs into reproducible statistics, conservative network attribution, evidence bundles, and provider-ready abuse reports. It is designed for security analysts, site operators, SRE/DevOps teams, hosting providers, and incident responders who need to document suspicious traffic without overstating what external evidence can prove.

> **Core rule:** ASN/BGP attribution identifies the network announcing an IP address. It does **not** by itself identify the tenant, instance, account, workload, proxy, operator, or attacker behind that address.

## What this repository contains

```text
cloud-abuse-investigation-skill/
├── SKILL.md
├── README.md
├── LICENSE
├── .gitignore
├── scripts/
│   └── build-evidence-bundle.sh
├── templates/
│   ├── provider-report-en.txt
│   └── provider-report-zh.txt
├── examples/
│   ├── sample-access.log
│   └── sample-asn.txt
├── providers/
│   ├── tencent-cloud.md
│   └── provider-template.md
└── references/
    └── sanitized-case-example.md
```

## Workflow

```text
Raw / filtered web logs
        ↓
Evidence preservation
        ↓
IP / UA / Path / Referer / Status statistics
        ↓
Automation-pattern analysis
        ↓
ASN / BGP attribution
        ↓
Fact vs. analysis vs. unknown separation
        ↓
Evidence bundle + checksums
        ↓
Cloud / hosting provider abuse report
```

## Key capabilities

- Extract and summarize suspicious Nginx/Apache access-log traffic.
- Count unique source IPs separately from total request volume.
- Analyze IP rotation, User-Agent reuse, endpoint repetition, Referer anomalies, status distributions, and other automation indicators.
- Attribute source addresses to origin ASNs using reproducible BGP/WHOIS evidence.
- Keep network ownership separate from tenant or attacker attribution.
- Generate an evidence bundle containing logs, unique IPs, form-ready IP fields, summaries, and SHA-256 checksums.
- Produce neutral Chinese and English provider-report templates.
- Support provider-specific profiles without hard-coding one incident or vendor into the core workflow.

## Quick start

The included helper expects a **filtered incident log** and a corresponding ASN/BGP result file. It copies those inputs into a new evidence directory and does not modify the source files.

```bash
chmod +x scripts/build-evidence-bundle.sh

./scripts/build-evidence-bundle.sh \
  examples/sample-access.log \
  examples/sample-asn.txt \
  /tmp/cloud-abuse-demo
```

Inspect the generated bundle:

```bash
find /tmp/cloud-abuse-demo -maxdepth 1 -type f -print
cat /tmp/cloud-abuse-demo/summary.txt
cat /tmp/cloud-abuse-demo/checksums.txt
```

For real incidents, first copy or filter the relevant records from the original access log into a separate working file. Do not rewrite production evidence in place.

## Classification model

The Skill uses a conservative five-level classification model:

| Level | Label | Typical evidence |
| --- | --- | --- |
| 0 | Insufficient evidence | Isolated anomalies with no stable pattern |
| 1 | Suspicious traffic | Some unusual behavior, weak automation evidence |
| 2 | Automated HTTP traffic | Multiple consistent automation signals |
| 3 | Distributed automated traffic / apparent abuse | Rotating IPs + consistent behavior + reproducible network attribution |
| 4 | Confirmed malicious activity | Direct exploit, credential attack, destructive action, or similarly strong evidence |

High request volume alone is not enough to call an event a DDoS or to identify an attacker.

## Attribution model

External evidence can often support:

```text
source IP → BGP origin ASN → network operator
```

External evidence usually cannot prove on its own:

```text
source IP → cloud tenant → instance/NAT/proxy → actual operator
```

The latter relationship generally requires provider-side allocation and account records for the exact source IP **and timestamp**.

## Evidence bundle

The helper produces a structure similar to:

```text
cloud-abuse-YYYYMMDD/
├── README.txt
├── source-ips.txt
├── source-ips-form.txt
├── nginx-access.log
├── bgp-asn.txt
├── summary.txt
└── checksums.txt
```

`source-ips-form.txt` uses semicolon-delimited IPs for provider forms that require values such as:

```text
192.0.2.10;192.0.2.11;198.51.100.24
```


## Provider reporting profiles

Provider-specific reporting channels are stored separately from the core investigation logic. This keeps the Skill reusable while allowing each cloud or hosting provider to document its own work-order URL, abuse form, field constraints, and terminology.

Currently included:

- **Tencent Cloud** — Security Center work-order profile: [`providers/tencent-cloud.md`](providers/tencent-cloud.md)
- **Provider template** — copy this when adding AWS, Alibaba Cloud, Azure, Google Cloud, Cloudflare, DigitalOcean, an ISP, or another hosting provider: [`providers/provider-template.md`](providers/provider-template.md)

The Tencent profile includes the Security Center work-order submission route supplied for this project. Provider console URLs and category IDs can change, so maintainers should verify them before live submission.

Contributions adding other providers are welcome when they use official reporting channels, avoid embedding real incident evidence, and retain the attribution boundary described below.

## Sanitized examples

All example IP addresses in this repository use documentation-only address ranges such as `192.0.2.0/24`, `198.51.100.0/24`, and `203.0.113.0/24`. Example ASNs are non-production placeholders for demonstrating the workflow.

The repository intentionally does **not** include the source IP list, raw logs, tenant information, hostnames, or other sensitive evidence from any real provider-abuse case.

## Security and evidence-handling notice

This project is intended to help preserve and communicate evidence, not to alter it.

- Treat original access logs and packet captures as read-only evidence.
- Work on copied or filtered data in a separate directory.
- Record filtering rules so that results can be reproduced.
- Preserve timestamps and timezone offsets; dynamic cloud IP allocation makes timing important.
- Review logs before sharing them externally for cookies, authorization headers, query-string secrets, personal data, internal hostnames, customer identifiers, and other sensitive material.
- Do not publish real incident evidence in a public repository unless it has been intentionally reviewed and sanitized.
- A local firewall or Fail2Ban decision is not independent proof of malicious intent.

### Never commit these to the public repository

- Real incident source-IP inventories when disclosure is unnecessary.
- Authentication cookies, bearer tokens, API keys, passwords, or session identifiers.
- Private keys or TLS key material.
- Internal admin URLs or infrastructure identifiers that create unnecessary exposure.
- Unredacted production access logs or packet captures.
- Cloud account IDs, instance IDs, ticket IDs, customer identifiers, or private investigation notes.

The `.gitignore` in this repository blocks common evidence and secret file patterns, but it is not a substitute for manual review before every commit.

## Responsible reporting language

Prefer wording such as:

> We observed distributed automated HTTP traffic originating from address space announced by the listed ASNs. The attached evidence establishes source IPs, timestamps, request characteristics, and network attribution. Please investigate whether these addresses correlate internally with customer accounts, instances, NAT gateways, proxy infrastructure, workloads, or other common resources.

Avoid statements such as “the cloud provider attacked us” unless independent evidence actually supports that claim.

## Supported environments

The methodology is provider-neutral and can be used for traffic associated with, for example:

- Tencent Cloud
- Alibaba Cloud
- AWS
- Microsoft Azure
- Google Cloud
- Cloudflare
- DigitalOcean
- VPS/hosting providers
- ISP, proxy, or other ASN-addressed infrastructure

Provider-specific reporting channels and form requirements should live in separate profiles or references rather than being embedded into the core classification logic.

## Contributing

Contributions are welcome, especially for:

- safer log parsers;
- provider-specific reporting profiles;
- RDAP/BGP attribution adapters;
- evidence-integrity checks;
- privacy-preserving sanitization helpers;
- tests built only from synthetic or intentionally sanitized data.

Please do not open issues or pull requests containing live credentials, unredacted production logs, private customer data, or confidential abuse-report evidence.

## License

Licensed under the **Apache License 2.0**. This license is suitable for broad commercial and enterprise reuse and includes an explicit patent grant from contributors, subject to the terms of the license.

See [LICENSE](LICENSE).
