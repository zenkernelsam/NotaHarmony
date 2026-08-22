# 原版系统剪贴板图片入口证据

证据时间：2026-08-23（Asia/Shanghai）
参考根目录：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## Android 原版行为

- `x7j.c(ClipboardManager)` 调用 `getPrimaryClipDescription()` 并要求
  `primaryClipDescription.hasMimeType("image/*")`；描述为空或不含图片 MIME 返回 false。
- `w43` 在编辑器状态分支调用上述判定，并把结果映射为 `e8a.a`，其 Kotlin toString 为
  `"ClipboardImage"`。
- `v49` 的 Paste 菜单逻辑先处理已有选区/内部剪贴板对象；若对象等于 `e8a.a`，则通过反射式方法句柄调用
  `rd9.handleAddImageFromClipboard-raaLB7I(DocPxOffset)`，参数为用户坐标封装 `ei3`。
- `sn6.toString()` 是 UI 状态 `"PasteImage"`，与上述分流共同证明这是专用入口，不是普通元素 Paste。

## Harmony 差距与等价边界

| 原版 | Harmony Phase 291 |
|---|---|
| ClipboardManager 描述含 `image/*` | SystemPasteboard 属性包含 `MIMETYPE_PIXELMAP` |
| `handleAddImageFromClipboard(DocPxOffset)` | 长按锚点进入既有单图 durable photo insert |
| 平台 bitmap 数据 | ImageKit PixelMap |
| 原始剪贴板图像能力 | 先规范化为 WebP lossy 85，不伪造未读取的元数据 |

JADX 方法体混淆/反编译失败导致无法逐行还原 handler 内部缩放细节；本阶段不声称复刻其内部实现，
只接入与原版一致的菜单分流和锚点语义。
