# Phase 1443 — 进行中套索手势上的粘贴不产选区（证据）

## 原版证据（decompiled_1.4.2 `j01.java:59-90`）

粘贴分发回调 `j01` 按既有 `msf` 选区种类产出"粘贴后选区"：

```java
if (msfVar instanceof isf)  → lb8.e(...)            // isf 重装配
if (msfVar instanceof jsf)  → new jsf(...)          // jsf 保种
if (msfVar instanceof lsf)  → new lsf(t87Var)       // lsf 保种
if (msfVar instanceof hsf) {
    a.d(NOTE_UI, "Paste attempted on in-progress lasso selection", …);
    return null;                                    // ← 不产选区结果
}
```

`hsf`（进行中套索，`"Paste attempted on in-progress lasso selection"` 日志
佐证）上粘贴：内容仍经上游路径插入，但选区结果为 `null`——不将粘贴
内容断言为新选区，进行中手势态不受污染。

## Harmony 状态（修复前）

两处粘贴落点均按 `selectionVisible ? undefined : true` 传入 drawnKind：
进行中手势时 `selectionVisible=false`（空选区隐藏），故走 `true` 支
→ 粘贴内容被断言为 `isf` 集合选区——与原版 null 语义不符。

## Harmony 修复

- `SelectionTool.isSelectionGestureInProgress()`：
  `isActive && 六类 id 全空`（beginSelection 已置、finalize 未决）。
- `applyOriginalGroupClipboardPaste` 回调与 `commitOriginalClipboardPaste`
  完成支：`!isSelectionGestureInProgress()` 才调 `selectElementIds`。
- 非 hsf 支不变：`selectionVisible ? undefined : true` 保种语义保留。

## 验证

`d02-paste-in-progress-gesture.mjs`：9/9 绿；基线/构建见报告。
