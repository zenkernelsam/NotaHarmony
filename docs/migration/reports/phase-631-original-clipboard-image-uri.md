# Phase 631 报告：系统剪贴板 URI 图像载体对齐

- 日期：2026-09-28
- 证据：`docs/migration/evidence/original-clipboard-image-uri-2026-09-28.md`
- ADR：`docs/migration/adr/ADR-0600-original-clipboard-image-uri.md`

## 原版事实

原版粘贴可用性门 `x7j.c` 用
`ClipDescription.hasMimeType("image/*")` 判定——凡声明 image/*
的剪贴板内容均可粘贴为图像，包括 URI 载体记录（content:///
file:// 图像文件）。粘贴经 `v49.handleAddImageFromClipboard`
在锚点落图。

## 缺口

Harmony 探针与读取只认 `MIMETYPE_PIXELMAP`；Harmony 侧"复制
图像文件"通常产出 `text/uri` 记录，原版可粘贴而 Harmony 连
Paste 菜单项都不显示——可用性缺口而非运行期失败。

## 实现

`OriginalClipboardImageIngress.ets`：

- 探针加 `MIMETYPE_TEXT_URI` 分支：`hasData` 后 `getData`
  遍历记录，首个 `isValidOriginalPhotoUri` 命中的
  `record.uri` → 可用。
- `OriginalClipboardImageSource` 增可选 `uri`；
  `readWithHarmonyPasteboard` 无 pixelMap 时取 URI 载体。
- `normalizeClipboardImageUri`：`fileIo` 只读打开，
  `stat.size` 按 `CLIPBOARD_IMAGE_MAX_BYTES=104857600` 校验
  并 1MB 分块读；`normalizeOriginalImageBytes` 复用照片入口
  归一化（EXIF 方向、3000px 降采样、webp q85 回写）。
- 结果扩展 `mimeType/rewroteBytes/fileExtension/encodedWidth/
  encodedHeight`；`NoteCanvasView.startOriginalClipboardImagePaste`
  按字段组装插入项：未回写保留源 mime+扩展名，回写为 webp。
- 失败链：无数据/无合规记录/超限/解码失败/非法尺寸 → 抛错走
  既有本地化 toast；fileIo 句柄与 pixelMap 资源 finally 释放。

## 差异

- Harmony text/uri 记录无图像声明，以扩展名白名单预筛：无
  扩展名 URI 不可见（收窄）；非图像 URI 不触发 Paste（更严）。

## 验证

- d05 fixture：46/46 全绿（新增探针/读取双载体断言）。
- d02-original-clipboard-image-ingress：32/32 全绿。
- note@default 构建绿；ohosTest 与全量回放见本节验收记录。
