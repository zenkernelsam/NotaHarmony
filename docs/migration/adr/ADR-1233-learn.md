# ADR-1233：Learn AI 学习特性

## 状态

已接受（Phase 1289）—— **后端依赖部分 fail-closed**。

## 决策

`LearnDatabase`（Room）→ `relationalStore`；AI 摘要/
测验生成依赖后端 —— fail-closed；Room 缓存+进度
语义保真。

## 理由

`LearnDatabase extends x5c`(Room) 实体：LearnJob/
LearnNoteState/QuizOp/QuizSession/StudyItemsInfo/
SummaryEntity —— 笔记→AI 摘要+测验→学习进度的
本地缓存；生成在服务端。

## 后果

Harmony 学习 = relationalStore 缓存+进度；AI 生成
后端依赖 —— 特性部分 fail-closed。
