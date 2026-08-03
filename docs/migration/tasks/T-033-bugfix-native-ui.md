# T-033 Bug 修复 + 原生化 UI 审查

## 目标

修复 Pencil 渲染 bug + 将自定义 UI 控件替换为 ArkUI 原生组件 + 全面审查 UI 原生化机会。

## Bug 1：Pencil 渲染大面积污染画布

### 现象

用 Pencil 工具画一笔后，大面积画布区域被渲染铅笔纹理，而不是只在笔画轨迹附近显示 splat。

### 可能原因

1. `renderPencilSplats()` 中 OffscreenCanvas 尺寸等于全画布，且 splat 坐标没有正确限制
2. `drawImage(offscreen)` 时没有 clip 到笔画 bounds
3. splat 生成器的坐标计算有误（可能 splat 点坐标是相对值但被当成绝对值）
4. OffscreenCanvas 着色后 `source-in` 操作影响了整个画布而非局部区域

### 排查步骤

1. 检查 `Canvas2DStrokeRenderer.renderPencilSplats()` 中 OffscreenCanvas 的使用方式
2. 确认 splat 坐标是否被正确 translate 到画布坐标系
3. 确认 drawImage 时是否限制了绘制区域
4. 检查 `StrokeSession.addBatch()` 中 splatGenerator 的输入参数

### 修复方向

- OffscreenCanvas 应该只覆盖笔画 bounds 区域（不是全画布大小）
- 或者在主画布 drawImage 前先 clipRect 到笔画 bounds
- splat 坐标应该是画布绝对坐标，不需要额外 offset

## Bug 2：选区工具栏应使用原生组件

### 现象

选中笔画后弹出的操作菜单（复制/粘贴/删除等）是完全自绘的自定义组件。

### 原版确认

原版 Notability 使用 Jetpack Compose 自定义组件（不是原生 Android PopupMenu）。但在鸿蒙上，应优先使用 ArkUI 原生组件以获得更好的平台一致性和交互体验。

### 修复方向

将 `SelectionOverlay.ets` 中的自绘菜单替换为 ArkUI 原生组件：

| 当前实现 | 应替换为 |
|----------|----------|
| 自绘 Row + Button 菜单 | `bindMenu()` 或 `Menu` + `MenuItem` |
| 自绘弹窗 | `AlertDialog` / `CustomDialog` |
| 自绘 Popup 面板 | `bindPopup()` / `Popup` |

### ArkUI 原生组件用法

```typescript
// 方案 A: bindMenu（推荐，轻量）
.bindMenu([
  { value: '复制', action: () => { /* copy */ } },
  { value: '剪切', action: () => { /* cut */ } },
  { value: '删除', action: () => { /* delete */ } },
])

// 方案 B: Popup（更灵活）
.bindPopup(showPopup, {
  builder: this.popupBuilder,
  placement: Placement.Bottom,
})
```

## Bug 3：全面 UI 原生化审查

### 审查范围

检查以下文件，找出可以用原生组件替代的自绘 UI：

| 文件 | 检查点 |
|------|--------|
| `ui/editor/EditorToolbar.ets` | 工具栏是否可用原生 Toolbar 模式 |
| `ui/components/ColorPicker.ets` | 是否可用原生 ColorPicker 或 Grid |
| `ui/components/WidthSlider.ets` | 是否已用原生 Slider（应该是） |
| `ui/components/SelectionOverlay.ets` | 菜单部分用 bindMenu |
| `ui/components/TextBlockOverlay.ets` | 是否用原生 TextArea（应该是） |
| `ui/library/LibraryPage.ets` | 删除确认是否用 AlertDialog |
| `ui/settings/BackupPage.ets` | 错误提示是否用 AlertDialog |
| `ui/editor/PageManagerBar.ets` | 是否可用原生模式 |

### 替换原则

1. **有原生等价物** → 用原生（Menu/Dialog/Popup/Slider/Picker）
2. **无原生等价物** → 保留自绘（如画布渲染、选区边框虚线）
3. **交互类**（菜单/对话框/通知）→ 必须原生
4. **展示类**（工具栏布局/颜色网格）→ 可以自绘但优先原生

## 验收标准

- [ ] Pencil 工具画一笔 → 只在轨迹附近显示纹理，不污染全画布
- [ ] 选区菜单使用 ArkUI bindMenu 或 Popup（不是自绘 Row+Button）
- [ ] 删除确认使用 AlertDialog（不是自绘）
- [ ] `check_ets_files` + `build_project` 通过
- [ ] 模拟器运行不崩溃
- [ ] 完成报告列出所有审查结果（已替换/保留自绘/原因）

## 完成报告

`docs/migration/reports/T-033-完成.md`
