# ADR-0609：分享面板 JPG/PNG 行点亮（当前页整页栅格化导出）

- 状态：Accepted
- 日期：2026-09-23
- 阶段：Phase 642
- 证据：`docs/migration/evidence/original-share-page-image-export-jadx-2026-09-23.md`
- 关联：ADR-0608（分享面板五格式 fail-closed 表）

## 背景

原版分享面板 `s6d` 含 JPG/PNG 格式（`atc` case6/7），对所选页
栅格化导出并经安卓系统分享 Intent 分发；`v6d` 面板状态携带页选择
集合（`Set l` + `int m`），支持页范围子集。

Phase 641 落地分享入口时，JPG/PNG 因"需页级栅格化器"被置灰。
复核发现 `ThumbnailRenderer` 已覆盖完整元素栈（纸面/PDF 背景/笔/
文字/形状/图/公式），渲染路径分辨率参数化——整页导出只需换
输出几何，栅格化器事实已具备。

## 备选方案

1. **页选择 + 多文件导出全复刻**：`v6d.l` 页集合 + 逐页多文件分发。
   HarmonyOS 的 `DocumentViewPicker.save` 每次存一文件，多页需目录
   选择器或打包 zip——交互范式不同，留待后续 Phase。
2. **当前页单文件导出（采用）**：先覆盖最高频场景（导出正在看的
   一页），行点亮、管线走通；页选择与批量分发登记差异。
3. **继续置灰等完整方案**：把可用功能扣押到完整复刻，违背逐阶段
   可用性原则。

## 决定

采用方案 2：

- `ThumbnailRenderer` 抽 `renderPageCore` 共享体，新增
  `renderPageExport`：`pagePixelSize × scale` 整页输出、
  `offset {0,0}` 无边距，独立栅格预算 4096 边 / 16M px；
- `PageImageExporter`：`packToData`（png / jpeg q92）→ 临时文件 →
  `DocumentViewPicker` 保存 → 分块复制，与 `exportToFile` 同范式；
- 分享面板 JPG/PNG 行点亮 → `onShareImage(format)` →
  `NotePage.shareCurrentPageAsImage`：当前页 ×2.0（≈192dpi）
  亮主题栅格化导出。

## 登记差异（fail-closed / 后续项）

| 原版行为 | Harmony 现状 | 解锁条件 |
|----------|--------------|----------|
| 页选择集合 + 多文件分享分发 | 仅当前页单文件 | 目录 picker 或打包策略 + 面板页选择 UI |
| 安卓系统分享 Intent | DocumentViewPicker 保存 | HarmonyOS 无同型组件 |
| `y59.b` 栅格分辨率 | 2× pagePixelSize ≈192dpi | JADX 不可见，按观感取档 |

## 验证

- `d05-original-share-page-image.mjs`：25 断言钉死栅格化预算、
  打包格式、picker 管线与接线；`d05-original-editor-share.mjs`
  41 断言回归（行点亮状态同步更新）。
- 全量 Desktop Replay 527/527；双 HAP clean 构建成功。

## 后续

- PDF 行：需 PDF 编码器（可将各页栅格图嵌入 PDF 容器），独立 Phase。
  （已由 Phase 643 / ADR-0610 以逐页 DCTDecode JPEG 嵌入方案点亮。）
- LINK 行：账号/链接后端，goal 外基础设施。
- 页范围选择：随面板两步交互一并补齐。
