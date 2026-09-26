# Phase 788 证据：原版 1.4.2 笔记上限售卖页 + 测验讲题/计分面

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）
证据源：`decompiled_1.4.2` strings.xml（`feature_paywall__*` +14、
`feature_learn_quiz__*` +27）。
Replay：`docs/migration/replays/d02-original-paywall-quiz-delta.mjs`
ADR：`ADR-0732-original-paywall-quiz-delta.md`

## 1. note_limit_offer 售卖页（14 键，订阅边界）

`reached`（触发文案）/`unlock_heading`/`plan_name`/
`feature_audio_quizzes`/`feature_handwriting_search`（卖点列举）/
`cta_upgrade`/`see_all_plans`/`not_now`/`cd_close`/`badge`/
`intro_terms`/`bare_terms`/`reassurance`——免费层笔记上限
触达后的付费墙弹页；另有平级键 `feature_paywall__restore_
subscribed_elsewhere`。卖点为
AI 测验与手写搜索；配 `data.library.state.notelimit` 包
（Phase 772 已关联）。

## 2. 测验面 +27（Learn 族内）

- **讲题桥（explain_*，10 键）**：`explain_this`/
  `explain_prompt_{expand,topics,tutor}`/生成态
  `explain_generating`/答-题-解-问四标题
  `explain_chat_heading_{answer,explanation,question,request}`/
  `explain_continue_with_chat`/`explain_close`——
  测验题→聊天讲解的 AI 桥（后端）。
- **计分反馈标签**：`correct`/`incorrect`/`skipped`/
  `your_answer`/`open_note`——与 Phase 785 的四计分列联动。
- **追平态（caught_up_*）**：`caught_up_{header,body,
  continue_to_quiz,exit_session}` + `all`——间隔重复
  复习"已追平"会话收尾面。
- `flashcard_onboarding_*`（Phase 779 已登记）。

## 3. 分类结论

- note_limit_offer：订阅付费墙——fail-closed；其卖点列举
  与触发语义入 T-042。
- explain_* 讲题桥：AI 后端边界。
- 计分标签/caught_up：Learn 族内 UX——边界随族登记。
- Harmony 无对应面；不实现。
