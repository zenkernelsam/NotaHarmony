# Phase 871 证据 — 形状/组 op payload 登记（类型 18–21）

## 目的

登记 `haa` 18–21 四表：`ao2` CREATE_SHAPE、`le8` MODIFY_SHAPE、
`cm2` CREATE_GROUP、`vd8` MODIFY_GROUP；核对 Harmony 写手。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### zq9 映射

```
ao2 -> CREATE_SHAPE(18)   le8 -> MODIFY_SHAPE(19)
cm2 -> CREATE_GROUP(20)  vd8 -> MODIFY_GROUP(21)
```

### `ao2` — CREATE_SHAPE（17 槽，f0–f17 缺 f5）

| 字段 | 读法 | 字段 | 读法 |
|------|------|------|------|
| f0 | `r()`→cxc 位置 | f9 | `k()`→hu1 颜色 |
| f1 | `q()`→fqa | f10 | `j()`→float |
| f2 | `t()`→Float | f11 | `m()`→hu1 填充色 |
| f3 | `u()`→qed 尺寸 | f12 | `z()`→tmf |
| f4 | `l()`→z4d | f13 | `v()`→boolean |
| f6 | `y()`→u16 结构 | f14 | `n()`→Float |
| f7 | `w()`→t16 样式 | f15 | `s()`→boolean |
| f8 | `x()`→ife | f16 | `o()`→long |
| — | — | f17 | `p()`→boolean |

### `le8` — MODIFY_SHAPE（16 读字段；856 登记 writer 容量 17）

| 字段 | 读法 | 字段 | 读法 |
|------|------|------|------|
| f0 | `a()` + qo5 向量（目标） | f10 | `l()`→hu1 **颜色** |
| f1 | `r()`→cxc | f11 | `k()`→Float **边宽** |
| f2 | `q()`→fqa | f12 | `j()`→g2d **填充色 setter** |
| f3 | `z()`→k2d | f13 | `y()`→tmf |
| f5 | `m()`→z4d | f14 | `s()`→Boolean **锁定** |
| f7 | `x()`→u16 | f15 | `o()`→tmf |
| f8 | `w()`→ife **样式** | f16 | `p()`→Boolean |

### `cm2` — CREATE_GROUP（单字段表）

f0 = 成员向量（`j(int,·)` 元素写 + `a()` 校验）——
CREATE_GROUP 只携带成员 id 集。

### `vd8` — MODIFY_GROUP

f0 = `j()`→qo5 目标组；f1 = `k()` int 计数 + `l(int,·)`
元素访问 —— 成员向量。

## Harmony 侧（`note/src/main/ets/data`）

- `OriginalModifyShapePayloadEncoder`：17 槽 vtable，
  fields[0]=4 目标；`u5j.x` 注释与原版一致地写
  style@8/color@10/borderWidth@11/fillColor@12/lock@14 ——
  对上 ife/hu1/Float/g2d/Boolean。
- `OriginalCreateShapePayloadEncoder`、`OriginalGroupPayloadEncoder`
  （cm2 单字段成员向量：qo5 siteId+timestamp 逐成员）、
  `OriginalGroupMutationOpCodec`（vd8 修改）、
  `OriginalShapeGroupOperation`/`OriginalGroupLayering`/
  `OriginalPartialEraseGroupPlanner` 配套层。

## 结论

形状/组四表字段模式登记完毕；Harmony 写手字段锚点逐项一致。
纯文档+fixture 阶段。
