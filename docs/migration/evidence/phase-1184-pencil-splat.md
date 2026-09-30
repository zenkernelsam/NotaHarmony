# Phase 1184 证据 — 铅笔 splat 点阵模型（mea/lea/owd）

来源：`defpackage/{mea,lea,owd,a}.java`。

## `owd` = PencilStrokeContent = splat 笔画

`{mea, splats: List<mea>}` —— 铅笔笔画渲染为**点精灵
（splat）列表** —— pointillist 纹理 stamp，非路径填充。

## `mea` = 单个 splat stamp 实例

```java
mea:
  static float k = sqrt(2)          // 对角/AA 常量
  lea a                             // 图集/纹理句柄
  int b                             // 颜色
  int d,e; float f,g,h,i            // 位置/旋转/尺寸（可变）
  static f(int color, float f):     // RGB 通道乘 f
    rh8.v 每通道钳位→打包 int
```

## `lea extends a` = splat 图集/纹理

`a` = 抽象基 `{static byte[] a}` —— **烘焙进 byte 数组的
splat 图集纹理**（铅笔颗粒纹理编译进二进制）。

## 判定

**铅笔渲染 = 纹理 splat 点阵**：每触点生成 `mea` splat
（位置/旋转/尺寸/颜色乘深）→ `lea` 共享颗粒图集 →
GL 点精灵 stamp —— 压感=尺寸/深乘，非路径。

## Harmony 决策

- splat stamp → Harmony 点精灵/纹理 stamp
  （`drawing`/GL sprite）。
- `lea` byte 图集 → Harmony 资源 `rawfile`/`PixelMap`。
- `f(color,f)` 通道乘 → Harmony 颜色调制。

## 产出

- fixture `d02-pencil-splat.mjs`（10 断言）。
- ADR-1128；中文报告。
