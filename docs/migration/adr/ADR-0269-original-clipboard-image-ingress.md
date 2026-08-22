# ADR-0269: Original Clipboard Image Ingress

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

Android Notability 用 `ClipboardManager` 的 `hasMimeType("image/*")` 识别系统图片剪贴板，并在 Paste
菜单中把内部元素与 `ClipboardImage` 分流。Harmony 此前的长按 Paste 只覆盖内部元素剪贴板。

## Decision

Harmony 使用系统 Pasteboard 的 PixelMap 作为唯一图片来源；无数据、非 PixelMap 或尺寸非法时 fail closed。
合法输入在释放源 PixelMap 后用 ImagePacker 输出 WebP lossy 85，并沿用照片入口的 100 MiB 字节上限。
产物交给既有单图 durable image persistence/history，插入锚点使用画布长按位置。

长按菜单只在 `StrokeClipboard` 无内容时提供系统图片 Paste；有内部内容时保持原语义优先。权限失败、编码
失败或持久化首张失败统一显示现有“无法添加图片”反馈。

## Consequences

- 不伪造原始 URI、文件名、MIME 或 EXIF 能力；系统剪贴板像素被显式规范化为 WebP。
- 真实权限提示、跨应用兼容性、像素色彩和性能仍需设备矩阵验证。
- `T-042` 不受本阶段影响，继续保留为整个 Goal 最后一项。
