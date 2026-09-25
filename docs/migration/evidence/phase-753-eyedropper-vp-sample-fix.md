# Phase 753 证据：eyedropper 取样坐标 vp/px 单位修复

> 证据基线：`decompiled_1.0.3`（JADX 输出，`C:\Users\Cisco He\Desktop\Notability\` 只读）。
> 关联：ADR-0646（eyedropper 移植）、ADR-0698（同型 vp2px 缺陷修复先例）。

## 1. 原版语义（既有登记）

- `a3a.java`：画布 `Bitmap.getPixel(clamp)` → `kkf.d` → `iu1` ARGB int；
- `nui.java`：放大镜内容 = 取样点 **24px 邻域**位图（物理像素）。

## 2. 缺陷分析

Harmony `sampleEyedropper`（Phase ~679 落地）按"ctx 为 px 缓冲"假设编写：

```ts
const px = Math.round(xVp * density);   // 触点 vp → 物理 px
const data = ctx.getImageData(sx, sy, sw, sh);   // sw=24
const idx = (cy * sw + cx) * 4;
createPixelMap(buffer, { size: { width: sw, height: sh }, ... });
```

但 ArkUI `CanvasRenderingContext2D` 默认 `LengthMetricsUnit.DEFAULT` =
**vp 绘制空间**：

- `getImageData(sx,sy,sw,sh)` 入参按 **vp** 解释；
- 返回 `ImageData.width/height` 为**物理 px**（官方文档：
  "矩形区域实际像素宽度。单位为px"），`data` 长度 = W×H×4 字节。

后果（density≈2.75 设备）：

1. `px = xVp×density` 送入 vp 解释的 API → 取样区偏移约 2.75×；
2. `sw=24` 被解释为 24vp → 实际取样 66 物理 px 边长；
3. `(cy*sw+cx)*4` 以 vp 边长当 px 行距 → 索引到错误的像素/越界；
4. `createPixelMap({size:24×24}, buffer=66×66×4)` —— 声明尺寸与
   缓冲不匹配（放大镜位图畸形或取样失败）。

## 3. Harmony 修复

`sampleEyedropper` 改写为 vp 空间直取 + 物理 px 行距：

- 取样区 vp 边长 = `24/density`（保持原版 24 物理 px 邻域语义）；
- `sx = clamp(xVp − 12/density, 0, wVp − swVp)`（vp 坐标直取）；
- `data.width/height`（物理 px）作为行距与 PixelMap 尺寸；
- 触点像素偏移 = `(xVp − sx) × density`（vp 差 → 物理 px 偏移）。

## 4. 文件清单

- `note/src/main/ets/ui/editor/NoteCanvasView.ets`：
  `sampleEyedropper` 取址/行距/PixelMap 尺寸三段修正 + 注释。
- `docs/migration/replays/d02-original-eyedropper.mjs`：
  更新 `canvas pixel sampling` 钉 + 新增 4 条 vp 空间钉。
