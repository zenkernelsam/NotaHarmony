# 证据：Canvas2DStrokeRenderer c5g 面复核（Phase 632）

- 日期：2026-09-28；Phase 632（审计收口）
- 原版来源：`decompiled_1.0.3/sources/defpackage/c5g.java`、
  `zx1.java`、`l96.java`、`pzf.java`
- Harmony 实现：`note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets`

## 背景

`审计缺口清单.md` 一.1 把本文件列为 462 行完全未审的最大缺口，
附两条线索（引自 `T-040-AUDIT-完成.md` 待办）：

> dash 参数（2w/1w、0.001w/2w）未对照 1.0.3 pzf 对应物；
> highlighter 用 alpha 0.42 简化（原版 BlendMode）

## 复核结论：两条线索均已 parity，基准引用错误

### 1. dash 参数（`c5g.g`，非 pzf）

`pzf` 实为 AutoCloseable 资源池（pzf.java:7-20），与笔画渲染
无关。真源是 `c5g.g`（c5g.java:213-240）：

- DASH → `this.i`（BUTT cap + ROUND join）+
  `DashPathEffect({2.0f*f, 1.0f*f}, 0.0f)`（:217/:223）
- DOTS → `this.j`（ROUND cap + MITER join）+
  `DashPathEffect({0.001f*f, 2.0f*f}, 0.0f)`（:231/:237）
- 实线 → `this.h`（ROUND cap + ROUND join，:243/:48）

Harmony `renderCenterPath`（Canvas2DStrokeRenderer.ets:570-582）：
DASH→`butt`+`[2w,1w]`、DOTS→`round`+`miter`+`[0.001w,2w]`、
其余 `round`/`round`——逐条一致，相位恒 0（Phase 574 已证，
`d02-original-dash-phase-zero` 回归）。

### 2. highlighter 透明度

原版**并非** BlendMode.MULTIPLY：`c5g` 构造器内全部六支画笔
`BlendMode.SRC_OVER`（c5g.java:33-65）；荧光笔经
`zx1.e(color, 107)`（c5g.java:250）做 **alpha 覆盖**
（zx1.java:38-44：`(i & 0xFFFFFF) | (107 << 24)`，107/255=0.42）。
Harmony `isHighlighter ? 107 : undefined`（:545/:578/:611）
逐位一致。

### 3. 填充排除

`l96.l0`（l96.java:5482-5495）：`clipOutPath(path2)` +
`drawPath(path, paint)` + `drawPath(path2, paint3)`——主轮廓
镂空后填充内部。Harmony `renderInkFill`（:497-510）用大矩形 +
轮廓 `clip('evenodd')` 达成同构镂空，再 fill——等价。

## 附带修正

`renderCenterPath` 两处注释误引 `pzf.g` 已更正为 `c5g.g`。

## 残余面

splat 纹理、tape 瓦片、renderCustomPath 边界分支未逐行走查，
但均有专项 fixture 间接覆盖；缺口清单一.1 已降级为
"主干覆盖"，完全未审文件数 12→11。
