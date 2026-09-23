# ADR-0600 原版剪贴板图像 URI 载体对齐

- 状态：accepted；Phase 631；2026-09-28
- 上下文：原版 `x7j.c` 的粘贴门为
  `ClipDescription.hasMimeType("image/*")`——URI 载体图像同样
  可用；Harmony 此前只探 `MIMETYPE_PIXELMAP`，URI 记录复制的
  图像在画布粘贴菜单不可见（
  `docs/migration/evidence/original-clipboard-image-uri-2026-09-28.md`）。

## 决策

`OriginalClipboardImageIngress.ets`：

- 可用性探针：`MIMETYPE_PIXELMAP` 命中照旧；否则
  `MIMETYPE_TEXT_URI` + `hasData` → 遍历记录取
  `isValidOriginalPhotoUri` 命中的 URI → true。
- 读取侧同序：pixelMap 优先；否则取首个合规 URI。
- URI 路径：`fileIo` 只读打开 + `stat.size` 校验
  `CLIPBOARD_IMAGE_MAX_BYTES=104857600` 分块读 →
  `normalizeOriginalImageBytes`（EXIF 方向/3000px 降采样/
  webp 回写，与照片入口同一归一化器）。
- `NormalizedOriginalClipboardImage` 增 `mimeType /
  rewroteBytes / fileExtension / encodedWidth / encodedHeight`；
  粘贴调用点按这些字段组装 `OriginalPhotoIngressItem`——
  未回写时保留源 mime 与扩展名，回写时 webp。
- fail-closed：无数据/无合规记录/超限/解码失败/尺寸非法均
  抛错，调用点走既有 toast。

## 后果

- 系统剪贴板复制的图像文件（file:// URI 记录）可经画布
  Paste 菜单插入，与原版 image/* 门口径一致。
- 归一化、尺寸上限、方向修正与照片入口共享同一管线。
- 未回写 URI 图像以原 mime/扩展名入资产库，不再一律 webp。
- 无扩展名 URI 仍不可见（比原版 image/* 收窄）；非图像 URI
  不触发粘贴项（更严）。

## 验证

d05 fixture 46/46、d02 fixture 32/32、全量回放套件、
note@default 与 note@ohosTest 双 HAP 构建全绿。
