# ADR-0734 — 原版 1.4.2 字符串尾部族合并登记（字符串面收尾）

日期：2026-09-29
状态：已登记（版本差/边界分层；无源码变更）
证据：`docs/migration/evidence/phase-790-original-key-tail.md`
Replay：`docs/migration/replays/d02-original-key-tail.mjs`

## 背景

五个尾部族合并登记：ui_text__（字体面板/超链接/快捷键 a11y）、
toolbox（媒体/贴纸入口+手机 a11y）、learn_transcription
（查看器+质量回传+错误键）、permissions（日历理由+锁屏相机）、
designsystem（beta/early_access 徽标等）。

## 决策

- 快捷键标签/bottom-sheet/徽标：本地小增量版本差。
- 转写反馈/权限理由：随 Learn/日历边界族。
- 无独立新功能面；字符串面收尾。

## 后果

- `feature_*`/`ui_*`/`data_*` 全部 +722 新键归属完毕。
