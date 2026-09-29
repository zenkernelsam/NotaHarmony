# Phase 1072 证据 — v69 操作应用状态机 + 实体类型表链

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `v69` = 文档级 op-apply 状态机

外层 `switch(op.m().ordinal())` 按 op 类型分发；
`liaVar.add(op)` 记入因果集合。

### MODIFY_POSITIONS (case 24, `je8`) 的实体路由

```java
boolean zP = fsi.P(op);                    // positionLocked?
for (ie8 ref : lv2.S(je8)):                // 每实体引用
    qo5 id = ref.n();
    if (!zP):
        t().get(id) → o06.d(op,ref)        // 类型 A
        else u().get(id) → k5d.d           // 类型 B
        else s().get(id) → wy0.d           // 类型 C
             (wy0 instanceof xhe → t09 集)
        else → "Inconsistent logic" 遥测错误
        set.add(o09(id))
    if (zP && r().I.get(id)==null):
        t()/u()/s()/n()/k() 链 → xy3/fkb 快照
        v().d(id, xy3.build())             // 物化进 map
    v().get(id) → qsa → …
```

## 实体类型表链

`t()`/`u()`/`s()`/`n()`/`k()`/`v()` = **六张按类别分的实体表**
（qo5→实体）：o06 / k5d / wy0 / fkb / xy3 / qsa 等 iface。
先按 opId 在各类表查找，找到则 `d(op,payload)` 应用。

## `fsi.P(uq9)` = positionLocked 判定

控制走 "直接应用" vs "物化快照" 分支。

## Harmony 决策

- op-apply = op-type switch → 实体表链查找 → 类型化 `d()`。
- positionLocked 物化进 `v()` 不变表。

## 产出

- fixture `d02-op-apply.mjs`（10 断言）。
- ADR-1016；中文报告。
