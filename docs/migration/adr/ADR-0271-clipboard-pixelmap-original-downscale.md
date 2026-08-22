# ADR-0271: Clipboard PixelMap Original Downscale

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

原版大图规范化在 oriented 任一轴超过 3000px 时按最大轴 Float32 比例缩放并重编码。Phase 291 的系统
剪贴板 PixelMap 入口此前允许 12000px，只做 WebP 重编码，绕过了同一契约。

## Decision

Harmony ImageKit 提供 `PixelMap.createScaledPixelMap()`（SDK 声明 since 18，带 anti-aliasing），可作为
已解码 PixelMap 的等价缩放 adapter。剪贴板入口现在复用 `planOriginalImageDownscale()` 的精确目标尺寸，
超过 3000px 时创建 scaled PixelMap，校验实际尺寸后输出 WebP lossy 85；scaled PixelMap 由本函数拥有并
在 finally 中释放，原始 clipboard PixelMap 继续由 reader owner 释放。

12000px 的本地 ingress 上限移除；合法输入以原版 3000px 规范化结果为准，异常仍 fail closed。
100 MiB 编码字节上限保留为资源保护门。

## Consequences

- 照片 URI 与系统剪贴板两条入口共享同一条原版尺寸规范化语义；
- 不再持久化超大 clipboard bitmap；
- SDK 缩放质量、WebP 支持和大图峰值内存仍需真实设备验收。
