# Phase 872 证据 — 块/位置/删除 op payload 登记（类型 22–25）

## 目的

登记 `haa` 22–25 四表：`rl2` CREATE_BLOCK、`td8` MODIFY_BLOCK、
`je8` MODIFY_POSITIONS、`s83` DELETE_ENTITIES；核对 Harmony 写手。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### zq9 映射

```
rl2 -> CREATE_BLOCK(22)      td8 -> MODIFY_BLOCK(23)
je8 -> MODIFY_POSITIONS(24)  s83 -> DELETE_ENTITIES(25)
```

### `rl2` — CREATE_BLOCK（21 字段）

锚点：f1(c6)=ty0 块类型；f2(c8)=cxc 位置；f3(c10)=fqa；
f4(c12)=Float；f5/6(c14/16)=qed 尺寸×2；f8(c20)=boolean；
f10(c24)=dp5；f11(c26)=bmb；f13(c30)=String；f14(c32)=hu1；
f15(c34)=k3a；f16/17/18/19(c36/38/40/44)=boolean×4；
f20(c42)=vy7 —— 富块（文本/图像）创建表。

### `td8` — MODIFY_BLOCK（18 槽，f0–f17 缺 f9 —— 与 856 容量一致）

| 字段 | 读法 | 字段 | 读法 |
|------|------|------|------|
| f0 | qo5 目标向量 | f10 | `q()`→z2d setter |
| f1 | `k()`→ty0 | f11 | `p()`→g2d setter |
| f2 | `s()`→cxc | f12 | `l()`→p2d setter |
| f3 | `r()`→fqa | f13 | `t()`→n2d setter |
| f4 | `w()`→k2d | f14 | `n()`→Boolean |
| f5 | `x()`→y2d | f15 | `o()`→Boolean |
| f6 | `y()`→qed | f16 | `v()`→Boolean |
| f7 | `z()`→ive | f17 | `u()`→Boolean |
| f8 | `m()`→Boolean | — | — |

（p2d/n2d/z2d/ive/k2d/y2d = 块修改 setter 表。）

### `je8` — MODIFY_POSITIONS（单字段表）

f0 = 位置向量（`k(int,·)` 元素写 + `j()` int 计数）——
只携带一组位置更新。

### `s83` — DELETE_ENTITIES（4 字段，各为「访问器+计数」向量）

| 字段 | 元素类型 | 语义 |
|------|----------|------|
| f0 | qo5 向量（`j()`+`l()`count） | entityDeletes |
| f1 | qo5 向量（`k()`+`m()`count） | entityUndeletes |
| f2 | cxc 向量（`p()`+`n()`count） | pageDeletes |
| f3 | cxc 向量（`q()`+`o()`count） | pageUndeletes |

实体按 op-id（qo5）寻址，页面按位置（cxc）寻址——
删除/复活同表双向字段。

## Harmony 侧

- `OriginalDeleteEntitiesPayloadEncoder`：注释即
  `entityDeletes, entityUndeletes, pageDeletes, pageUndeletes`
  四字段向量，空字段省略（starts[field]==0 → 0）。
- `OriginalCreateBlockPayloadEncoder`/`OriginalModifyBlockPayloadEncoder`
  + Operation 层、`OriginalModifyPositionsPayloadEncoder`/
  `DeletePageCompensationOpCodec`/`PageDeleteCheckpoint` 配套。

## 结论

22–25 四表登记完毕；s83 双向四向量布局与 Harmony 编码器
字段顺序/元素类型逐项一致。纯文档+fixture 阶段。
