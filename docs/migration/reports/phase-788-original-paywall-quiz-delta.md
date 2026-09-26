# Phase 788 — 原版 1.4.2 售卖页与测验讲题/计分面登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-788-original-paywall-quiz-delta.md`
ADR：`ADR-0732-original-paywall-quiz-delta.md`
Replay：`d02-original-paywall-quiz-delta.mjs`（5/5）

## 本阶段做了什么

归属 `feature_paywall__` +14 与 `feature_learn_quiz__` +27
两个差集。

## 发现

- note_limit_offer：笔记上限触达→卖点（audio_quizzes/
  handwriting_search）→升级/看全部计划/暂不免的全链弹页；
  平级 `restore_subscribed_elsewhere`。
- explain_* 十键：测验题→聊天讲解桥（AI 后端）。
- 计分标签（correct/incorrect/skipped/your_answer）+
  caught_up 追平收尾与 Phase 785 计分列呼应。

## 分类

- 付费墙/讲题桥：订阅与 AI 后端边界 fail-closed。
- 计分标签族：随 Learn 边界登记。

## 验收

- Replay 5/5 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
