# T-019 编辑器工具栏

## 目标

实现编辑器工具栏组件：Pen/Pencil/Highlighter/Eraser/Selection 工具切换 + 颜色选择器 + 粗细滑块 + 工具状态管理。

## 参考

- 知识库：REVERSE_ANALYSIS.md §22（Brush 模型 f21：brushStyle/widthSize/color + 工具枚举 zy5）、§39.6（工具栏 48vp 高、单工具 48vp 点击区、24vp 图标）
- 契约：`note/src/main/ets/core/model/BrushTypes.ets`（ToolType/BrushSpec/BrushSpec）
- 依赖：T-016（NotePage 空壳）

## 实现要求

### 创建文件

1. `note/src/main/ets/ui/editor/EditorToolbar.ets`（@Component 工具栏）
2. `note/src/main/ets/ui/editor/EditorViewModel.ets`（@Observed 编辑器状态）
3. `note/src/main/ets/ui/components/ColorPicker.ets`（颜色选择网格）
4. `note/src/main/ets/ui/components/WidthSlider.ets`（粗细滑块）

### EditorViewModel

```typescript
@Observed
export class EditorViewModel {
  currentTool: ToolType = ToolType.PEN;
  brushStyle: BrushStyle = BrushStyle.MONO;
  brushColor: number = -16777216;  // 黑
  brushWidth: number = 36.0;
  eraserIsPartial: boolean = false;
  selectionIsFreehand: boolean = false;
  showColorPicker: boolean = false;
  showWidthSlider: boolean = false;

  getRenderSpec(): RenderSpec  // 从当前状态构建 RenderSpec
  selectTool(tool: ToolType): void
}
```

### EditorToolbar 布局

```
Row (height: 48vp) {
  [Pen 按钮] [Pencil 按钮] [Highlighter 按钮] [Eraser 按钮] [Selection 按钮]
  Divider
  [颜色按钮（当前色圆点）] [粗细按钮（当前宽度指示）]
  Divider
  [Undo] [Redo]  // T-021 实现功能
}
```

- 选中工具高亮（backgroundColor 变化）
- 点击颜色按钮 → 展开 ColorPicker 弹层
- 点击粗细按钮 → 展开 WidthSlider 弹层

### ColorPicker

预设 12 色网格（黑/灰/红/橙/黄/绿/青/蓝/紫/粉/棕/白）+ 选中态边框。

### WidthSlider

Slider 组件，范围 [2, 100]，默认 36，步进 2。显示当前值。

### 鸿蒙特有约束

- 工具栏高度固定 48vp，按钮点击区 48×48vp。
- 使用 @ObjectLink 绑定 EditorViewModel（父组件 NotePage 持有 @State viewModel）。
- 弹层用 `Popup` 或 `Panel` 组件。
- 颜色用 ARGB int 存储，显示时转 hex 字符串。

## 验收标准

- [ ] `check_ets_files` + `build_project` 通过
- [ ] 工具栏 5 个工具按钮可切换，选中态高亮
- [ ] 颜色选择器弹出、选色后关闭、当前色更新
- [ ] 粗细滑块拖动后 brushWidth 更新
- [ ] getRenderSpec() 返回正确的 RenderSpec
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-019-完成.md`
