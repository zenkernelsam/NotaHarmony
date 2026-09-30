# Phase 1126 证据 — f8d = SharedNodeData + hr5 可变锚字段

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `f8d` = `SharedNodeData`（toString 泄漏实名）

```
SharedNodeData(rawSiteId, rawTimestamp, rawAudioTime, parent, values)
```

```java
f8d { short a;   // rawSiteId
      int b;     // rawTimestamp
      long c;    // rawAudioTime
      qwc d;     // parent 游标
      List e;    // values
      int f }    // 计数
```

- 序列树共享节点：站点+时戳+音频时戳 + 父游标 + 值列表。
- eq = 全字段；hashCode = site/ts/audio/parent/values 组合。

## `f8d.a(hr5, i)` = 锚点写出

```java
hr5.J = this.a;   // site
hr5.K = this.b;   // timestamp
hr5.L = i;        // slot seq
```

`qwc.d(hr5)`/`rwc.d(hr5)` 调它 —— 把节点的 {site,ts} 和
槽位 i 写进可变 `hr5` 锚。

## `hr5` = 可变 `exc` 锚 `{J:site, K:timestamp, L:seq}`

对应 `exc` 不可变锚 `{m:site, a1:key(ts), C:seq}` —
同一三元组的可变/不可变两态。

## Harmony 决策

- 序列节点 = `{site,ts,audioTs,parent,values}` 共享数据。
- 锚 = `{site,ts,seq}` 三元组；hr5 为可写出参变体。

## 产出

- fixture `d02-shared-node.mjs`（10 断言）。
- ADR-1070；中文报告。
