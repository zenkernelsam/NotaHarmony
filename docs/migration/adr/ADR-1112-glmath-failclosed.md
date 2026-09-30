# ADR-1112：libglmath 数学渲染 — fail-closed

## 状态

已接受（Phase 1168）—— **fail-closed**（修正 Phase 1167
的"优雅降级"误读）。

## 决策

`libglmath.so` arm64 bionic + JNI —— **HarmonyOS 不可
加载**；原版对缺库 = **致命对话框 + 退出**（
`kd`→`MissingNativeLibraryActivity` NEW_TASK|CLEAR_TASK，
`setCancelable(false)`）—— 硬依赖、非降级。

## 理由

- 原生编译 .so（Android bionic/JNI ABI），OHOS 无等价
  ABI + JNI 桥。
- 原版语义 = 缺库即拒启动 → 数学渲染是硬依赖。
- 选项：(a) 逆 `nativeMeasure/nativeDraw` 纯 ArkTS/C++
  重写（大工程、需字体度量+LaTeX 排版）；
  (b) fail-closed：数学功能整块关闭、入口隐藏。

## 后果

- Harmony：若无可移植重写 → 数学公式渲染 fail-closed
  （入口置灰/隐藏）；笔记数据（含数学串）仍可读写，
  仅渲染禁用 —— 与原版"缺库拒启动"同语义但缩到
  功能级（不 crash 整个 app）。

## 开放

`nativeMeasure/nativeDraw` 可逆性评估为后续项。
