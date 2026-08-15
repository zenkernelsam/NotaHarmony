# 原版 Math standalone bitmap raster scale：JADX 线性证据

## 来源

- APK：`C:\Users\Cisco He\Desktop\Notability\Notability_1.0.3\com.gingerlabs.notability.apk`
- SHA-256：`3C616F6ED15B4DA14108A66B67A480BBA5789916A901FCDF7DE5192FA55B674B`
- JADX：1.5.6
- 日期：2026-08-15

普通 `decompiled_1.0.3/sources/defpackage/aeg.java` 的 `invokeSuspend()` 与
`ue4.v()` 因 JADX SSA/constructor pass 失败而缺失。为避免根据寄存器名猜测，分别执行单类 fallback/simple
线性反编译，并保留下面的最小证据摘录。原版目录本身没有被修改。

```powershell
jadx.bat --single-class defpackage.aeg --single-class-output $env:TEMP\nota-aeg-fallback-20260815.java `
  --decompilation-mode fallback --comments-level debug com.gingerlabs.notability.apk
jadx.bat --single-class defpackage.ue4 --single-class-output $env:TEMP\nota-ue4-simple-20260815.java `
  --decompilation-mode simple --comments-level debug com.gingerlabs.notability.apk
```

## `aeg.invokeSuspend()`：两个 float 的来源

```java
ue4 r0 = r14.d
r2 = r26
a79 r2 = (defpackage.a79) r2
java.util.Map r2 = r2.h
float r3 = r13.a
r93 r4 = r13.f
float r4 = r4.a()
boolean r5 = r1.Y
...
java.lang.Object r0 = r0.v(r1, r2, r3, r4, r5, r6)
```

同一 coroutine 的入口把 `r1 = r10.k0`，而 `k0` 的静态类型是 `t0g`。原版 `t0g.toString()` 明确把
`t0g.a` 命名为 `ViewportState.zoom`，把 `t0g.f` 命名为 `density`；`r93.a()` 是 Density 的像素倍率。

## `ue4.v()`：clamp 与 0.5 量化

```java
float r31 = m18.y0(rh8.u(r20 * r21, 1.0f, 4.0f) * 2.0f) / 2.0f;
...
r25 = r31;
...
r17.P = r25;
...
r0 = r3.G(r111, r210, r211, r29, r212);
```

`m18.y0(float)` 是 `Math.round(float)`；`rh8.u(float, min, max)` 是闭区间 clamp。因此 standalone Math
bitmap 的原版倍率是：

```text
round(clamp(viewportZoom × density, 1, 4) × 2) / 2
```

## `ue4.G()`：量化结果继续传给 bitmap renderer

```java
public Object G(r08 r8, Map r9, float r10, boolean r11, ff2 r12) {
    ...
    Object r23 = E(r14, r22, r10, r0);
    ...
}
```

`ue4.E()` 的缓存键包含这个 float，并最终创建 `p18(..., blockWidth, blockHeight, rasterScale, color)`。
这排除了“固定 2×”以及“只按 zoom、不按 Density”两种解释。
