# ADR-0728 — 原版 1.4.2 账号面/引导/权限增量登记

日期：2026-09-29
状态：已登记（版本差+边界分层；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-784-original-account-onboarding.md`
Replay：`docs/migration/replays/d02-original-account-onboarding.mjs`

## 背景

`ui_account__` 26 键为 Phase 780 移除的 `feature_settings__logout_*`
族的落点——登出/改密/换号三流程迁至独立账号页，共享同步
状态门控 UX（unsynced 警告→countdown→spend-link）。
`data_onboarding__` +5 首用提示与 READ_CALENDAR 权限补入。

## 决策

1. 账号流程族：后端/账号边界 fail-closed；其**同步门控 UX
   语义**（三文案层级 + 倒计时 + 一次性链接）钉入证据。
2. onboarding 五键绑定已登记面（尺子/彩虹笔刷/模板/undo）。
3. READ_CALENDAR 归入 Phase 765 日历族边界。
4. 本阶段不实现。

## 后果

- 键名迁移第二实例确认（Learn 之后），T-042 更名表输入。
- Manifest 组件差至此全部登记完毕（4/4）。
