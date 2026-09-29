# Phase 1056 证据 — 值类型清单（几何/颜色/纸张/时间戳）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 几何 struct（xwd 固定布局）

| 类 | 字段（toString 实名） | 槽位 |
|---|---|---|
| `fqa` | **Point{x,y}** | c()=x, d()=y |
| `qed` | **Size{width,height}** | **d()=width, c()=height（访问器序与名相反）** |
| `bmb` | **Rect{origin:fqa, size:qed}** | c()/d() |
| `vy7` | **Margins{top,bottom,left,right}** float×4 | f()@?, e()@+12 |

`vy7.a()`：任一负值→"Margins cannot be negative"。

## 颜色

- `hu1` = **Color{bitsR,bitsG,bitsB,bitsA}**——4 byte 通道
  （f()=R, e()=G, d()=B, c()=A），`cmf.a` byte 格式化。
- `k3a` Paper：backgroundColor **必须 alpha==1**
  （"Paper background colors must be alpha == 1"）。

## `k3a` Paper（cee 表，非 struct）

`{flair, flairSpacing, flairBleeds, flairCentered,
backgroundColor:hu1, legacyPaperIndex}`——纸张纹理参数+
旧索引兼容字段。

## `tmf` = Comparable long 包装

`{long I}` + `njj.j0(10,I)` toString——用作
serverTime/audioTime/zIndex 的统一序数包装。

## Harmony 决策

- Point/Size/Rect/Margins/Color struct 布局保留；
  qed 访问器序注意（width=d, height=c）。
- Paper alpha==1 校验+legacyPaperIndex 兼容字段保留。

## 产出

- fixture `d02-value-types.mjs`（12 断言）。
- ADR-1000；中文报告。
