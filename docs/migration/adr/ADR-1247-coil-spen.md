# ADR-1247：Coil3 + Samsung S-Pen SDK

## 状态

已接受（Phase 1303）。

## 决策

- Coil3 → Harmony `Image`/multimedia.image+网络缓存。
- S-Pen SDK → Harmony `pen`/压感 Touch API；S-Pen 设置
  UI → fail-closed/自实现。

## 理由

Coil3（GIF/SVG 解码+OkHttp 网络图）+ Samsung S-Pen SDK
（setting/colorpicker/quicktool/handwriting + `Spen
Configuration`）—— 图片加载库+三星触控笔集成。

## 后果

Harmony 图片 = multimedia.image+缓存；触控笔 = pen API
（S-Pen 专属 UI 降级）—— 集成语义保真+平台降级。
