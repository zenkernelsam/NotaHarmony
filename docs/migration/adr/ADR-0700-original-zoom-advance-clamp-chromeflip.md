# ADR-0700：原版 Zoom 前进区宽夹取域修正 + panelInTopHalf chrome 翻转

- 状态：Accepted
- 日期：2026-09-25
- 关联：ADR-0697（前进区宽持久化）、ADR-0698/0699（覆盖层）、
  `phase-752-zoom-advance-clamp-chromeflip.md`

## 背景

Zoom 簇深挖暴露两处对齐缺口：

1. **夹取域错误**：`htd` case 18 `setAdvanceRegionWidth` →
   `rh8.u(f, 48f, 336f)` ——原版夹取域 [48dp, 336dp]；Phase 749
   误用估值 [60, 320]。
2. **漏状态字段**：`ggg.f = panelInTopHalf`（第 6 字段）——由
   布局位置流派生（`zt8`/`egg`），驱动 `ahg.S = isShown &&
   panelInTopHalf` → `u49` 的 `"chromeFlip"`/`"toolboxFlip"`
   scaleY ±1 动画：面板在上半区时控制条镀铬垂直镜像。

## 决定

1. `NoteZoomView` 拖拽夹取域更正为 `ZOOM_ADVANCE_WIDTH_MIN_VP=48` /
   `MAX_VP=336`（dp→vp 等价）；写路径夹取、读路径不夹取（原版同）。
2. `panelInTopHalf` ≡ `!dockBottom`（Harmony 停靠离散化为
   Top/Bottom，顶部停靠即上半区）；控制条 Row 施加
   `.scale({x:1, y:-1})` 于顶部停靠时——"chromeFlip" 即时近似。

## 近似登记

- 原版 panel 可悬浮中间态（连续 y 位置流），Harmony 只支持停靠——
  `!dockBottom` 覆盖全部可达态。
- 翻转无 spring 过渡动画；仅控制条翻转（书写画布不镜像）。
- `svf(20/21)` 手势面派生流已由既有 `toolChangedAt` 门控覆盖。

## 后果

- 前进区宽可拖到原版真实的 [48,336] 域；旧估值被覆盖处现可及。
- 顶部停靠时控制条图标方向与原版一致镜像。
- 无新依赖；专项 Replay pins 更新。

## 后续纠正（ADR-0702 / Phase 754）

`panelInTopHalf` 翻转机制经 `fgg.b` 复核证伪：原版是控制条/画布卡
**Column 序交换**（条恒贴面板内沿），非图标 scaleY 镜像；镜像会倒置
字形。同时画布卡高按 `njj.d` 的 272dp 修正（原 160vp 无依据）。
本 ADR 的 [48,336] 夹取域结论不变。
