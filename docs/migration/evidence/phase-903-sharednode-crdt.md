# Phase 903 证据 — `f8d` SharedNodeData + CRDT 节点引用层

## 目的

实名 882 触及的 CRDT 共享树节点层。`decompiled_1.0.3`。

## `f8d` = `SharedNodeData`（toString 实证）

```java
SharedNodeData(rawSiteId=, rawTimestamp=, rawAudioTime=,
               parent=, values=)
    short a;      // rawSiteId
    int b;        // rawTimestamp
    long c;       // rawAudioTime
    qwc d;        // parent 节点链
    List e;       // values（节点承载值表）
    int f;        // 计数/容量
```

`a(hr5,i)`：`hr5.J=a; hr5.K=b; hr5.L=i`——把节点
身份写入 `hr5` 记录。

## `hr5` = 线上节点身份 = **cxc 同型三元组**

`{J=siteId, K=timestamp, L=index}`——与 880 `cxc`
（site+u16pad+timestamp+index 12B）语义同型：
节点身份 = {站点, 时间戳, 序内索引}。

## `swc`/`qwc`/`rwc` = 节点引用三层

| 类型 | 角色 |
|------|------|
| `swc` | 引用接口：`a()`→qwc、`c()`→audioTime、
`d(hr5)`=导出线上、`e(rwc)`=导出可变、`getParent/
getValue` |
| `qwc` | **已解析引用**（不可变）：`a()=this`、
`d()` 把 f8d+index 写进 hr5 |
| `rwc` | **惰性/未解析引用**：`{f8d a=null, b=-1}`；
`a()`→qwc 物化，`sharedData` 未设 → `ba6.d0` 抛 |

## 语义

CRDT 共享树：节点携带 {site,ts,audioTime} 身份 +
父链 + 值表；引用分 resolved(qwc)/lazy(rwc) 两态，
线上以 hr5 三元组寻址——树序遍历/合并由此支撑。

## Harmony 侧

Harmony 序列身份（`compareOriginalSequenceIdentity`/
cxc 同构）↔ hr5 三元组；元素树 provenance ↔
SharedNodeData 父链/值表语义。

## 结论

CRDT 共享树节点层实名：f8d 数据、swc/qwc/rwc 引用
三态、hr5=cxc 同型线上身份。纯文档+fixture 阶段。
