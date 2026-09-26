# ADR-0716 — 原版 1.4.2 大纲解析管道登记为后端边界（细化 ADR-0709）

日期：2026-09-29
状态：已登记（版本差·后端边界；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-772-original-syllabus-parse.md`
Replay：`docs/migration/replays/d02-original-syllabus-parse.mjs`
上游：ADR-0708、ADR-0709（CalendarDatabase schema）

## 背景

字符串证据显示 1.4.2 大纲导入为**服务端解析**：用户经
"Choose a file/photos" 上传大纲 → 服务端抽取日期与作业
（`error_server_busy/rate_limited/timed_out/too_large/not_syllabus`
五类服务端错误态 + `parsing` 进行中态）→ "Review the course name
and dates" 复核横幅 → 写入 `syllabusCourses`/`syllabusEvents`。
`SyllabusParseException` 位于 `data/learn/syllabus/`（Learn 簇）。

## 决策

1. **细化 ADR-0709**：syllabus 四表虽本地 schema 可移植，唯一
   生产者是服务端解析——功能整体判为**后端耦合**，并入
   ADR-0708 Learn/服务端簇 fail-closed。
2. 19 个 1.4.2 新增异常类完成归簇登记；其中
   `LibraryInitTimeoutException`/`NoteOpsGoneException`/
   `PreemptedByOpenNoteException` 的**本地语义**（初始化超时上报、
   打开笔记抢占挂起）登记为可借鉴项，不承诺回移。
3. `NoteLimitRefusedException` 属订阅付费墙（ADR-0708），客户端
   抛出但上限/订阅态属后端。

## 后果

- Replay 钉住导入入口、五类服务端错误、复核横幅与异常类归属。
- T-042 输入补齐大纲功能完整边界判定。
