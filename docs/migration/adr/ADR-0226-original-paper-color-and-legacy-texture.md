# ADR-0226：恢复原版 paper color、legacy picker 与纹理渲染

## 状态

Accepted — 2026-08-16，Phase 249。

## 背景

Phase 247/248 已恢复 picker 提交边界、共享 spacing 和收藏，但 `OriginalTemplatePickerDraft` 仍只保存尺寸与
方向，颜色只能沿用当前值；UI 没有原版六个 legacy 选项或 HSV；`PaperRenderer` 忽略 `legacyPaperIndex`，
并用主题纯色替代原版纸张。

进一步直读原版 `s3a/htd/o1/iq0/n7j/ua5/m3a/p4a/u3a/j79` 后确认，颜色和 legacy 同样是草稿字段，
且原版包含 15 张必须重复平铺的真实纹理。

## 决策

### 1. picker 草稿保存完整 `s3a`

`OriginalTemplatePickerDraft` 增加 `backgroundColor` 与 `legacyPaperIndex`。尺寸、方向、颜色、legacy 的任何
变化都只更新本地草稿；点击 Plain/Lines/Grid/Dots 卡片才产生默认模板或当前笔记提交。

新 UI 动作按原版互斥：

- legacy -> `backgroundColor = null`
- custom color -> `legacyPaperIndex = null`

读取历史值不强制互斥，以免破坏合法旧数据。选中态与收藏候选比较完整颜色、legacy、尺寸、方向、线型和
spacing。

### 2. 自定义色使用原生 Slider 组成 HSV，不提供 alpha 编辑

当前 ArkUI 面板使用 Hue/Saturation/Brightness 三个原生 Slider。读取或仅展开已有 ARGB 时保留 alpha；用户
实际移动 HSV，或从 legacy／无颜色切换为 custom 后写 opaque ARGB，匹配原版 `rw1(..., false)`。不使用
12 色画笔预设替代纸张 picker。

### 3. 精确移植 15 张原版 WebP

原版资源逐字节复制到 rawfile，专项 replay 比较全部 SHA-256。禁止重新生成、压缩或用近似纯色替代。
wire 中 1～15 以外的 legacy index 保持可读，但不伪造纹理。

### 4. loader 明确所有权和 generation

- 主画布只持有当前需要的一张纹理；页面/设置切换以 page generation + texture generation 丢弃迟到结果；
- `ImageBitmap` 与 `PixelMap` 在替换、离页和组件销毁时释放；
- 缩略图每次渲染只加载所需纹理，并在 finally 释放，避免无上限解码缓存；
- 原版是并发缓存，Harmony 选择“主画布单当前值 + 缩略图短生命周期”以适配内存预算，同时保持视觉语义。

### 5. 渲染顺序与颜色策略按原版

纸张绘制顺序为：底色 -> repeat legacy texture -> PDF -> flair。纹理横纵 repeat，逻辑 tile 为 1024×1024。

线色由 `u3a` 的 legacy 表、常用颜色映射和 HSV/亮度算法产生，不再固定使用主题灰。无显式颜色时按原版
opaque white 得到 `#BBBBBB`，未知 legacy 使用原版 opaque black fallback。深色主题只反转非暗纸；原版暗
legacy `{8,11,12,14,15}` 不重复反转。Canvas `filter = invert(1)` 只包围纹理填充。

### 6. 移除 opaque-only 数据校验

`PageBackgroundModel.validateOriginalPaper()` 接受 0～255 的完整 alpha，但仍拒绝颜色通道只出现一部分。
UI 新色 opaque 与数据格式可保留 alpha 是两个不同边界。

## 被否决的方案

### 用六个 swatch 纯色直接绘制页面

否决。swatch 是 picker 识别色，原版 canvas 使用 15 张细节明显的 WebP。

### 启动时一次解码全部 15 张纹理

否决。压缩资源约数 MB，但 RGBA 解码会接近 60 MiB；移动端不应为未使用纸张常驻全部像素。

### 保存颜色时立即修改默认模板/当前笔记

否决。违反原版 `s3a -> l3a` 的模板卡提交边界，也会制造额外 Undo/持久化动作。

### 继续强制 `alpha === 255`

否决。原版实体、转换和 wire 格式保存 alpha；无 alpha 只属于当前 UI 控件能力。

## 后果

正面：

- 默认模板与编辑器 picker 都可组合尺寸、方向、纸色、legacy、线型与 spacing；
- 收藏/选中态不再漏比较颜色与 legacy；
- 主画布和缩略图都能消费原版纹理与线色；
- 快速切页不会由迟到的旧纹理覆盖当前页；
- 原版 ARGB alpha 不再被模型拒绝。

限制：

- 模板卡的小预览使用原版 swatch 近似 legacy 纹理，主画布/缩略图才使用真实 WebP；
- 未做设备像素验收，Canvas pattern filter、popup 高度和 WebP 内存峰值仍需真机；
- 未为未知 legacy index 伪造资源，这是故意的 fail-safe。

## 验证

- 专项：`D02_ORIGINAL_PAPER_COLOR_LEGACY_TEXTURE_REPLAY_OK`
- 全量：`REPLAY_FILES=234 FAILED=0`
- 15/15 原版 WebP SHA-256 相同
- `git diff --check` 通过
- `hvigorw clean --no-daemon` 成功
- clean 后 `note@ohosTest`、`note@default` 严格串行构建成功
- 未启动设备、模拟器、虚拟机、真机或 Hypium
