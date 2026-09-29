# Phase 1092 证据 — 序列树节点族（qwc/rwc/xwc/ywc/mxc）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `swc` 导航器的两个实现（序列树）

| 类 | 角色 |
|----|------|
| `qwc implements swc` | `{f8d, int}` **序列树节点**导航（getParent→qwc） |
| `rwc implements swc` | **范围**导航（文本区间，`e(rwc)→rwc`） |

`mxc` = 基接口；`f8d` = 树节点数据。

## `ywc` 定位元素基 + `xwc`

```java
ywc { Integer a }                 // 抽象基（int 位置标签）
xwc extends ywc { qo5 b, g2c c, long d }
                                // 定位元素 {opId, g2c, pos}
g2c extends hvd { f2c }         // REVIVE_CHARS 包装元素
```

文本序列 = 因果序的 `ywc` 定位元素树（opId+position 键）。

## Harmony 决策

- 序列树 = qwc(节点)/rwc(范围) 导航器 + ywc 定位元素；
  `xwc`{qo5,g2c,pos} 承载 revive 元素。

## 产出

- fixture `d02-seq-tree.mjs`（10 断言）。
- ADR-1036；中文报告。
