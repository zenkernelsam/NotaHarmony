# Phase 772 — 原版 1.4.2 大纲解析管道与新增异常族登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-772-original-syllabus-parse.md`
ADR：`ADR-0716-original-syllabus-parse.md`
Replay：`d02-original-syllabus-parse.mjs`（5/5）

## 本阶段做了什么

从字符串键恢复 1.4.2 大纲导入的完整 UX 链，并对两版本异常类
做全量 diff（1.4.2 新增 19 个）。

## 发现

- **大纲导入为服务端解析**：Choose file/photos → "Extracting key
  dates and assignments" → 服务端错误五态（busy/rate_limited/
  timed_out/too_large/not_syllabus）→ review banner → 写
  `syllabusCourses`/`syllabusEvents`（Phase 765 表的消费端）。
  `SyllabusParseException` 属 Learn 簇——ADR-0709 的"本地可移植"
  表述经 ADR-0716 细化为"表可移植、生产者属后端，功能整体
  后端耦合"。
- 19 个新异常类归簇完毕：认证 4、HWR 4、画廊 1（前阶段已登记）+
  SyllabusParse（本阶段）+ NoteLimitRefused（付费墙）+
  登录生命周期 2 + 快照序 2 + FirebaseLogger + 本地语义 3
  （LibraryInitTimeout/NoteOpsGone/PreemptedByOpenNote——登记为
  可借鉴语义项）。

## 验收

- Replay 5/5 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档 + ADR-0709 细化注已更新。
