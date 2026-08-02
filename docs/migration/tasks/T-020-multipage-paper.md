# T-020 多页管理与纸张模板

## 目标

实现页面管理条（添加/删除/翻页）+ 纸张模板程序化绘制（PLAIN/LINES/GRID/DOTS）+ 画布组件重构（NoteCanvasPage → 可嵌入 NoteCanvasView）。

## 参考

- 知识库：REVERSE_ANALYSIS.md §7（纸张模板 qae：程序化绘制 + REPEAT 平铺，LINES 间距 8px/28px、GRID 方格、DOTS 点阵半径 1.25px）
- 契约：`note/src/main/ets/core/model/NoteTypes.ets`（PaperSize/PaperTemplate/PageInfo）
- 依赖：T-017（PageRepositoryImpl）、T-019（EditorViewModel）

## 实现要求

### 创建文件

1. `note/src/main/ets/rendering/PaperRenderer.ets`（纸张背景绘制）
2. `note/src/main/ets/ui/editor/PageManagerBar.ets`（底部页面管理条）
3. `note/src/main/ets/ui/editor/NoteCanvasView.ets`（从 NoteCanvasPage 重构为 @Component）

### PaperRenderer.ets

```typescript
// 禁止 import 平台 API 以外的非 Canvas 类型（可用 CanvasRenderingContext2D）
export class PaperRenderer {
  // 在给定 Canvas 上绘制纸张背景
  renderBackground(ctx: CanvasRenderingContext2D, width: number, height: number, template: PaperTemplate): void {
    switch (template) {
      case PaperTemplate.PLAIN: break;  // 空白
      case PaperTemplate.LINES: this.drawLines(ctx, width, height); break;
      case PaperTemplate.GRID: this.drawGrid(ctx, width, height); break;
      case PaperTemplate.DOTS: this.drawDots(ctx, width, height); break;
      default: break;
    }
  }
  // LINES: 水平线，间距 28vp，线宽 0.5，颜色 #E0E0E0
  // GRID: 水平+垂直，间距 28vp
  // DOTS: 点阵，间距 28vp，半径 1.25，颜色 #BDBDBD
}
```

### PageManagerBar.ets

```
Row (height: 56vp, 底部) {
  [← 上一页] [页码 "2/5"] [下一页 →] [＋ 添加页面] [🗑 删除当前页]
}
```

### NoteCanvasView.ets

将 Phase 2 的 NoteCanvasPage 核心逻辑（Canvas + onTouch + 渲染链路）重构为 `@Component struct NoteCanvasView`，使其可嵌入 NotePage。
- 接收 `@ObjectLink viewModel: EditorViewModel` 控制工具/颜色/宽度
- 接收 `@Prop currentPage: PageInfo` 控制纸张模板
- 保留全部 Phase 2 渲染能力

### 鸿蒙特有约束

- PaperRenderer 绘制用 Canvas 2D API（lineWidth/strokeStyle/arc）。
- 纸张背景每帧先绘制，再叠加笔画层。
- PageManagerBar 通过回调通知父组件翻页/增删。
- NoteCanvasView 不是 @Entry（它是子组件）。

## 验收标准

- [ ] `check_ets_files` + `build_project` 通过
- [ ] NotePage 中可见画布 + 底部页面管理条
- [ ] 切换纸张模板（LINES/GRID/DOTS）背景正确显示
- [ ] 添加/删除页面后页码更新
- [ ] 画布书写功能不退化（Phase 2 能力保留）
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-020-完成.md`
