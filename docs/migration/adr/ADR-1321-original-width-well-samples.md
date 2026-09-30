# ADR-1321：宽度预设槽位渲染笔画厚度样张而非数字

## 状态

已接受（Phase 1385）。

## 背景

`WidthSlider` 的预设槽位此前把每个预设宽度渲染成 `Text(width.toString())`（数字徽章）。
对照原版，预设槽位是一枚显示**笔画厚度样张**的图像（横向笔画条，厚度 ∝ 预设宽度），
不显示数字。

## 原版证据

- `setting_pen_width_mini_layout.xml`：预设槽位是 `ImageView`(id `width_view`)，
  24×24dp，背景 `setting_mini_attr_bg` —— 由代码填入样张图像，非文本。
- `SpenPenWidthMiniLayout.java`：槽位图标由 S-Pen SDK 绘制（厚度/压力样张），
  属专有 SDK 内部渲染，无对应矢量资源可直接拷贝。
- `yed.java`：滑杆上方独立 `ui_tools__width` = "Width: %1$d" 文本读数
  （数值由该读数承载，不在预设槽位上）。

## 决策

1. 预设槽位由 `Text(width)` 改为横向圆角笔画条 `Row{height=wellSampleHeight(width), fill=brushColor}`：
   条厚 ∝ 预设宽度（`Math.max(2, Math.min(16, width))` 像素缩放），符合原版
   「厚度样张」语义。
2. 预设宽度数值保留为 `.accessibilityText(width.toString())` —— 视觉与原版一致
   （槽位只显样张），数值由无障碍文本与下方 "Width: N" 读数承载。
3. 槽位选中态边框、photoImportLease 门控、`setBrushWidth(width, index)` 回调不变。
4. S-Pen SDK 的精确样张像素为专有内部实现，采用等价的横向圆角条表达同一语义，
   属受控适配而非逐像素拷贝。

## 后果

- 预设槽位视觉与原版对齐：一眼分辨厚薄，槽位不再暴露数字。
- 宽度精确值仍由 "Width: N" 读数与无障碍文本提供。
- 新增 Replay `d02-original-width-well-samples.mjs`（13 断言）锁定样张结构、
  厚度缩放、选中态与数值无障碍。

## 参考

- `docs/migration/evidence/phase-1385-original-width-well-samples.md`
- `docs/migration/reports/phase-1385-original-width-well-samples.md`
- `docs/migration/replays/d02-original-width-well-samples.mjs`
