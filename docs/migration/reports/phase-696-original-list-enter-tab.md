# Phase 696 — 原版空装饰段 Enter + 列表段 Tab（fm7.g/fm7.h）移植

## 范围

`fm7.g()`/`fm7.h()`：富文本编辑器的经典列表行为——空装饰段上
按 Enter 退装饰/降级，列表段上按 Tab 缩进。

## 原版行为（证据见 phase-696 evidence）

- Enter：空列表段（`qi3.c()` 空段 + `n4c.x` 列表装饰）→
  indent>0 减一级、indent==0 `clearDecoratorOnCursorParagraph`；
  空引用/代码段（`n4c.w`）→ 清装饰；其余插入 `\n`。
- Tab：光标段为列表装饰（**不要求空段**）→ `h5a(+1)`；
  否则 `replaceSelectedText("\t")`。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `onWillInsert` 拦截 `'\n'`：`isParagraphEmpty`（qi3.c 等价：
    段内零非换行字符）+ 装饰分派——列表(1-3) indent>0→
    `adjustIndentLevel(-1)`、==0→`clearParagraphDecorator`；
    引用/代码(4/5)→`clearParagraphDecorator`；命中返回 `false`
    取消插入。
  - `onEditorKeyEvent` 非 Ctrl 分支加 `keyCode===2049`(TAB) →
    `handleTabKey()`：列表段 `adjustIndentLevel(1)`；否则
    draftText 选区替换 `'\t'` + run 差分平移 + caret 落位 +
    `onDraftChange`（复用 confirmLink 替换管线）。
  - `clearParagraphDecorator`：清 decoratorStyle +
    programmingLanguage（code 装饰清除时语言字段一并清除），
    其余段落字段保留，空样式归并删除。

## 验证

- Replay：`d02-original-list-enter-tab.mjs` 23 项全绿；
  lease-bound 计数不变。
- 构建：`note@default`/`note@ohosTest` clean assembleHap 成功
  （见提交记录）。
- 真机/模拟器：未验证（约束内）。

## 限制

- `onWillInsert` 仅见 `insertValue==='\n'`——软键盘"回车"在
  HarmonyOS TextArea 语义下触发路径已按 API 12 回调挂载，真机
  软键盘/硬键盘 Enter 一致性待验收（已加 R-33 检查行）。
- `clearDecoratorOnCursorParagraph` 是否连带清 programmingLanguage
  原版不可静态判定——按"语言字段对非代码段无意义"的规范化语义
  一并清除，记 evidence。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `docs/migration/replays/d02-original-list-enter-tab.mjs`
