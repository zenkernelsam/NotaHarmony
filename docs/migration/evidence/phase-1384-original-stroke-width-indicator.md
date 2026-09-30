# Phase 1384 — 原版 stroke-width indicator 证据

## 原版调用链（decompiled_1.0.3）

```
宽度按钮
 └─ z5c.java:1669  h1aVarK  = rh8.K(swd.a(y31).a(uwd).b, uz4, 0)   // outline 环
    z5c.java:1688  h1aVarK2 = rh8.K(swd.a(y31).a(uwd).a, uz4, 0)   // fill 内填
    z5c.java:1699  go5.b(h1aVarK2 /*fill*/, "pen" /*label*/,
                          x82.m(... outline painter ...), kkf.d(i5) /*brush color*/)

swd.a(y31)  → rwd{qwd(size1),qwd(size2),qwd(size3)}
    y31 0=mono→a, 1=taper→b, 2=dash→c, 3=dot→d
rwd.a(uwd)  → qwd{fill,outline}   uwd SMALL/MEDIUM/LARGE → size1/2/3
x5f.c(a6f, w) → uwd：w4g.a[a6f] 宽度预设数组，x90.i0 最近下标 iI0，
    iMax=max(1,len/3)；iI0<iMax→SMALL，iI0<2iMax→MEDIUM，否则 LARGE
```

- `w4g.a` 预设数组（`a6f.I/K/M/R`=pen/…→`[.5,1,1.5,2,3,4,5,7.5,10,15,20,30]`；
  `a6f.J`→`[1,1.5,2,3,4,5,7.5,10]`；`a6f.S`→`[2,4,6,8,12,18,24,30,36,42,48,64]`；
  其余工具为空数组 → 无指示）。
- Harmony `widthWells` 即 `w4g.a` 的等价物（`repository.getWidthWells(toolType)`），
  `brushWidth` 连续值、选择模式用 `selectionWidth`。

## 资源提取

`res/drawable/ui_tools__strokeindicator_<mono|taper|dash|dot>_size<1|2|3>_{fill,outline}.xml`
（24 个）。viewport 全部 `24×6`；dash/dot 为多 `<path>` 子路径，已在
`_gen_strokeind.cjs` 中拼接为单条 pathData。生成 `StrokeIndicators.ets`：

- `mono` = 等粗圆角横条（胶囊）。
- `taper` = 楔形渐细条。
- `dash` = 三段短圆角虚线。
- `dot`  = 三个圆点。
- `size1/2/3` = 由细到粗；`outline` 为略大一圈的外环路径，`fill` 为内填路径。

## Harmony 落点

`EditorToolbar.ets`：`strokeWidthTier()`（x5f.c 移植）、`strokeIndicatorKey()`、
`strokeIndicator()`；宽度按钮 `Shape{ outline环→textPrimary, fill→colorToHex(sel?selectionColor:brushColor) }`，
`viewPort{w:vw,h:vh}` 渲染为 32×8，`.accessibilityText` 保留数值。

## 验证

- Replay `d02-original-stroke-width-indicator.mjs`：28/28。
- `note@default` assembleHap：成功。
- 全量 Desktop Replay 基线：见当日总进展（1237/1237）。
