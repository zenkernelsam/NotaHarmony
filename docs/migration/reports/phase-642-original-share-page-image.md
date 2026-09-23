# Phase 642 — 分享面板 JPG/PNG 行点亮（当前页整页栅格化导出）

- 日期：2026-09-23
- 证据：`docs/migration/evidence/original-share-page-image-export-jadx-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0609-original-share-page-image.md`
- Replay：`docs/migration/replays/d05-original-share-page-image.mjs`（25 断言）

## 原版行为

- 分享面板 `s6d` 枚举含 JPG/PNG（`atc` case6/7 渲染对应图标）；
- `v6d` 面板状态携带页选择集合（`Set l` + `int m`），`b7d` 按
  `l.size() != m` 判定部分页导出——原版支持页范围子集；
- `y59.b` 按格式导出执行体在 JADX 层未反编译；安卓侧经 `v6d.t`
  系统分享 Intent 分发。

## Harmony 缺口（修复前）

Phase 641 的分享面板中 JPG/PNG 行置灰——当时按"需页级栅格化器"
登记。复核发现 `ThumbnailRenderer` 已具备完整元素栈渲染且分辨率
参数化，栅格化器事实存在，只需换输出几何。

## 本 Phase 变更

### `rendering/ThumbnailRenderer.ets`

- 抽出 `renderPageCore`（elements 加载、PDF/纸面背景、全元素栈
  渲染、PixelMap 组装的共享体），`renderThumbnail` 委托之；
- 新增 `renderPageExport(..., scale)`：输出 = `pagePixelSize × scale`
  整页、`offset {0,0}` 无边距；独立栅格预算
  `EXPORT_MAX_SIDE=4096`/`EXPORT_MAX_PIXELS=16M`，fail-closed 拒绝
  超预算请求；页缓存 2048/2M 预算不动。

### `data/PageImageExporter.ets`（新）

- `exportPageImage(context, pixelMap, title, format)`：
  `ImagePacker.packToData`（png / jpeg q92，64MB 缓冲）→ 沙箱临时
  文件 → `DocumentViewPicker.save`（`.png`/`.jpg`）→ 分块复制 →
  临时文件清理；取消/失败返回 false。

### `ui/editor/EditorToolbar.ets`

- `ShareFormatRow` 增 `format` 参数；JPG/PNG 行点亮；
- 行点击分发：`note` → `onShareNote()`，`jpg`/`png` →
  `onShareImage(format)`；新增 `onShareImage` 回调。

### `ui/editor/NotePage.ets`

- `PAGE_EXPORT_SCALE = 2.0`（≈192dpi）；
- `onShareImage` 走既有门禁 → `shareCurrentPageAsImage`：当前可见页
  亮主题栅格化（导出恒取笔记固有颜色，不受夜间模式影响）→
  `PageImageExporter.exportPageImage` → `export_done`/`export_failed`
  toast；`pixelMap.release()`/`renderer.dispose()` finally 兜底。

## Fail-closed 登记（ADR-0609）

- 页选择集合 + 多文件分发 → 仅当前页单文件（后续 Phase）；
- 安卓系统分享 Intent → DocumentViewPicker 保存（平台对等物）；
- 原版栅格分辨率不可考 → 2× pagePixelSize ≈192dpi。

## 验证

- 专项 `d05-original-share-page-image.mjs`：25 断言绿；
- `d05-original-editor-share.mjs` 更新行点亮状态：41 断言绿；
- 全量 Desktop Replay：527/527 全绿；
- `note@default`/`note@ohosTest` 双 HAP clean 构建成功。

## 提交

见 git log `Phase 642` 提交。
