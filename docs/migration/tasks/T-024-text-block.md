# T-024 文本框

## 目标

实现文本框工具：双击画布创建文本框 → 进入编辑态 → 输入文字 → 完成后可编辑/移动/删除。MVP 只支持纯文本。

## 参考

- 知识库：REVERSE_ANALYSIS.md §30（TextBlockInfo：textOrigin/blockScaledSize/rotationRadians/insets + 统一 ID 可变换）
- 契约：`note/src/main/ets/core/model/ElementTypes.ets`（TextBlockElement）
- 依赖：T-022（选区变换体系，文本框参与统一选中/移动）

## 实现要求

### 创建文件

1. `note/src/main/ets/rendering/TextBlockTool.ets`（文本框逻辑）
2. `note/src/main/ets/ui/components/TextBlockOverlay.ets`（编辑态 UI）

### TextBlockTool.ets

```typescript
import { TextBlockElement } from '../core/model/ElementTypes';
import { Point2D } from '../core/model/GeometryTypes';

export class TextBlockTool {
  // 创建文本框（双击位置）
  createTextBlock(position: Point2D, color: number, fontSize: number): TextBlockElement {
    return {
      id: generateId(),
      type: ElementType.TEXT,
      transform: [1,0,0,0,1,0,0,0,1],
      bounds: { left: position.x, top: position.y, right: position.x + 200, bottom: position.y + 40 },
      richText: '',
      textOrigin: position,
      blockWidth: 200,
      blockHeight: 40,
      rotationRadians: 0,
      contentLeftInset: 4,
      contentTopInset: 4,
      fontSize: fontSize,
      fontColor: color,
    };
  }

  // 更新文本内容
  updateText(element: TextBlockElement, text: string): TextBlockElement

  // 渲染文本到 Canvas
  renderText(ctx: CanvasRenderingContext2D, element: TextBlockElement): void {
    // ctx.font = `${element.fontSize}px sans-serif`
    // ctx.fillStyle = colorToRgba(element.fontColor)
    // ctx.fillText(element.richText, element.textOrigin.x + inset, element.textOrigin.y + inset)
  }
}
```

### TextBlockOverlay.ets

编辑态覆盖层（@Component）：
- TextArea 组件定位在文本框位置
- 失焦或点击"完成"→ 退出编辑态 → 文本写入 TextBlockElement
- 编辑态显示虚线边框

### 集成到 NoteCanvasView

- 双击画布（非笔画区域）→ 创建 TextBlockElement → 显示 TextBlockOverlay
- 文本框参与选区体系（可被 SelectionTool 选中/移动/删除）
- 文本框渲染在笔画层之上

### 鸿蒙特有约束

- TextBlockTool 禁止平台 import（逻辑层）。
- TextBlockOverlay 是 @Component，使用 TextArea/TextInput 组件。
- MVP 只支持纯文本（richText 字段存 string，不解析富文本标记）。
- 文本框默认宽 200vp，高度自适应（最少 40vp）。
- 双击检测：两次 touchDown 间隔 < 300ms 且距离 < 10vp。

## 验收标准

- [ ] `check_ets_files` + `build_project` 通过
- [ ] 双击画布出现文本编辑框
- [ ] 输入文字后点击完成，文字渲染在画布上
- [ ] 文本框可被 Selection 工具选中并移动
- [ ] 文本框可被删除
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-024-完成.md`
