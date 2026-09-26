# Phase 787 — 原版 1.4.2 库主页增量登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-787-original-library-home-delta.md`
ADR：`ADR-0731-original-library-home-delta.md`
Replay：`d02-original-library-home-delta.mjs`（7/7）

## 本阶段做了什么

对 `feature_library__` +57 差集（扣 flashcard 族）逐族归属。

## 发现

- Coming-Up 主页区块十键——日历事件即将提醒面
  （765 日历族 UI 侧，后端/权限边界）。
- 考试复习区块（upcoming_exams/exam_review/tomorrow）。
- **滑动删除/收藏三键为真·未移植 UX 差**——Harmony 库页
  无 swipeAction（本地可移植，回移评审待定）。
- 视图切换 a11y、多选标签、封面/计划本/learn 入口配套。

## 分类

- Coming-Up/考试：后端边界。
- 滑动操作：版本差·本地候选。
- a11y 增量：版本差。

## 验收

- Replay 7/7 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
