# Phase 1289 证据 — data/learn AI 学习特性

来源：`data/learn/{a,b,LearnError}.java` + `database/
LearnDatabase(.java+_Impl)`。

## `LearnDatabase extends x5c`（Room `RoomDatabase`）

实体表（`_Impl` 扫描）：
```
LearnJob          // 学习生成任务（in-flight AI 生成）
LearnNoteState    // 每笔记学习态
QuizOp            // 测验题目（quiz 题项 op）
QuizSession       // 测验会话
StudyItemsInfo    // 学习项集合
SummaryEntity     // AI 摘要（笔记→总结）
```

`a`/`b` = Room DAO impl；`LearnError` = 错误域。

## 语义

**"Learn" AI 学习特性** —— 笔记 → 服务端 AI 生成
`SummaryEntity`（摘要）+`QuizOp`（测验题）→
`QuizSession`/`StudyItemsInfo`/`LearnJob`/`LearnNoteState`
Room 缓存+进度 —— AI 驱动的闪卡/测验/摘要学习系统。

## Harmony 决策

Learn → Room→`relationalStore`；AI 生成依赖后端 —
— 学习特性 fail-closed（后端 AI 生成），Room 缓存
+进度语义保真。

## 产出

- fixture `d02-learn.mjs`（10 断言）。
- ADR-1233；中文报告。
