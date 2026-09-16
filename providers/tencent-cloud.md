# Tencent Cloud Provider Profile

This profile documents provider-specific reporting details for Tencent Cloud.
It is intentionally separate from the core investigation workflow so that
provider URLs, field formats, and category IDs can evolve independently.

## Scope

Use this profile when suspicious traffic is externally attributed to address
space announced by Tencent-related ASNs or when Tencent Cloud is otherwise the
appropriate provider for an abuse/security report.

Do **not** treat ASN attribution alone as proof that Tencent Cloud itself,
a specific Tencent Cloud tenant, or a specific cloud instance generated or
directed the traffic.

## Security work-order submission URL

Tencent Cloud Security Center work-order entry:

https://console.cloud.tencent.com/workorder/category?source=14&level1_id=141&level2_id=2942&data_title=%E4%BA%91%E5%AE%89%E5%85%A8%E4%B8%AD%E5%BF%83

This is a console route and may require authentication. Category IDs and route
parameters may change over time. Verify the destination before submitting a live
incident.

## Recommended incident title

English:

```text
Distributed automated HTTP traffic from Tencent-announced address space
```

Chinese:

```text
来自腾讯相关 ASN 地址空间的分布式自动化异常 HTTP 请求
```

Avoid titles that state or imply that Tencent Cloud itself attacked the server
unless independent evidence establishes that conclusion.

## Evidence to prepare

At minimum include:

- observation start and end time, including timezone;
- total matching request count;
- unique source IP count;
- complete source-IP list, if appropriate to disclose;
- representative raw log lines;
- request Path / method distribution;
- HTTP status distribution;
- User-Agent distribution;
- Referer distribution where relevant;
- BGP/ASN attribution results and query source;
- a short explanation of the automation indicators;
- SHA-256 checksums for submitted evidence files when practical.

## IP field format

If the Tencent Cloud work-order form requests multiple IP addresses separated by
semicolons, generate the value from a reviewed source list:

```bash
awk '{print $1}' suspicious.log | sort -u | paste -sd';' -
```

Example using documentation-only addresses:

```text
192.0.2.10;192.0.2.11;198.51.100.24
```

Before pasting a large list, verify whether the current form imposes character
or item limits. If it does, split the list into deterministic groups and keep a
copy of the grouping used for each submission.

## Recommended wording

```text
We observed distributed automated HTTP traffic from multiple source IP
addresses. The attached evidence establishes the source IPs, timestamps,
request characteristics, and external BGP/ASN attribution. We request that
Tencent Cloud Security investigate whether these addresses can be correlated
internally with customer accounts, cloud instances, NAT gateways, proxy
infrastructure, workloads, or other common resources.

We are not asserting that Tencent Cloud itself generated or directed the
traffic. External ASN attribution identifies the network announcing the source
addresses but does not by itself identify the responsible tenant, instance,
operator, or user.
```

## Provider-side questions worth asking

Where appropriate, request that the provider examine:

- public IP / EIP allocation at the exact observed timestamps;
- NAT gateway or shared-egress relationships;
- CVM or other compute-resource association;
- tenant/account correlation across multiple reported addresses;
- proxy, container, serverless, or automation workloads;
- whether the same resources have been associated with other abuse reports.

## Evidence boundary

Externally supportable:

```text
source IP -> BGP origin ASN -> network operator
```

Usually provider-internal:

```text
source IP + timestamp -> allocated resource -> tenant/account -> workload/operator
```

Keep these two layers separate in reports and public documentation.
