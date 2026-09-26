# Phase 779 — 原版 1.4.2 闪卡导入管线登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-779-original-flashcard-import.md`
ADR：`ADR-0723-original-flashcard-import.md`
Replay：`d02-original-flashcard-import.mjs`（7/7）

## 本阶段做了什么

登记 1.4.2 新增闪卡导入管线——Anki/CSV/TSV/TXT 四格式 +
双级分隔符 + 手动粘贴的完整导入面。

## 发现

- `zf5` 枚举五值；`qpl.d()` 完成请求侧序数映射。
- APKG 为本地 ZipFile 解包 + `collection.anki21b/21/2`
  白名单定位 Anki 集合库；`mub` 设 64MB 单条目上限。
- 24 键分三层：入口（anki/manual 两路）、分隔符
  （5 选项 × 2 级）、错误与配额。
- 无网络调用——纯本地管线，与 syllabus 服务端解析对照。
- quota 键对 = 订阅边界。

## 分类

- 解析管线：版本差·本地候选（迄今最高可移植性）。
- 配额门控：订阅边界 fail-closed。
- Harmony 无闪卡面；不实现。

## 验收

- Replay 7/7 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
