# Phase 790 — 原版 1.4.2 字符串尾部族合并登记（字符串面收尾）

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-790-original-key-tail.md`
ADR：`ADR-0734-original-key-tail.md`
Replay：`d02-original-key-tail.mjs`（6/6）

## 本阶段做了什么

合并登记五个尾部族，完成字符串面全量归属。

## 发现

- ui_text__：字体面板导航 + 超链接编辑 + 五条 kbd 快捷键
  a11y 标签（列表三类+字号增减）。
- toolbox：添加媒体/贴纸入口 + 手机形态 a11y。
- learn_transcription：查看器 + transcript_accurate/
  inaccurate 质量回传 + 四错误键。
- permissions：日历理由 + 锁屏相机需解锁（760 配套）。
- designsystem：beta/early_access 徽标等
  （bottom-sheet a11y 系 1.0.3 存量）。

## 验收

- Replay 6/6 绿；+722 新键全族归属完毕；全量套件与双 HAP
  随本阶段执行。
