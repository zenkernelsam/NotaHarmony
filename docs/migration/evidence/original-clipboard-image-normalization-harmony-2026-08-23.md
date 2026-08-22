# 系统剪贴板 PixelMap 大图规范化证据

证据时间：2026-08-23（Asia/Shanghai）
范围：正式仓 Phase 281/291 当前源码与本地 HarmonyOS SDK 声明。

## 已闭环契约

`OriginalImageInsertPlan.planOriginalImageDownscale()` 复刻 Android `vuh.b()`：

- 3000px 以内不改尺寸；
- 超限时按 `3000 / max(width, height)` 计算 Java-float 目标；
- 目标轴 half-up round 且最小为 1；
- sample size 按 power-of-two 循环选择；
- Phase 281 Replay 已覆盖 `9000x12000 -> 2250x3000` 等数值。

## Phase 291 差距

`OriginalClipboardImageIngress` 此前定义 `CLIPBOARD_IMAGE_MAX_SIDE=12000`，对 PixelMap 直接 WebP lossy 85
重编码，返回原始宽高。该路径会持久化最多 12000px 的 intrinsic image，违反照片 URI 路径已经执行的原版
3000px 规范化链。

## SDK 能力

本地 DevEco SDK `@ohos.multimedia.image.d.ts` 声明：

```text
createScaledPixelMap(x: number, y: number, level?: AntiAliasingLevel): Promise<PixelMap>;
@since 18
```

文档注释说明其基于当前 PixelMap 创建新 scaled result 并使用 anti-aliasing。因此已有解码 PixelMap 可以
在不重新读取 URI 的情况下应用同一目标尺寸。

## 修复边界

剪贴板入口复用上述 planner；超限 PixelMap 创建 scaled copy 后检查实际 `getImageInfo()` 尺寸，再编码为
WebP lossy 85。scaled copy 在 finally 中释放；源 PixelMap 由外层 finally 释放。编码结果继续受 100 MiB
上限约束，失败不返回部分产物。
