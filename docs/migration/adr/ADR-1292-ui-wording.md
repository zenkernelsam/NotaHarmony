# ADR-1292：UI 文案保真

## 状态

已接受（Phase 1351）。

## 决策

UI 文案 = 原版 `strings.xml` **逐字节保真**（用户可见
串）；卡描述（无障碍）串近似。

## 理由

`string.json`（~915）对照 `strings.xml`：全部 widget/
库/编辑器用户可见串（"Tap to open Notability"/"No notes
in this folder"/"Choose a note"/"Start recording"/"Recent
Notes" 等）**逐字节一致**；仅 `*_desc` 无障碍描述近似
（"Show your recent notes." vs "Quick access to…"）。

## 后果

用户所见文案与原版逐字节一致 —— UI wording 保真目标
达成；无障碍描述近似为文档化差异。
