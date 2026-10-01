# Phase 1443 — 进行中套索手势上的粘贴不产选区

## 范围

`j01` 粘贴分发 `hsf`（进行中套索）支：粘贴内容照插但选区结果为
`null`——不将粘贴内容断言为新选区。Harmony 原以 `selectionVisible`
保种判定，进行中手势下走 `true` 支 → 误产 isf 集合选区。

## 原版证据

`j01.java:59-90`：isf→`lb8.e` 重装配 / jsf→`new jsf` / lsf→`new lsf` /
hsf→log + `return null`。

## Harmony 变更

- `SelectionTool.isSelectionGestureInProgress()` 新谓词
  （isActive && 六类 id 全空）。
- 两处粘贴落点以此为门跳过 `selectElementIds`：
  `applyOriginalGroupClipboardPaste` 回调、`commitOriginalClipboardPaste`
  完成支。

## 验证

- `d02-paste-in-progress-gesture.mjs`：9/9。
- 全量基线 + `note@default` / clean `note@ohosTest`：见提交记录。

## 决策

ADR-1378。
