# Phase 616 — UNGROUP 仅 gtc 单组选区可触发（dhb case5 ftc 死路径）

## 原版证据

- `dhb.java:17655-17672`：case5（UNGROUP，dsc=5）——
  `gtc`（整个选区 = 单个组）→ `l0(gtc.a)` 成员集非空才派发
  `wsc` 解组协程并 `fvb.a()` 清选区；`ftc` 多选壳仅解析
  `H1(ftc.m)` 首组成员集后直接 `return mof.a`，**不派发
  `wsc`**——混选含单组时 UNGROUP 是死操作；`itc`/`etc`
  落不可达分支。
- 结论：原版解组门槛 = 顶层项恰为 [组id]（`gtc` 语义）。

## 排查结论

Harmony `selectionCanUngroup = selectedGroupIds.length === 1 &&
组存在 && 叶子可解析`——混选 {组+散件} 仍显示并执行解组，
原版不可。

## 修复

- `NoteCanvasView.ets` `updateSelectionOverlay`：
  `selectionCanUngroup` 改为 `groupMembers !== null &&
  length === 1 && members[0] === selectedGroupIds[0]`（保留
  组存在/叶子可解析检查）——顶层项恰为单个组 ⇔ `gtc`。
- `ungroupSelectedElements` 入口同门槛 fail-closed：
  `resolveOriginalGroupAuthoringMembers` 顶层项恰为所选组，
  否则静默返回（对应 `ftc` 死路径）。

## 验证

- 新增 replay `d02-original-ungroup-gate.mjs`：11/11 绿。
- 全量 desktop replay 套件：506/506 绿。
- `note@default` HAP 构建绿；`note@ohosTest` HAP 构建绿。
- ArkTS 静态检查随构建通过，无新增错误。
- 未启动模拟器/真机/Hypium。

## 提交

`Phase 616: UNGROUP requires a single-group selection (dhb case5 ftc dead path)`
