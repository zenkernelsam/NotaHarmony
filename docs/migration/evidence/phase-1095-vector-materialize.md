# Phase 1095 证据 — lv2 向量物化助手（S/I/T）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `lv2.S(je8) → List<ie8>` = ModifyPositions 项物化

```java
int n = je8.j();                    // 向量计数 slot
if (n <= 0) return hw3.I;           // 空 → 不可变空表
th7 b = m18.S();                    // 持久 list builder
for i in 0..n:
    ie8 e = new ie8();
    je8.k(e, i);                    // 第 i 元素绑定（FlatBuffers）
    b.add(e);
return m18.E(b);                    // 冻结成不可变
```

## 通用 FB 向量→List 模式

- `j()` = 元素数（vtable slot）；`k(elem,i)` = 第 i 元素
  绑定到复用表对象（FlatBuffers `__assign`）。
- `m18.S()`/`E()` = 持久化 builder/freeze（Phase 1052）。
- `lv2.I(s83)` = DELETE 列表；`lv2.T(r29)` = bundle 向量。

## Harmony 决策

- FB 向量→List：`count + per-index bind + 持久化构建`；
  空→`hw3.I` 单例。

## 产出

- fixture `d02-vector-materialize.mjs`（10 断言）。
- ADR-1039；中文报告。
