# T-037 页面设置：纸张尺寸/模板选择器

## 目标

PageManagerBar 添加页面设置入口，可选择纸张尺寸（A4/A5/Letter...）、模板（空白/横线/方格/点阵）、方向（纵向/横向），应用到当前页。

## 实现要求

### 修改/创建文件

1. 创建 `note/src/main/ets/ui/components/PageSettingsPanel.ets`
2. 修改 `note/src/main/ets/ui/editor/PageManagerBar.ets`（添加"模板"按钮）

### PageSettingsPanel（bindPopup 或 Sheet）

三个选择区：
- **尺寸**：A3/A4/A5/A6/Letter/Legal/Tabloid（Grid 或 List，选中高亮，显示 mm/in 尺寸）
- **模板**：空白/横线/方格/点阵（4 个小预览块，用 Canvas 绘制迷你预览）
- **方向**：纵向/横向（2 个按钮）

选择后立即应用：
- updatePage 写 page_info 表
- 重绘纸张背景 + 调整画布页面尺寸
- 宽度变化时 viewport"适应宽度"

### 约束

- 用原生 bindPopup/Sheet 承载面板（T-033 原生化原则）
- 尺寸 mm→画布 px 换算：1mm ≈ 3.78px @96dpi（保持现有换算逻辑一致）
- 模板预览小画布复用 PaperRenderer

## 验收标准

- [ ] 模板按钮弹出设置面板
- [ ] 切换模板 → 画布背景即时变化（横线/方格/点阵可见）
- [ ] 切换尺寸 → 页面宽高变化且持久化
- [ ] 切换方向 → 宽高互换
- [ ] 退出重进页面设置保留
- [ ] `check_ets_files` + `build_project` 通过 + 模拟器不崩溃

## 完成报告

`docs/migration/reports/T-037-完成.md`
