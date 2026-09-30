# Phase 1168 证据 — libglmath fail-closed 机制（kd 守卫）

来源：`defpackage/kd.java` + `MissingNativeLibraryActivity` +
`arm64_extracted/lib/arm64-v8a/libglmath.so`。

## `libglmath.so` = arm64 编译原生库

`arm64_extracted/lib/arm64-v8a/libglmath.so` —— 真实
arm64 .so（`GLMathNative` JNI 绑 `nativeInit/nativeMeasure/
nativeDraw`）—— Android bionic + JNI ABI，**HarmonyOS
不可直接加载**。

## `kd` = native 加载守卫（lambda 分派 case 1）

```java
case 1:   // glmath 加载失败回调
  Intent i = new Intent(app, MissingNativeLibraryActivity)
             .addFlags(268468224);   // NEW_TASK|CLEAR_TASK|
                                     // EXCLUDE_FROM_RECENTS
  if (mainLooper) app.startActivity(i)
  else Handler(main).post(l43(17, app, i));
```

glmath 加载失败 → 启 `MissingNativeLibraryActivity`（不可
取消 AlertDialog `app__missing_native_library_title/
message` + OK→退出）。

## 加载链

`GLMathNative` static `System.loadLibrary("glmath")` →
`UnsatisfiedLinkError` → `AppStartupInitializer` catch →
`kd` case1 → 致命对话框 → 退出。

## 判定：**fail-closed**（非 graceful-degrade）

原版对缺 `libglmath` = **致命错误 + 退出** —— 数学渲染
是硬依赖（LaTeX 文本/绘制）。修正 Phase 1167 的"降级"
误读：原版**不**优雅降级，而是拒绝启动。

## Harmony 决策

- `libglmath.so` arm64 bionic —— **不可移植**：
  (a) 若可逆 `nativeMeasure/nativeDraw`（测宽/绘制字形
      数学式）→ 纯 ArkTS/C++ 重写（大工程）；
  (b) 否则 **fail-closed**：数学渲染功能整块关闭，入口
      隐藏 —— 与原版"缺库即拒启动"语义对齐（Harmony
      上该功能不可用，但不 crash 整个 app）。

## 产出

- fixture `d02-glmath-failclosed.mjs`（10 断言）。
- ADR-1112（fail-closed）；中文报告。
