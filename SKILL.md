---
name: cloud-abuse-investigation
version: 1.0.0
description: >-
  从 Web/Nginx 访问日志中排查可疑自动化流量，完成源 IP 聚类、行为识别、ASN/BGP 归属、证据边界定性，
  并生成适合云厂商 Abuse/Security 团队提交的证据包、举报正文和 IP 表单字段。适用于腾讯云、阿里云、AWS、
  Azure、Google Cloud、Cloudflare、IDC/Hosting ASN 等来源异常流量。重点避免把 ASN 归属直接等同于攻击主体归属。
triggers:
  - 排查一批来源 IP 是否属于同一云厂商或 ASN
  - 分析 Nginx/Apache access log 中疑似扫描、爬虫、代理池、自动化请求
  - 判断流量能否定性为 suspicious automated traffic / apparent abuse
  - 生成云厂商网络攻击/滥用举报材料
  - 整理 IP 列表、日志证据、ASN 归属、时间范围、Path/UA/Referer/Status 分布
  - 将多个 IP 转成云厂商表单要求的分号分隔格式
---

# Cloud Abuse Investigation Skill

## 目标

把“看到异常请求”转化成一套可复核、可提交、不过度定性的事件材料：

1. 从原始访问日志中提取目标流量。
2. 对源 IP、时间、Path、User-Agent、Referer、状态码等做统计。
3. 对 IP 做 ASN/BGP 归属验证，并区分“网络归属”与“行为主体”。
4. 判断是否存在自动化、扫描、代理池、分布式请求等一致性特征。
5. 给出分层定性，而不是越过证据直接断言攻击主体。
6. 生成云厂商可直接处理的 evidence bundle、README、IP 字段和举报正文。

## 核心原则

### 1. 原始证据只读

- 不修改 `/var/log/nginx/access.log`、Apache 原始日志或用户上传的原始证据。
- 优先复制/筛选到 `/tmp/...` 或独立 evidence 目录后再分析。
- 所有统计都应能追溯到原始日志行。

### 2. 事实、分析、推断分层

输出时严格区分：

**可直接证明的事实**
- 某时间段出现 N 个唯一源 IP。
- 某些请求使用相同 User-Agent。
- 某些 IP 的 BGP origin ASN 为 ASxxxx。
- 某 Path/Referer/Status 重复出现。

**合理分析**
- 大量轮换 IP 使用高度一致的请求特征，符合自动化访问特征。
- 多 IP 集中于同一/少数 ASN，可能来自同一云厂商网络或代理基础设施。

**不能仅凭外部日志证明的结论**
- 这些 IP 一定属于同一租户、同一 CVM、同一账号或同一攻击者。
- 云厂商自身实施、指挥或授权了该流量。
- 某客户账号就是行为主体。

推荐表达：

> 发现来自 ASxxxx / ASyyyy 所公告地址空间的大规模分布式自动化异常 HTTP 请求。现有外部证据可证明源 IP、时间戳、请求特征及 BGP/ASN 归属，但无法从外部直接确定对应租户、实例或控制主体，建议由云厂商根据内部账号与资源日志进一步关联调查。

### 3. ASN 归属 ≠ 云实例归属 ≠ 攻击主体归属

始终保留这一边界：

`公网源 IP -> BGP Origin ASN -> 网络运营主体` 可以由外部数据验证。

`公网源 IP -> 云实例/公网 NAT/EIP -> 租户账号 -> 实际操作者` 通常只有云厂商内部才能验证。

## 输入

至少需要以下之一：

- Nginx/Apache access log；或
- 已筛选出的可疑请求日志。

推荐同时提供：

- 已提取的 source IP 列表；
- Team Cymru / WHOIS / RIR / BGP 查询结果；
- 目标 User-Agent、Path、Referer、时间范围等已知 IOC；
- 云厂商举报页面对字段格式的要求。

## 标准工作流

### Phase A — 证据固定与日志筛选

1. 明确原始日志文件路径。
2. 不在原始日志上执行 `sed -i`、重写、truncate 等修改操作。
3. 根据 IOC 筛选目标流量到独立文件。
4. 记录筛选规则，防止后续无法复现。

示例：按精确 User-Agent 筛选：

```bash
UA='Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1'
grep -F "$UA" /var/log/nginx/access.log > /tmp/suspicious-automation.log
```

如果筛选条件由多个 Path/UA/Referer 组成，保存为脚本或 README，避免只保留最终结果。

### Phase B — 基础统计

必须输出：

- 总匹配请求数；
- 唯一源 IP 数；
- 首次出现与最后出现时间；
- 请求方法 + Path 分布；
- HTTP 状态码分布；
- User-Agent 分布；
- Referer 分布；
- 每 IP 请求数；
- 如有必要：每分钟/每小时请求量。

注意：

- Nginx combined log 中请求字段通常在双引号字段 `$2`；User-Agent 常为 `$6`；Referer 常为 `$4`。
- 不要只统计完整 request line 而误称为 Path；需要 Path 时应从 `METHOD URI HTTP/x.x` 中进一步拆出 URI。
- 时间排序尽量解析时间字段，不要仅依赖普通字符串排序。

### Phase C — 自动化特征识别

对以下信号做交叉判断，不以单一信号定性：

1. **IP 轮换**：短时间大量唯一 IP。
2. **UA 一致性**：大量不同 IP 使用完全相同、罕见、过时或异常 UA。
3. **Path 一致性**：反复访问相同少量 endpoint。
4. **Referer 一致性/异常性**：空 Referer、固定 Referer、直接 IP URL、异常跨域 Referer。
5. **节奏一致性**：时间间隔、burst、周期或并发模式高度类似。
6. **请求结构一致性**：Method、query 参数、header、响应状态高度一致。
7. **ASN 集中度**：大量 IP 集中在同一或少量 ASN。
8. **业务不合理性**：真实用户几乎不会产生的路径组合、频率或跨 IP 行为。

推荐定性分级：

- **Level 0 — Insufficient evidence**：只有少量异常，无一致模式。
- **Level 1 — Suspicious traffic**：存在异常但自动化证据较弱。
- **Level 2 — Automated HTTP traffic**：多项特征一致，可合理判断为自动化请求。
- **Level 3 — Distributed automated traffic / apparent abuse**：大量轮换 IP + 一致行为 + 明确网络归属，适合提交 abuse 调查。
- **Level 4 — Confirmed malicious activity**：只有存在明确恶意 payload、漏洞利用、认证攻击、资源消耗攻击等直接证据时才使用；不要仅凭“请求很多”升级到此级别。

默认优先使用 Level 2–3 的描述，不轻易使用“攻击者”“攻击团伙”“DDoS”等强结论。

### Phase D — ASN / BGP 归属

优先使用权威或可复核来源：

- Team Cymru IP-to-ASN；
- RIR WHOIS/RDAP；
- 云厂商公开 IP range（若有）；
- BGP 查询服务做交叉验证。

Team Cymru 批量 WHOIS 示例：

```bash
{
  echo begin
  echo verbose
  cat source-ips.txt
  echo end
} | nc whois.cymru.com 43 > bgp-asn.txt
```

分析结果时至少统计：

- 每个 origin ASN 的唯一 IP 数；
- ASN 名称；
- 非目标 ASN 数；
- 未识别/查询失败数。

不能把 `ASN Name` 文本中含某品牌名作为唯一证据。必要时结合 RIR/BGP 信息交叉验证。

### Phase E — 定性结论模板

根据证据自动填充，不越界：

> 在 `<time_start>` 至 `<time_end>` 的服务器访问日志中，共识别 `<request_count>` 条满足筛选条件的 HTTP 请求，涉及 `<unique_ip_count>` 个唯一源 IP。多个源 IP 在 User-Agent、目标 endpoint、Referer/请求结构等方面表现出高度一致性，符合分布式自动化 HTTP 访问特征。BGP/ASN 查询显示，其中 `<asn_distribution>`。这些证据支持将事件描述为“来自相关 ASN 所公告地址空间的分布式自动化异常流量 / apparent abuse”。现有外部证据不能单独证明这些地址属于同一云租户、实例、账号或控制主体，应由网络/云服务商基于内部资源映射和账号日志进一步确认。

### Phase F — Evidence Bundle

推荐目录：

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

说明：

- `README.txt`：事件摘要、时间范围、统计、分析、请求事项。
- `source-ips.txt`：一行一个唯一 IP。
- `source-ips-form.txt`：表单格式，例如分号分隔。
- `nginx-access.log`：仅相关日志，不必提交全量 access.log。
- `bgp-asn.txt`：原始 ASN 查询结果。
- `summary.txt`：核心数字和 IOC。
- `checksums.txt`：可选但推荐，用 SHA-256 固定证据文件。

生成 checksum：

```bash
cd cloud-abuse-YYYYMMDD
sha256sum README.txt source-ips.txt nginx-access.log bgp-asn.txt summary.txt > checksums.txt
```

### Phase G — 云厂商举报正文

正文必须包含：

1. 事件类型：suspicious/distributed automated HTTP traffic。
2. 时间范围及日志时区。
3. 唯一 IP 数、总请求数。
4. 主要行为一致性特征。
5. ASN/BGP 归属统计。
6. 附件清单。
7. 明确说明“不将网络归属等同于行为主体”。
8. 请求云厂商关联内部 customer account / instance / NAT / workload / proxy 等资源调查。

英文标准段落：

```text
We are not asserting that the cloud provider itself generated or directed this traffic. The submitted evidence establishes source IP addresses, timestamps, HTTP request characteristics, and BGP/ASN attribution. We would appreciate your security team investigating whether these addresses can be correlated internally with customer accounts, instances, NAT gateways, proxy infrastructure, workloads, or other common resources.
```

中文标准段落：

```text
本举报并非认定云厂商自身生成、指挥或授权了相关流量。现有材料仅用于证明源 IP、时间戳、HTTP 请求特征及 BGP/ASN 网络归属。请贵方结合内部账号、实例、EIP/NAT、代理基础设施、工作负载及安全日志进一步核查这些地址是否存在共同资源或控制主体。
```

## 腾讯云 Provider Profile

当目标 ASN/网络指向 Tencent 时：

### 推荐事件名称

- 中文：`来自腾讯相关 ASN 的分布式自动化异常 HTTP 流量`
- 英文：`Distributed Automated HTTP Traffic from Tencent-related ASNs`

如果证据明确指向具体 ASN，可写：

`Distributed Automated HTTP Traffic from Provider-related ASNs`

### 举报口径

推荐：

> 发现来自腾讯相关 ASN 所公告地址空间的大规模分布式自动化异常访问，希望腾讯云根据源 IP、时间戳及内部账号/实例记录进一步调查。

避免：

- “腾讯云攻击了我的服务器”
- “这些云厂商服务器在攻击我”
- “已经证明是同一个腾讯云用户”

除非存在额外证据，否则这些表达超过外部日志能够证明的范围。

### 表单 IP 字段

如果要求“多个 IP 用 `;` 分隔”：

```bash
awk '{print $1}' suspicious.log | sort -u | paste -sd';' -
```

保存：

```bash
awk '{print $1}' suspicious.log | sort -u | paste -sd';' - > source-ips-form.txt
```

如果字段有长度或数量限制，按固定数量分组，不删除 IP：

```bash
awk '{print $1}' suspicious.log | sort -u | awk 'NR%50==1{if(NR>1)print ""}{printf "%s%s", (NR%50==1?"":";"), $0} END{print ""}'
```

## 质量检查清单

提交前逐项验证：

- [ ] 原始 access log 未被修改。
- [ ] 筛选规则已记录且可复现。
- [ ] 唯一 IP 数由当前日志动态计算，不是手填旧数字。
- [ ] 总请求数与 evidence log 行数一致。
- [ ] 时间范围来自日志自身，并保留时区。
- [ ] Path、Status、UA、Referer 字段解析正确。
- [ ] ASN 统计基于唯一 IP，而不是请求条数。
- [ ] 未把 ASN 归属写成云租户/攻击者归属。
- [ ] 举报正文中的数字与附件一致。
- [ ] IP 表单字段去重且格式符合平台要求。
- [ ] 如提交原始日志，已检查是否包含不必要的 Cookie、Authorization、个人数据或其他敏感字段。
- [ ] 压缩包内文件名清晰。
- [ ] 可选：已生成 SHA-256 checksum。

## 常见错误与修正

### 错误 1：把 ASN 归属直接写成“腾讯云 IP 攻击”

修正为：

> 来自腾讯相关 ASN 所公告地址空间的异常自动化流量。

### 错误 2：只给 IP，不给时间戳

云厂商内部公网 IP 可能动态分配。必须尽量给出精确时间和时区。

### 错误 3：只给截图

截图可作为辅助，但应优先提交机器可读的 IP 列表、原始相关日志和 ASN 结果。

### 错误 4：把请求数当作唯一 IP 数

两者必须分别统计。

### 错误 5：ASN 统计按日志行计数

应先 `sort -u` 得到唯一 IP，再做 ASN 分布，否则请求量大的 IP 会扭曲归属统计。

### 错误 6：过早定性为 DDoS

若没有容量耗尽、可用性影响、请求速率/带宽证据等，不要仅因 IP 多而称 DDoS。

### 错误 7：README 写死某次事件数字

Skill 中只使用变量；任何具体事件的 IP 数量、请求数和 ASN 分布都属于 case data，不应成为通用逻辑。

## 输出格式

运行本 Skill 后，优先输出以下结构：

### A. 事件摘要

- 时间范围：
- 总请求数：
- 唯一 IP：
- 主要 UA：
- 主要 Path：
- ASN 分布：
- 推荐定性：

### B. 证据判断

分别列出：

- 已证明；
- 高可信分析；
- 尚不能证明。

### C. 服务器命令

只提供只读/复制/统计命令；任何可能修改原日志的操作必须单独警告并默认避免。

### D. 举报材料

生成：

- `README.txt`
- `source-ips.txt`
- `source-ips-form.txt`
- `nginx-access.log`
- `bgp-asn.txt`
- `summary.txt`
- 可选 `checksums.txt`

### E. 举报正文

根据平台语言生成中文或英文版本，并保持证据边界。

## 与 Fail2Ban / 防御动作的边界

本 Skill 的主目标是取证、识别、定性和举报，不默认执行封禁。

如果用户进一步要求防御：

- 可以基于已确认 IOC 生成 Fail2Ban filter/jail、Nginx rate limit、临时封禁命令；
- 先避免误封搜索引擎、CDN、健康检查、公司 NAT、监控节点；
- 封禁策略与举报证据应分开保存，避免将“被本地封禁”误当作恶意性的证明。

## Case Example — Tencent 2026-09

以下仅是示例，不应在其他事件中硬编码：

- N 个唯一源 IP；
- X 个 IP -> AS64500；
- Y 个 IP -> AS64501；
- Non-Tencent ASN: 0；
- 大量地址使用相同 legacy iPhone Safari User-Agent；
- 推荐定性：`Distributed automated HTTP traffic / apparent abuse`；
- 不足以单独证明：同一腾讯云租户、同一实例、同一控制主体或腾讯云自身实施攻击。

