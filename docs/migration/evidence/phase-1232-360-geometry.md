# Phase 1232 证据 — 360 几何/立体数据结构（q0b/r71/p0b/m40/o0b）

来源：`defpackage/{q0b,r71,m40,o0b,p0b,xaf}.java`。

## `q0b` = 360 mesh+立体 UV holder

```java
static float[] i = {1,0,0, 0,-1,0, 0,1,1};      // mono UV
static float[] j = {1,0,0, 0,-0.5,0, 0,0.5,1};  // top-bottom
static float[] k = {0.5,0,0, 0,-1,0, 0,1,1};    // side-by-side
int a; r71 b; xaf c; int d,e,f,g,h;             // GL attrib/uniform 位置
static b(p0b)→立体有效性
```

`i/j/k` = **3×3 UV 变换矩阵** —— mono / top-bottom /
side-by-side 立体格式各自的 UV 缩放偏移（立体 3D
视频常见 3 布局）。

## `p0b` = 立体对 mesh 描述

```java
final o0b a,b;  // 左/右眼 mesh
final int c;    // 立体类型索引
final boolean d = (a==b);  // mono?
```

## `o0b` = `r71[]` 眼 mesh 数组

`o0b(r71... meshes)` —— 每眼一个 mesh 缓冲。

## `r71` = 时间戳→值 有序映射

`r71(8,false)` + `E(ts)`/`G(ts)`/`b(k,v)` —— 排序时间
队列（帧时→旋转/mesh/元数据三队列由 vfc.M/N/L 持有）。

## `m40` = 逐帧旋转 map（mode-3）

`m40(3)` → `K/L=float[16]` 旋转矩阵 + `M=r71` 队列
—— vfc.L 持有的逐帧旋转存储。

## 语义

vfc 用 3 个 `r71` 时间戳队列（M=ts→旋转索引、N=ts→
p0b、L/m40=ts→旋转矢量）+ `q0b` 立体 UV×mesh →
逐帧对齐 360 球面渲染。

## Harmony 决策

r71 排序队列→有序 Map；q0b 3 立体 UV 矩阵保真；
p0b/o0b 眼 mesh → XComponent 顶点缓冲。

## 产出

- fixture `d02-360-geometry.mjs`（10 断言）。
- ADR-1176；中文报告。
