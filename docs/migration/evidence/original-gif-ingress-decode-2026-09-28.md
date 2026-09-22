# 原版 GIF 插入链路解码（2026-09-28）

阶段：Phase 581。对象：原版插入菜单 "Add GIF" 项与 GIF 动图渲染。

## 1. 菜单项（qc.java I=0 分支）

插入菜单五项：Add Files → Add Photo → Take Photo → **Add GIF** →
Insert Math（`feature_note_toolbox__add_gif`，图标
`ui_designsystem__gif`）。GIF 项条件渲染：`function4 != null` 才显示
——即宿主必须提供 GIF 回调；`kkf.a` 经 `nti`/`rh8` 逐层透传
Function0，静态无法钉到最终 picker 目标（与 Add Files 相同的
lambda 透传盲区）。

## 2. GIF 只是普通图片类型（oj3.java）

`oj3.a`（受支持图片集）= png/jpg/jpeg/webp/tif/tiff/**gif**/heif/heic；
`oj3.b` = 对应 MIME 集，被 `ff5`（文件 picker accept）、`sl`（拖放）、
`yne`（剪贴板）共用 —— GIF 经图片/文件/粘贴/拖放全入口天然接受。
`oj3.e/f`（picker mime 数组）含图片+音频+文档+pdf+txt（f 另含
application/octet-stream）。

## 3. 动图渲染（ly.java / jy.java）

原版用 `AnimatedImageDrawable`（API28+）渲染 GIF：`ly` 解码 drawable，
`AnimatedImageDrawable` 实例挂到 `jy`（图片视图），`setRepeatCount`
可控循环。这是 **专用动画视图**，不是静态 PixelMap 路径。

## 4. Harmony 侧现状（已 fail-closed）

`ImageAssetLoader.ets`：`mimeType === 'image/gif'` →
`ImageAssetLoadState.ANIMATED_UNSUPPORTED`，原因串明确写明
"animated GIF requires the original dedicated image view"。
HarmonyOS 画布渲染走静态 PixelMap，无等价的 AnimatedImageDrawable
逐帧视图接入 canvas 渲染管线 —— 维持 fail-closed（GIF 资产可入库，
渲染为空态）。

## 5. 结论

- "Add GIF" 菜单项本质是图片 picker 的便捷入口（GIF 已在接受集内），
  其专属 picker 目标静态不可钉 —— 与 Add Files 同为 lambda 透传盲区，
  不臆造。
- 动图渲染属有意 fail-closed，已有 `ANIMATED_UNSUPPORTED` 实现 +
  原因文案，无需改动。
