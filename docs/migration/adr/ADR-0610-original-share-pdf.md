# ADR-0610：分享面板 PDF 行 — 整册逐页栅格化 PDF 导出

- 阶段：Phase 643
- 状态：已实现（栅格子集）；上游编码细节未反编译，差异登记如下

## 背景

Phase 641 按 `s6d` 原序落地分享面板五行（LINK/PDF/NOTE/JPG/PNG），
其中 PDF 置灰 fail-closed（PDF 编码器未备）。Phase 642 的
`renderPageExport` 把整页栅格化打通后，PDF 行只差编码器：每页
JPEG 栅格以 `/Filter/DCTDecode` 直通嵌入即可构成合法 PDF，无需
zlib/字体子系统。

## 原版证据

- `s6d.java`：`PDF(ui_share__chip_pdf, action_pdf, ..., atc(4))`；
  `atc` case4 = `ui_designsystem__share_pdf` 图标。
- `b7d.java`：`list.size() > 1 ? s6d.PDF : s6d.LINK` —— 集合导出
  默认 PDF。
- `y59.java`：`a(...)` 对页集合调 `b(s6d.PDF, listL0, ...)`；
  `y59.b` JADX 未反编译，上游编码实现不可见。

## 决策

1. **纯栅格 PDF**：每页一张满幅 JPEG（q92、×2 ≈192dpi、亮主题、
   全元素栈，与 JPG 导出同渲染管线），`DCTDecode` 直通嵌入，
   `MediaBox` 写 mm→pt 物理尺寸。理由：上游编码不可见，栅格是与
   已实现 JPG/PNG 路径同源的最小风险方案；阅读器按 MediaBox 等比
   缩放，物理尺寸正确。
2. **整册导出**：`this.pages.slice()` 快照序 = 原版页序；页选择
   集合（`v6d.l`）作为已登记差异暂不实现。
3. **预算闸门**：512 页 / 单页 JPEG 32MB / 整册 256MB，非法输入
   fail-closed 抛错（编辑器不崩）。
4. **保存管线同构**：临时文件 → `DocumentViewPicker` `.pdf` →
   分块复制 → fsync → 清理，复用 `export_done`/`export_failed` toast。

## 登记差异

1. `y59.b` 未反编译：上游或含矢量文字/字体嵌入；Harmony 恒栅格。
2. 无页范围选择：`v6d.l`/`m` 对应能力未实现，恒整册。
   （已由 Phase 644 / ADR-0611 部分补齐：全部/当前页二选；
   任意子集仍登记。）
3. 无多笔记合并导出（`b7d` `size()>1` 场景无对应入口）。
4. LINK 行保持 fail-closed（账号后端依赖）。

## 验证

- 新 fixture `d05-original-share-pdf.mjs`：24 断言（枚举/图标/默认
  策略证据 + 组装器结构/预算/picker/接线 pin）。
- `d05-original-editor-share.mjs` pin 更新：PDF 行 `true`、
  `onSharePdf` 派发。
- 全量 Desktop Replay 528/528 绿；`note@ohosTest`/`note@default`
  clean 构建通过。
