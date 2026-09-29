# Phase 1052 证据 — lv2 向量访问器范型 + 持久化集合机制

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `lv2` 向量访问器范型（所有载荷共用）

```java
public static final List M(wd8 wd8Var) {
    int iC = wd8Var.c(4);                    // vtable 槽
    int i2 = iC != 0 ? wd8Var.i(iC) : 0;     // 向量长度
    if (i2 <= 0) return hw3.I;               // 空 → 持久化空单例
    th7 th7VarS = m18.S();                   // builder
    for (...) { qo5 q = new qo5();
        wd8Var.B(q, i3); th7VarS.add(q); }   // 逐元素 struct 读
    return m18.E(th7VarS);                   // 冻结 → 持久化 List
}
```

- 变体：`N/O`(qub/f2c cxc 向量)、`P/Q`(cm2/vd8 成员)、
  `I/J/W/X`(s83 删除四表→th7)、`Y`(ge8 页)、`u/e0`
  (td8/le8 块/形状)、`S`(je8)、`M`(wd8 inks→qo5)、
  `w/B/E|x/C/F`(dm2/wd8 编码路径)、`y/z`(gd 元素)、
  `f0/g0`(styleMap→th7)、`b0/c0`(yn2/ke8 segmentation)、
  `d0`(yda selectedEntities)、`T`(r29 op 列表)、
  `U`(vt9 OpsBundle→ops)、`V`(zgb)。

## 持久化集合机制

- `hw3.I` = 持久化**空 List 单例**（List+Serializable+
  RandomAccess+ik6）。
- `th7 extends u4` = 持久化 List builder：`{Object[] I,
  int J size, boolean K frozen}`，`L`=冻结 EMPTY。
- `m18.S()`=新建 builder；`m18.E(List)`=冻结成 `th7`。
- 与 Phase 990 `lgf` RRB 持久化树同族（collections-
  immutable vendored）。

## `lv2` 常量表（头部）

`a-h` = `oz/pz/qz/rz` ±INFINITY 1–4 维边界对象；
`zp9(7)`、`wz6[]` 空、`o5d.M`、`l=8.0f`、`m=24.0f`。

## Harmony 决策

- 向量读取范型统一建模：slot→len→逐元素→冻结持久化。
- 空集合统一 `hw3.I` 等价单例；builder/冻结两阶段。

## 产出

- fixture `d02-vector-accessors.mjs`（12 断言）。
- ADR-0996；中文报告。
