# Phase 604 — 裁剪会话期间图片未裁剪全图渲染（itc.c / showUncropped）

- 日期：2026-09-23
- 结果：已实现对齐
- 证据：`docs/migration/evidence/original-image-uncropped-render-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0573-original-image-uncropped-render.md`
- Replay：`d02-original-image-uncropped-render.mjs`（12 项断言）

## 背景

原版 `itc`（Tap 单元素选区）第三字段 `showUncroppedImage`：
CROP 菜单动作（`dhb` case14 → `fvb.e(true)`）置位，裁剪收尾复位。
`TileSubmission.r` / `TiledRendererUpdate.j` 将该标记送入渲染层——
**裁剪会话期间选中的图片块渲染整张已定向原图**，草稿矩形可拖入
已裁掉的域（`session.domain` 允许超出当前块）。

Harmony 缺口：`imageCropVisible` 期间图片仍按 `cropRect` 裁剪渲染
并 clip 到 `blockWidth×blockHeight`，draft 拖出当前裁剪域时手柄
悬空在空白上，用户看不到可裁入的像素。

## 实现

- `ImageCanvasRenderer.renderImage` 增加可选尾参
  `uncroppedSourceCrop`：
  - `null` → 原路径（块矩形 clip + crop 像素平移）；
  - 非 `null` → 不 clip，`translate(-source.left, -source.top)` 后按
    `intrinsic/oriented` 缩放绘制全图（intrinsic 单位 = 本地块坐标
    系，`beginOriginalImageCrop` 已强制 cropW≈blockWidth）；全图
    恰好铺满 `session.domain`。EXIF 方向与用户翻转顺序两路径共用。
- `NoteCanvasView` 渲染循环：`imageCropVisible` 且
  `element.data.id === imageCropSession.original.id` 时传
  `session.sourceCrop`；其余图片与非裁剪态不变。

## 验证

- Replay `d02-original-image-uncropped-render.mjs`：12/12。
- 全量 Desktop Replay 全绿（含本 Phase 新 fixture）。
- `note@default` / `note@ohosTest` HAP 构建通过。

## 遗留

- 原版裁剪 UI 是否附带域外暗化层未取证；Harmony `ImageCropOverlay`
  无暗化层，本 Phase 仅对齐"全图可见"语义，不新增暗化。
