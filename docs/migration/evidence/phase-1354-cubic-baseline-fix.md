# Phase 1354 证据 — cubic-fitter 基线归属更正

**更正 Phase 1326**：`sqh`/`wy5` 引为 cubic-fitter 基线
误标。实读：`sqh`/`tdh`/`qeh`/`e2h`/`lm9`/`bx3` =
**kotlinx-serialization 多态注册器**。

## 真实内容

```
qeh = @interface（注解）
tdh implements qeh —— qeh.class（注解类型工厂）
sqh implements lm9 extends bx3 —— bx3/lm9 = serialization
  SerializersModule 链；sqh.a 单例经 e2h.i/m 链式注册
  e2h.i(qeh.class, e2h.m(qeh.class, new tdh(1), 2)...) ——
  多态序列化器注册
wy5 implements ko3 extends nd8 extends pd8 —— Compose
  Modifier.Element 链（draw modifier，非拟合）
```

→ `sqh`/`wy5`/`tdh`/`qeh` = **kotlinx-serialization 多态
模块注册 + Compose Modifier**，非 cubic-fit 算法。

## 更正说明

Phase 1326 把 `sqh.f`/`wy5` 当 cubic-fitter 基线误标。
真实 least-squares bezier 拟合器在别处（`*5d`/rendering
族待进一步定位）。Harmony `CubicFitter`（最小二乘
cubic+>200pt 二分分段+zoom 容差）实现本身正确 —
— 误标仅在原版基线符号。

## Harmony 决策

更正 cubic-fitter 基线归属（`sqh`/`wy5` 实为序列化注册
器/Modifier）；真实拟合算法基线待精确定位。

## 产出

- fixture `d02-cubic-baseline-fix.mjs`（10 断言）。
- ADR-1295；中文报告。
