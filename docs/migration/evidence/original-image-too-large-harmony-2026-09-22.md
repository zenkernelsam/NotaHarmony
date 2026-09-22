# 原版超限图片提示 → HarmonyOS 移植证据（2026-09-22）

## 原版证据

- `decompiled_1.0.3/sources/defpackage/u49.java`：收集 `rd9` 事件流，向 snackbar
  发送 `feature_note__image_too_large_to_add`（"Image is too large to add."）。
- `strings.xml`：`image_too_large_to_add` = "Image is too large to add."

## Harmony 移植

- `OriginalPhotoIngress.ets`：新增 `OriginalPhotoTooLargeError extends Error`，
  两处超限闸口（`stat.size > maxBytes` 预检与读取后 `isOversizedOriginalPhoto`
  校验）统一抛出。
- `NoteCanvasView.photoErrorToastRes(e)`：`instanceof` 映射到
  `image_too_large_to_add`，其余错误保持 `original_photo_insert_failed`；
  相册导入、剪贴板图片、拍照三个 catch 面统一接入。
- 与原版一致：超限图片有专属文案而非通用失败提示。
- 差异登记：原版按解码像素维度判定超限；Harmony 按 100MB 字节闸口判定
  （`ORIGINAL_PHOTO_MAX_BYTES`），触发面更宽，属平台适配。

## 验证

- 回放 `docs/migration/replays/d02-original-image-too-large.mjs`：原版事件/
  字符串锚点 + Harmony 类型化抛出、三处 catch 映射、双语资源，全过。
- `note@default`、`note@ohosTest` 双构建通过。
