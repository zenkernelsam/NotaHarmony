# ADR-0732 — 原版 1.4.2 笔记上限售卖页与测验讲题/计分面登记

日期：2026-09-29
状态：已登记（fail-closed/边界分层；无源码变更）
证据：`docs/migration/evidence/phase-788-original-paywall-quiz-delta.md`
Replay：`docs/migration/replays/d02-original-paywall-quiz-delta.mjs`

## 背景

`feature_paywall__` +14 = note_limit_offer 付费墙弹页
（触达→卖点→升级→dismiss 全链）；`feature_learn_quiz__`
+27 = explain 讲题桥（10 键）+ 计分反馈标签 +
caught_up 追平收尾。

## 决策

1. 付费墙族：订阅边界 fail-closed；卖点与触发语义入 T-042。
2. explain 讲题桥：AI 后端边界。
3. 计分标签/caught_up：随 Learn 族登记。
4. 本阶段不实现。

## 后果

- `feature_paywall__`/`feature_learn_quiz__` 差集闭合。
- 订阅门控的文案规格进入 T-042 输入。
