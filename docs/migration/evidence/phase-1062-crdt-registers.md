# Phase 1062 证据 — CRDT 寄存器应用层

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
（真实类名：`com.gingerlabs.notability.core.model.crdt.Register$Builder`）

## `fi0.d(uq9, ie8)` = 实体属性寄存器应用模板

```java
rz1.R(pageAndOriginRegister-ref, op, new k1a(new tz9(page), origin));
rz1.P(rotationRegister-ref, op, ie8Var.l());   // SetFloat?
rz1.Q(scaleRegister-ref, op, ie8Var.m());
rz1.R(zIndexRegister-ref, op, xgb(tmf.I));
if (任一变) A();  // 失效回调
```

- `ie8` = Modify 视图（k()=cxc 页、j()=fqa 原点、
  l()=rotation、m()=scale、o()=tmf zIndex）。
- `ei0` = Kotlin callable reference（指向
  `Register$Builder` 方法名）。

## `rz1` 寄存器写助手

```java
static boolean R(v1b reg, uq9 op, Object v) {
    if (v == null) return false;
    ((fqb) reg.get()).c(uq9Var, v);   // 因果键写入
    return true;
}
```

`v1b` = Provider<Register.Builder>；`fqb` =
**Register$Builder**；`c(uq9, value)` = 带 op 因果的
寄存器写（LWW/收敛语义由 op 序决定）。P/Q 为
rotation/scale 特化（k2d SetFloat / y2d 值型）。

## 值包装

`k1a`=page+origin 对、`tz9`=cxc 包装、`xgb`=zIndex
ULong 包装、`y2d`=scale 值、`k2d`=SetFloat。

## `be5` 实体变换 iface（同族）

`{G()→k11 bounds, P(fqa)→float[] 矩阵, y(k11) 变换}`；
`m5d`/`ry0` 等实体实现；`y18`=Matrix 助手。

## Harmony 决策

- **CRDT 核心语义保留**：每属性独立寄存器+op 因果写；
  无变化不触发失效；值包装类型保留。

## 产出

- fixture `d02-crdt-registers.mjs`（11 断言）。
- ADR-1006；中文报告。
