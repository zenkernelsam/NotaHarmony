# Phase 1183 证据 — 笔画内容三分类 + ViewportState（实名泄漏）

来源：`defpackage/{mwd,nwd,owd,t0g,pwd}.java` —— toString
泄真名。

## `pwd` 抽象可绘基 `{Path a, Path b(scratch), BlendMode,
float[]}` + `abstract a()→Float`

## 3 笔画内容子型（`extends pwd`）

| 类 | 实名 | 渲染策略 |
|----|------|---------|
| `mwd` | **BezierStrokeContent** | 贝塞尔 tessellation 笔画（`ife` TapePattern + `t16` InkStyle + Path + List） |
| `nwd` | **CentralPathStrokeContent** | 中线路径笔画（Path×3 + List + Float×2 + ife + t16） |
| `owd` | **PencilStrokeContent** | 铅笔点阵笔画（`mea` + **splats** 点精灵） |

三种笔画渲染策略：贝塞尔轮廓 / 中线路径 / 铅笔 splat
（点阵纹理 stamp）。

## `t0g` = **`ViewportState`**（toString 实名）

```java
ViewportState(
  zoom                      // float
  pageWidthRelativeZoom     // float — 页宽归一缩放
  functionalViewportRect    // 功能视口
  visibleViewportRect       // 可视视口
  areTransformsTransient    // bool — 变换是否暂态
  density                   // float — dpi
  … 16+ 字段 (a76×2, r93, pce×3 惰性)
)
```

视口/相机态：双 zoom + 功能/可视视口 + 暂态变换 + dpi。

## 判定

渲染场图（scene-graph）= `ContentInputs`（输入，Phase
1180）+ `ViewportState`（相机）+ `pwd` 可绘 3 子型
（Bezier/CentralPath/Pencil-splat 笔画）→ `bpd`
SceneRenderer GL 帧。

**实名校准**：`h0f`=ContentInputs、`t0g`=ViewportState、
`mwd`=BezierStrokeContent、`nwd`=CentralPathStrokeContent、
`owd`=PencilStrokeContent、`bpd`=SceneRenderer（Phase
1177）、`ife`=TapePattern（1182）、`t16`=InkStyle（1176）。

## Harmony 决策

3 笔画渲染策略保留：贝塞尔/中线/splat 三种 tessellation
→ Harmony `drawing.Path`/点精灵；`ViewportState` 相机
字段语义保留。

## 产出

- fixture `d02-stroke-content.mjs`（10 断言）。
- ADR-1127；中文报告。
