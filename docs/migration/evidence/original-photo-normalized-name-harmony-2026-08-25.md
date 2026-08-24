# Phase 408 Harmony 证据：原版照片归一化文件名

## 原版证据

- `decompiled_1.0.3/sources/defpackage/bgj.java:206`：`File.createTempFile("temp_", null, context.getCacheDir())`。
- 同函数随后执行 `String name = fileCreateTempFile.getName();` 并构造 metadata fileName。
- `decompiled_1.0.3/sources/defpackage/vuh.java:137` 与压缩调用证明规范化输出为 `"image/webp"`。

## Harmony 变更

- `OriginalImageNormalizer.ets` 的 `NormalizedOriginalImageBytes` 新增 `rewroteBytes`，区分原始字节与 WebP 重写快照。
- `OriginalPhotoIngress.ets` 在重写时返回 `photo-N`，在未规范化时保留 `photo-N.<source-extension>`；`OriginalPhotoIngressItem` 同步透出重写状态。
- `NoteCanvasView.ets` 剪贴板路径构造的 WebP 快照标记 `rewroteBytes: true`。

## 本地实测

- ArkTS 检查：三个核心变更文件无错误；仅保留项目既有 warning/deprecation 信息。
- 新增专项 Replay：`D02_ORIGINAL_PHOTO_NORMALIZED_NAME_OK TOTAL=5 FAILED=0`。
- 既有照片 Ingress Replay：`D02_ORIGINAL_PHOTO_INGRESS_OK TOTAL=10 FAILED=0`。
- 全量 Desktop Replay：`REPLAY_FILES=365 PASSED=365 FAILED_FILES=0`。
- clean：`BUILD SUCCESSFUL in 1 s 982 ms`（2.946 秒）。
- ohosTest HAP：`BUILD SUCCESSFUL in 27 s 766 ms`（29.590 秒）。
- default HAP：`BUILD SUCCESSFUL in 42 s 855 ms`（44.324 秒）。

## 边界

没有启动模拟器、虚拟机、真机或 Hypium；静态 HAP 构建不替代运行态验收。WebP 编码器设备差异继续由既有 fail-closed 边界保护。
