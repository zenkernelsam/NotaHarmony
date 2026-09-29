# Phase 1066 证据 — ry0 块 spec + e4c 集合 + 委托属性名册

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ry0 implements be5, ce5, bf0`

= **块实体 spec**（CREATE_BLOCK `rl2` 物化，区别于 `m5d` 的
CREATE_SHAPE `ao2`）。字段：`{uq9 b, rl2 c, int d, yc6 e..m,
qo5 n, cxc o, fqa p, cz0 q, qed r, k11 s, v09 t, long u}`。

### `fl6[] v` = Kotlin 委托属性名册（8 属性）

| 属性 | 类型 |
|------|------|
| rotation | Float |
| scale | Size |
| size | Size |
| corner | BlockCornerType |
| textWrap | TextWrapMode |
| enableCaption | Boolean |
| positionLocked | Boolean |
| zIndex | `getZIndex-tJoBMIg()J` —— **ULong 名称修饰** |

`zIndex-tJoBMIg` 证实 zIndex 是 `ULong`（tmf，Phase 1060）
—— Kotlin 值类名修饰保留在字节码。

## `e4c implements o4c`

= CRDT **集合**（子成员/组）：
`{m4c, ArrayList c, k4c, iwc, gja, al2, int h}`；
`q = rh8.b(-1,0)` 哨兵 opId。

## Harmony 决策

- 块 spec 8 委托属性原样；zIndex=ULong。
- `e4c` = 组/成员集合（寄存器式列表）。

## 产出

- fixture `d02-block-spec.mjs`（10 断言）。
- ADR-1010；中文报告。
