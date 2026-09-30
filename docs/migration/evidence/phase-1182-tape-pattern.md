# Phase 1182 证据 — TapePattern 枚举（ife）+ washi-tape 可绘

来源：`defpackage/{ife,mwd}.java`。

## `ife` = **`TapePattern` 枚举**（Phase-1150 泄名坐实）

```java
enum ife:    // = core.flatbuffers.TapePattern
  STRIPES    // 条纹
  GRID       // 方格
  DOTS       // 圆点
  PLAIN      // 纯色
  STARS      // 星星
  FLOWERS    // 花
  HEARTS     // 心
  WAVES      // 波浪
  CHECKERS   // 棋盘格
```

9 个 washi-tape（纸胶带）装饰图案枚举 + `nz3 T` synthetic
holder + byte 序 —— **坐实 `TapePattern` schema 名**。

## 绑定

`n5d.tapePattern`（shape spec，Phase 1158）→ `ife`；
`mwd` 笔画可绘持 `ife` → 纸胶带笔画按图案填充渲染。

## 判定

纸胶带工具 = `InkStyle` 笔画 + `TapePattern` 图案填充：
- `ka8`/`mwd` 笔画几何（Path）+
- `ife` 图案 → GL/Canvas 图案纹理填充。

## Harmony 决策

`ife`=`TapePattern` 9 值枚举 **直接保留**（schema 对齐）；
图案纹理 → Harmony `ImagePattern`/`PixelMap` 填充。

## 产出

- fixture `d02-tape-pattern.mjs`（10 断言）。
- ADR-1126；中文报告。
