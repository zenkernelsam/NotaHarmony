# ADR-0701：eyedropper 取样坐标 vp/px 单位修复

- 状态：Accepted
- 日期：2026-09-25
- 关联：ADR-0646（eyedropper 移植）、ADR-0698（同型 vp2px 缺陷）、
  `phase-753-eyedropper-vp-sample-fix.md`

## 背景

ADR-0698 的 Phase 750 修复确认 `CanvasRenderingContext2D` 默认
`LengthMetricsUnit.DEFAULT` = vp 绘制空间，并登记了
`sampleEyedropper` 的同类 `getImageData` 密度乘积缺陷为观察项。
本 Phase 落地修复。

## 缺陷

原实现把触点 vp 坐标先乘 density 再送入 `getImageData`——但 vp
模式下该 API 入参就是 vp（取样位置偏移约 density 倍）；且返回的
`ImageData.width/height` 是物理 px，代码却以请求边长（vp 值 24）
当像素行距索引 data、并以 24×24 声明 PixelMap——行距错位 +
位图尺寸与缓冲失配（density≈2.75 时实际取样 66px 边长）。

## 决定

`sampleEyedropper` 统一 vp 空间取址：

- 请求边长 `24/density` vp ⇒ 取样仍为原版 `nui` 的 24 物理 px 邻域；
- 触点、区域起止、画布宽高全部 vp 直取（不再乘 density）；
- 像素行距与 PixelMap 尺寸改用 `data.width/height`（物理 px）；
- 触点像素偏移 = `(xVp − sx) × density`。

## 后果

- 取色器放大镜显示正确的触点邻域位图，提交颜色命中触点像素——
  此前在高密度屏上必然取样偏移且放大镜内容畸形。
- 修复面与 Phase 750 同类（`LengthMetricsUnit.DEFAULT=vp`），
  两处均已收敛；全仓 vp2px 用点已复核无其他同类误用
  （mathRaster/pdfRaster 的 density 乘子是位图导出目标，合法）。
