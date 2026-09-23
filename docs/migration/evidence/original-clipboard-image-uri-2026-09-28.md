# 证据：原版系统剪贴板图像门的 URI 载体（x7j.c）

- 日期：2026-09-28；Phase 631
- 原版来源：`decompiled_1.0.3/sources/defpackage/x7j.java`、
  `w43.java`、`v49.java`、`e8a.java`、`d8a`（粘贴分发）
- Harmony 实现：`note/src/main/ets/data/OriginalClipboardImageIngress.ets`、
  `note/src/main/ets/ui/editor/NoteCanvasView.ets`

## 原版语义

- `x7j.c(ClipboardManager)`（x7j.java:200-203）：
  `getPrimaryClipDescription().hasMimeType("image/*")` ——
  粘贴可用性门按 **ClipDescription 声明的 image/* MIME** 判定，
  不区分载体：位图记录与 content:// URI 记录（声明 image/png
  等）同样通过。`w43` case28 用它把 `e8a.a`（ClipboardImage）
  态注入粘贴菜单；`v49` 点击后经 `handleAddImageFromClipboard`
  落点插入。

## Harmony 原实现与缺口

`probeWithHarmonyPasteboardMimeTypes` 只认
`pasteboard.MIMETYPE_PIXELMAP`；`readWithHarmonyPasteboard` 同样
要求 pixelMap 记录。Harmony 系统剪贴板里"复制文件/图片"常产出
`text/uri` 记录（file:// URI），而非 pixelMap——原版会显示
Paste 并解码，Harmony 探针返回 false，菜单不显示 Paste，
等价于功能缺失。

## 对齐实现

- `probeWithHarmonyPasteboardMimeTypes`：pixelMap 命中照旧；
  否则若 mimeTypes 含 `MIMETYPE_TEXT_URI` 且 `hasData()`，
  `getData()` 遍历记录，任一 `record.uri` 通过
  `isValidOriginalPhotoUri`（支持扩展名白名单）→ true；
  异常 fail-closed → false。
- `readWithHarmonyPasteboard`：pixelMap 分支不变；无 pixelMap
  且含 text/uri → `firstSupportedClipboardImageUri` 取首个
  合规 URI → `{pixelMap: null, uri, release}`。
- `importOriginalClipboardImage`：pixelMap →
  `normalizeOriginalPixelMap`；uri → `readClipboardImageUri`
  （fileIo openSync + 104857600 上限分块读）→
  `normalizeOriginalImageBytes`（EXIF 方向 + 3000px 降采样 +
  webp 回写）→ 归一化结果。
- `NormalizedOriginalClipboardImage` 扩展 `mimeType /
  rewroteBytes / fileExtension / encodedWidth / encodedHeight`；
  `startOriginalClipboardImagePaste` 改用这些字段组装
  `OriginalPhotoIngressItem`（URI 分支保留源 mime/扩展名）。

## 差异与边界

- Android ClipDescription 携带 image/* 声明；Harmony text/uri
  记录无图像声明——以扩展名白名单预筛，无扩展名 URI（如
  datashare 短链）不可见，属已知收窄（解码兜底仍由
  normalizeOriginalImageBytes 保证安全）。
- 链接等非图像 URI 不触发 Paste 可用性——比原版宽口径
  image/* 更严，避免对非图像 URI 显示粘贴项。

## 回放

`d05-original-image-drop-ingress.mjs` 增补断言 46/46 全绿；
`d02-original-clipboard-image-ingress.mjs` 32/32 全绿。
