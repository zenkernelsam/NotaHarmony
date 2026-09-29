# Phase 1091 证据 — 文本序列 CRDT 内部类型

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 类型谱系

| 类 | 角色 |
|----|------|
| `hr5 implements exc` | **可变锚点 builder** `{J:short site, K:int, L:int}` |
| `swc` iface | **锚点导航器** `a()→qwc`,`c()→long`,`d(hr5)→hr5` 派生,`e(rwc)→rwc`,`getParent()→qwc` |
| `s3c` | 文本片段 `{Set a, Set b 样式集, CharSequence c 内容, double d, int e}` |
| `gxc extends y3` | 线序列化锚点（FlatBuffers） |
| `qwc`/`rwc`/`mxc` | 序列树节点/范围/基 iface |

## 语义

- `hr5` 可变锚点：插入时 `swc.d(hr5)` 派生新锚
  （fractional 分配在 (site,seq) 空间）。
- `s3c` = 带样式集的文本段（双 Set = 字符/段落样式）。
- `swc` 导航器 = 序列树父/子遍历。

## Harmony 决策

- 文本 CRDT = exc 锚序列 + swc 树导航 + s3c 片段；
  `hr5` 可变 builder。

## 产出

- fixture `d02-text-sequence.mjs`（10 断言）。
- ADR-1035；中文报告。
