# ADR-0573 — 裁剪会话期间图片未裁剪全图渲染（itc.c / showUncropped）

- 状态：Accepted
- Phase 604；对齐 `itc`/`dhb`/`l0f`/`m2f`（decompiled_1.0.3）。

## 背景

原版 `itc`（Tap 单元素选区）第三字段 `showUncroppedImage` 由
CROP 菜单动作置位（`dhb` case14 → `fvb.e(true)`），裁剪收尾复位。
`TileSubmission.r`/`TiledRendererUpdate.j` 把该标记交给瓦片渲染器：
**裁剪会话期间选中的图片块渲染整张已定向原图**，忽略 cropRect
像素裁剪与块矩形 clip，使草稿矩形可以拖入已裁掉的域。

Harmony 缺口：`imageCropVisible` 期间图片仍按 `cropRect` 渲染并
clip 到 `blockWidth×blockHeight`——draft 矩形可拖出当前裁剪域
（`session.domain` 本来就允许超出），但域外像素不可见，手柄
悬空在空白上，与原版"看着全图拖裁剪框"的体验不符。

## 决策

1. `ImageCanvasRenderer.renderImage` 增加可选尾参
   `uncroppedSourceCrop: Rect2D | null = null`：
   - `null`：原有路径（块矩形 clip + crop 像素平移）；
   - 非 `null`：不 clip，平移 `(-source.left, -source.top)`、按
     `intrinsic/oriented` 缩放画全图——intrinsic 单位与本地块
     坐标系共享（`beginOriginalImageCrop` 强制 cropW≈blockWidth），
     因此全图恰好铺满 `session.domain`。
   - 两路径共用 EXIF 方向与用户翻转顺序（像素空间内先应用）。
2. `NoteCanvasView` 渲染循环仅当 `imageCropVisible` 且
   `element.data.id === imageCropSession.original.id` 时传
   `session.sourceCrop`；其余图片/非裁剪态不变。
3. 尾参为可选参数，`d02-image-thumbnail` 等既有调用点签名兼容。

## 偏差

- 原版经 `showUncropped` 标记走瓦片渲染层；Harmony 无瓦片层，
  直接在元素渲染分支切换——语义等价（同一标记→同一渲染差异）。
- 原版裁剪 UI 是否附带域外暗化未从 decompiled 取证；Harmony 的
  `ImageCropOverlay` 本无暗化层，本次不新增（仅对齐"可见全图"）。

## 验证

- `docs/migration/replays/d02-original-image-uncropped-render.mjs`：
  12 断言（uncropped 分支几何、门控 id 匹配、调用点尾参、
  domain/crop 单位共享前提）。
- 全量 Desktop Replay 494/494 全绿；`note@default`/`note@ohosTest`
  构建通过。
