# 原版证据：LOCK/UNLOCK 门槛（xsc.k + dhb case18/19）— Phase 617

来源：`decompiled_1.0.3/sources/defpackage/`（Notability 1.0.3 反编译，只读证据树）。

## 类型层级（m4d = 形状家族；oy0 = 块家族）

- `m4d.java:4`：`interface m4d extends ly3`——可定位接口。
- `n5d.java:8`：`n5d implements yy3, bf0, be5, m4d`——形状实体，
  元素类型中唯一的 `m4d`，含 `positionLocked` 寄存器。
- `oy0.java:4`：`interface oy0 extends ly3`——块基类。
- `hp5.java:8`（图像）、`r08.java:4`（文本/数学块基类）均为
  `oy0`/`be5`，**不是 `m4d`**；笔画为 `s06`。

## xsc.java:216-240 — k(ktc)：多选/单组的锁方向解析

```java
public final Boolean k(ktc ktcVar) {
    if (x09VarN == null || ktcVar.h().isEmpty()) return null;
    while (it.hasNext()) {
        be5 be5VarI = tl7.I(x09VarN, qo5, 6);
        if (be5VarI != null) {
            if (!(be5VarI instanceof m4d)) return null;   // 非 m4d 成员→死
            m4d m4dVar = (m4d) be5VarI;
            if (cih.a(m4dVar)) {                          // n5d 形状判定
                if (!((n5d) m4dVar).t()) z2 = false;      // 存在未锁形状
                z = true;
            }
        }
    }
    return z ? Boolean.valueOf(z2) : null;                // 无形状→死
}
```

- `ktc.h()` = 平铺成员集（组展开为成员 id）。
- **任一成员非 `m4d`（笔画/图像/文本/数学块）→ null →
  `dhb` case18/19 `boolK == null` → 静默不执行**。
- 无 `n5d` 成员 → null；有 → `z2`（全部形状已锁）= UNLOCK 方向。

## dhb.java:17997-18034 — case18/19 执行

- `itc` 单元素：`be5VarI instanceof oy0` → `u5j.n` 翻转
  `!oy0.t()`；`instanceof m4d && cih.a` → `u5j.x` 翻转
  `!n5d.t()`——**单 oy0 块/形状可锁，`s06` 笔画产出空 op
  （`objX` 保持 null，`wsc` 收到空负载=死操作）**。
- 非 itc：`xsc.k` 判向后过滤 `cih.a(m4d) && t() != z15`
  （仅状态需翻转的形状）→ `vz6` 协程 + `fvb.a()` 清选。

## Harmony 差异与修复

旧门槛 `onlyShapesSelected || (selectedCount === 1 && 无组)`：

1. `selectedCount` 计入笔画——**单笔画选区显示 LOCK**
   （原版 itc 对 s06 产出空 op，死操作）。
2. 多选/单组语义未按 `ktc.h()` 展开校验（组成员恰在
   selectedEntityIds 中故旧实现碰巧可用，但门槛未声明
   成员展开语义）。

Phase 617：`allMembersAreShapes` = 展开组叶子后所有成员
（散件 id + 组叶子）都是形状 ⇔ `xsc.k` 非 null 且有 n5d；
`selectionCanLock = allMembersAreShapes || (无组 &&
selectedCount === 1 && lockableCount === 1)`——单元素须为
oy0/m4d 等价（形状/文本/图像/数学），单笔画死路径对齐。
`selectionPositionLocked` 增加组成员形状全锁判定；
`setSelectedPositionLocked` 把组叶子并入生效形状集合，
保留 `t() != z15` 逐项过滤。
