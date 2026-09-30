# Phase 1128 证据 — f2c 序列元素 FlatBuffers 表

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `f2c extends cee implements ka4` = 序列元素表

```java
j() → int:         c(4) slot → vector length        // 元素数
k() → qo5:         c(6) slot → 嵌 struct qo5         // opId
l(i, cxc):         c(4) + f(iC) + i*12               // 第 i 个 cxc
```

- **元素 = 12-byte `cxc` struct 向量**（步长 `i*12`）——
  与 `sg5.f` 写的 12-byte `exc` 锚同构（cxc 属 exc 家族 pageId）。
- `l(i,cxc)` 绑读直写出参；`k()` 嵌读 opId。
- hashCode = `lv2.O(this)*31 + qo5?.hashCode`（向量哈希+id）。

## 布局

```
table f2c {
  slot4: [cxc]   // 12B stride — 锚向量
  slot6: qo5     // 共享 opId
}
```

g2c 包它成 List；xwc = {opId, 这些锚, pos} —— 序列树节点
的 wire 形态。

## Harmony 决策

- 序列元素 wire = `{cxc[]@12B, qo5}`；读 = 向量步长绑读。
- 12-byte 锚与 exc 结构体互认。

## 产出

- fixture `d02-f2c-table.mjs`（10 断言）。
- ADR-1072；中文报告。
