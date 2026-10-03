# ADR-1414：文本编辑光标可见性滚动（jyh.g / lcn.h）

## 状态

已接受（Phase 1479）——原生移植，含登记差异。

## 背景

原版编辑态 `zle` 流驱动 `jyh.g`：按 `li8` 动作类型决定滚动策略——
SELECT_ALL 不滚；PAGE_UP/DOWN 页滚后 reveal；OTHER（输入/方向键等）
仅当 1dp 宽 caret 矩形越 5% 内缩视口时 `mfc.u(rect,0.1f)` 最小位移
滚动至可见。`lcn.h` 在 IME/底部锚定场景把 caret 矩形按 336dp/zoom
扩展后 reveal。

Harmony 侧：`TextBlockOverlay` 内嵌原生 `TextArea`（块内自滚），
但**画布视口不会因 caret 越界/键盘遮挡而滚动**——缺口。

## 决策

1. `Canvas2DTextRenderer.caretRectAtIndex`：复用 `caretIndexAtPoint`
   同一 `layoutLines`/`measureRange` 核，caret 索引 → 1 单位宽、
   行高矩形（world 坐标，element.transform AABB）——`lcl.h` 等价物。
2. `revealEditingCaret()`：5% 内缩"全含"判据 + 10% 内缩最小位移 →
   `panBy(−jM)`；`onCaretChange`/`onDraftChange` 双通道触发。
3. IME 避让并入有效视口底边收缩：`getWindowAvoidArea
   (TYPE_KEYBOARD).bottomRect.height`（懒查询，免去事件订阅）；
   `editorWindow` 在 `aboutToAppear` 缓存。
4. SELECT_ALL 门以"选区覆盖全部草稿文本"近似。

## 弃用的替代方案

- **caret 像素位置走 TextArea 私有 API**：无公开 caret-rect API；
  自研 layout 与渲染核同源，一致性更好。
- **`on('avoidAreaChange')` 事件驱动**：reveal 只在 caret/文本变化
  时才需要——懒查询更简单且等价（键盘先于 caret 事件到位）。
- **PAGE_UP/DOWN 预滚 ∓0.9h**：原生 TextArea 已处理页移；叠加会
  双重滚动——按 OTHER 支近似并登记。

## 后果

- 输入/光标移动到视口（或被键盘遮挡区）边缘时页面自动跟随——
  原版体验对齐；
- 差异：滚动无动画；PAGE 键无 ∓0.9h 预滚；SELECT_ALL 判定为
  近似谓词；Top 锚定 IME 场景未实现（Harmony 无对应物）。
