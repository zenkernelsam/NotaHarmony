# Phase 1180 证据 — 瓦片渲染模型（h0f=ContentInputs + pwd/mwd）

来源：`defpackage/{h0f,pwd,mwd,t0g}.java`。

## `h0f` = **`ContentInputs`**（toString 实名）— 渲染输入模型

```java
toString: "ContentInputs(noteGeneration="
  noteGeneration      // long — 笔记版本（脏检测）
  zoom                // float — 缩放
  tileWidth, tileHeight  // int — **瓦片尺寸**
  useBezier           // bool — **贝塞尔笔画 tessellation**
  showTileBorder      // bool — 调试瓦片边框
  idsToErase          // Set — 待擦除
  selectionState      // ktc — 选择态
  idsToExclude        // Set
  pdfTextSelectionState  // pda — PDF 文本选择
  … List×2, Long, Set, Map
```

**笔记画布 = 瓦片渲染**：tileWidth/Height 分块 +
`useBezier` 笔画平滑 + `noteGeneration` 脏版本比对 +
`showTileBorder` 调试。

## `pwd`/`mwd`/`t0g` = 渲染笔画/形

```java
abstract pwd: Path a, static Path b(scratch),
  BlendMode, float[];  abstract Float a()
mwd extends pwd: {Path×3, float, int, BlendMode,
  bool, float[], Float×2, ife, Path}   // 笔画可绘
t0g: {float,float,a76×2,bool,r93,…}    // 另一可绘
```

## 判定

**瓦片渲染管线**：`ContentInputs`（版本/缩放/瓦片/
贝塞尔/选择态）→ `pwd`/`mwd` 可绘 → `bpd`
SceneRenderer 分瓦片绘帧 —— 脏区剔除 + Bezier
笔画 tessellation + 选择/擦除/PDF 文本状态。

## Harmony 决策

- 瓦片渲染 → Harmony XComponent/Drawing 瓦片策略
  （脏区剔除保留）。
- `useBezier` → Harmony 笔画贝塞尔 tessellation。
- `ContentInputs` 字段语义 → Harmony 渲染输入 struct。

## 产出

- fixture `d02-tile-render.mjs`（10 断言）。
- ADR-1124；中文报告。
