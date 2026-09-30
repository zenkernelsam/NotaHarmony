# Phase 1188 证据 — op 载荷回读（vq9/ka4/cee → uq9）

来源：`defpackage/{vq9,ka4,eg5}.java`。

## `vq9 extends cee implements ka4` = CREATE op 载荷表

```java
vq9 (cee FlatBuffers 表基):
  a()→String          // 槽字符串
  j()→Boolean         // bool
  k()→qo5             // opId 读回（buffer→qo5.b 绑）
  l()→String          // c(8) 槽字符串
  m()→uq9 / n(uq9)    // →uq9 op 包装（字段拷入）
```

`k()` 回读 `qo5`（opId）→ `n()` 把载荷字段拷进 `uq9`
op —— op 载荷→完整 op 桥。

## `ka4` = op 载荷 iface；`eg5`=`uq9` 工厂 lambda

## 判定

**op 回读层**：`cee` 载荷表（`vq9` 等 32 载荷）→
`k()→qo5` opId + 字段 → `n()→uq9` 完整 op ——
CREATE/MODIFY op 解包 + 重组。`ka4` 统一载荷契约。

## Harmony 决策

`cee`/`ka4`/`vq9`/`uq9` → Harmony op-payload struct +
`rebuild opId` + `into-op`（同 Phase 1096-1098 载荷层）。

## 产出

- fixture `d02-op-readback.mjs`（10 断言）。
- ADR-1132；中文报告。
