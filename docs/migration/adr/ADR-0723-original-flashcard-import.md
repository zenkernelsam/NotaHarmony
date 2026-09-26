# ADR-0723 — 原版 1.4.2 闪卡导入管线登记

日期：2026-09-29
状态：已登记（版本差·本地候选；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-779-original-flashcard-import.md`
Replay：`docs/migration/replays/d02-original-flashcard-import.mjs`
上游：ADR-0716（syllabus 服务端解析）、Learn/订阅边界族

## 背景

1.4.2 新增完整闪卡导入管线：zf5 枚举 APKG/CSV/TSV/TXT/Other；
APKG 经本地 ZipFile 解包并定位 Anki 集合库（anki21b/21/2），
单条目 64MB 守卫；分隔符双级模型（词—定义、行间）+
手动粘贴入口；quota 门控属订阅边界。

## 决策

1. **解析管线本体**：纯本地（无网络调用）——与 Phase 772
   服务端 syllabus 解析形成鲜明对照；登记为版本差·
   本地候选，是迄今可移植性最高的 1.4.2 新功能。
2. **quota 门控**：订阅边界，fail-closed。
3. 本阶段不实现——Harmony 无闪卡面（Learn 族整体边界内）。

## 后果

- Replay 钉住枚举、anki 文件名白名单、64MB 守卫与键族。
- APKG 本地解析规格进入 T-042 输入。
