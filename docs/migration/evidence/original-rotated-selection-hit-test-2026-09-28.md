# 原版证据：旋转选区命中测试（yxi.e）— Phase 619

来源：`decompiled_1.0.3/sources/defpackage/`（Notability 1.0.3 反编译，只读证据树）。

## yxi.java:88-91 — e(cmb, j, f, j2) 旋转点测试

```java
public static final boolean e(cmb cmbVar, long j, Float f, long j2) {
    cmbVar.getClass();
    return f == null ? cmbVar.a(j)
        : cmbVar.a(y18.c(j, b(-ldj.t2(f.floatValue()), j2)));
}
```

- `cmbVar.a(j)` = 轴对齐矩形包含。
- `f != null` 时：先把测试点 `j` 用 `y18.c` 施加 `b(-f, j2)`（绕中心
  `j2` 旋转 `-f` 的仿射矩阵），再做轴对齐包含。
- 即：**选区矩形以"未旋转矩形 + 旋转角"存储**；命中测试把点反旋转
  回未旋转坐标系再测矩形——等价于测试点是否落在真实旋转四边形内。

## y18.java:76-95 — c(j, fArr) 4×4 仿射点变换

`c` 对点做完整 4×4 矩阵乘法（含透视除法）；`b(-f, j2)` 构造绕 `j2`
旋转 `-f` 的矩阵。Harmony 侧用等价的 2D 旋转公式即可（无透视项）。

## dl1.java 调用点 — 全部"点在选区内"判定经 yxi.e

```text
dl1.java:114  — ftc 分派：yxi.e(cmbVar, jE, ftcVar.d, fi3.b(cmbVar))
dl1.java:182  — ftc 分派（第二分支）：同上
dl1.java:212  — itc/gtc 分派：yxi.e(cmbVarA, jE, htcVar.g(), fi3.b(cmbVarA))
dl1.java:267  — 同上（第二分支）
```

- `htc.a()` = 选区的未旋转矩形；`htc.g()` = 选区旋转角（`Float`，无
  旋转时为 null）；`fi3.b` = 矩形中心。
- `itc`（单元素选区）的 `g()` 暴露元素的旋转寄存器值——单个旋转
  元素命中判定必须反旋转，否则其屏幕 AABB 的四角区会误命中为
  "选区内"（应判"选区外"→ 取消选择/穿透命中下层元素）。

## lg2.java 的 htc 关联（本 Phase 的入口线索）

`lg2.f(...)`（粘贴位置产生器）区分 `htc` 与非 `htc` 选区：粘贴时
`z==true` 且选区带矩形 → 保留"内容中心 ↔ 矩形中心"偏移。Harmony
模型中无独立于内容边界的区域矩形（`selectionRect` 即内容 AABB），
该分支不可表达、无行为差；同一 `htc` 接口上的 `g()` 旋转寄存器
则对应本 Phase 的命中测试差异。

## 原版行为总结

1. 无旋转（`g()==null`）：轴对齐矩形包含。
2. 有旋转：测试点绕未旋转矩形中心反旋转 `-g()`，再做轴对齐包含。
3. 判定枢纽是**未旋转矩形**（`htc.a()`），不是旋转后四边形的
   AABB——AABB 四角区在原版一律判为"外部"。

## Harmony 差异（修复前）

- `selectionRect` = 已旋转元素的屏幕 AABB，比真实旋转四边形大；
  `pointInRect(touch, selectionRect)` 把 AABB 四角误命中。
- 受影响路径：选区内按下→拖拽/缩放判定、deselectMode 的"外部按下
  →取消模式"判定（4 个 `pointInRect` 调用点）。

## Harmony 对齐（修复后）

- `itc` 等价范围：单个带 `rotationRadians≠0` 的选中元素 → 克隆元素
  去旋转取未旋转 `bounds`→屏幕矩形；触点绕该矩形中心反旋转 `-θ`
  后做轴对齐包含（`singleSelectedUnrotatedScreenRect` +
  `pointInSelectionRect`，对应 `y18.c` + `cmb.a`）。
- 多元素/组选区（`ftc.d` 级旋转在 Harmony 模型中无独立寄存器，各
  元素 `rotationRadians` 可不同）退回 AABB 测试——原版 `ftc.d` 仅
  在"选区整体旋转"操作语境非零，Harmony 等效场景不可静态表达。
- 无旋转/单笔（无旋转寄存器）→ `g()==null` 分支等价：AABB。
