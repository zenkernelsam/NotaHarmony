# Phase 1265 报告 — Compose 语义/无障碍

## 完成内容

- `tvc`=SemanticsProperties 键（ContentDescription/
  editableText/textSelectionRange/imeAction/…13+）；
- `ivc`=SemanticsActions 键（onClick/setText/setSelection/
  copy…）；`vvc`=33 KProperty accessor+setter；`xvc`=
  SemanticsPropertyReceiver —— TalkBack/无障碍元数据。

## 产出

- evidence `phase-1265-semantics.md`
- fixture `d02-semantics.mjs`（10/10）
- ADR-1209
