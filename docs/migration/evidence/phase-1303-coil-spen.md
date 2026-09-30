# Phase 1303 证据 — Coil3 图片加载 + Samsung S-Pen SDK

来源：`coil3/` + `com/samsung/android/sdk/pen/`。

## Coil3 图片加载（`coil3/`）

```
coil3/gif/         — GIF 解码器
coil3/svg/         — SVG 解码器
coil3/network/okhttp/ — OkHttp 网络 fetcher
```

→ **Coil 3** Kotlin 多平台图片加载 —— GIF/SVG 解码 +
OkHttp 网络图加载（笔记图片/缩略图/贴纸）。

## Samsung S-Pen SDK（`com/samsung/android/sdk/pen/`，
70 文件）

```
setting/color/ + colorpalette/ + colorpicker/ — 笔色/调色板
setting/quicktool/                            — 快捷工具
setting/handwriting/                          — 手写设置
setting/common/ + util/
view/SpenConfiguration                        — S-Pen 配置
```

→ **Samsung S-Pen SDK** —— 手写笔设置 UI（色板/快捷
工具/手写）+ S-Pen 配置（三星触控笔集成）。

## 语义

- Coil3 = 图片/GIF/SVG 加载+网络缓存 —— 笔记媒体。
- S-Pen SDK = 三星触控笔特性 —— 笔工具设置/配置。

## Harmony 决策

- Coil3 → Harmony `Image`/`ImageKnife`/`@ohos.multimedia
  .image`+网络缓存（GIF/SVG 支持）。
- S-Pen SDK → **Harmony 手写笔** `pen`/`Touch` 压感 API
  （S-Pen 设置 UI 不可移植 → fail-closed 或自实现）。

## 产出

- fixture `d02-coil-spen.mjs`（10 断言）。
- ADR-1247；中文报告。
