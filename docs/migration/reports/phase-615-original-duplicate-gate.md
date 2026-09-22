# Phase 615 — DUPLICATE 顶层项 >=2 门槛（dhb case4）

## 原版证据

- `dhb.java:17638-17654`：DUPLICATE 仅 `ktcVar instanceof ftc`
  可触发；`A1 = T1(ftc.q) + ftc.m 组 id` 集合 `size() >= 2` 才
  派发 `kk9` 协程并 `fvb.a()` 清选区，否则静默。`itc`（单元素）、
  `gtc`（单组）不进 case4——单选 DUPLICATE 是死操作。
- `gtc.java:90-93`：`gtc.f()` 返回 `qw3` 空集——组成员不计入
  `ftc.q`，故 `A1` = 未入组散件 + 组 id = 顶层项数；一个组
  无论含多少成员只算 1 项。

## 排查结论

Harmony `SelectionOverlay` 无条件 push DUPLICATE，
`duplicateSelected` 无门槛——单元素/单组均可复制，原版不可。

## 修复

- `NoteCanvasView.ets`：新增 `@State selectionCanDuplicate`，
  在 `updateSelectionOverlay` 复用 `groupMembers`
  （`resolveOriginalGroupAuthoringMembers` = `T1(ftc.q)+组 id`
  等价集）置 `!== null && length >= 2`；`duplicateSelected`
  入口同门槛 fail-closed。
- `SelectionOverlay.ets`：新增 `@Prop canDuplicate`，
  DUPLICATE 菜单项条件 push。

## 验证

- 新增 replay `d02-original-duplicate-gate.mjs`：12/12 绿。
- 全量 desktop replay 套件：505/505 绿。
- `note@default` HAP 构建绿；`note@ohosTest` HAP 构建绿。
- ArkTS 静态检查随构建通过，无新增错误。

## 提交

`Phase 615: DUPLICATE requires >=2 top-level items (dhb case4)`
