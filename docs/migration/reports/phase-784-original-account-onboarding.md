# Phase 784 — 原版 1.4.2 账号面/引导/权限增量登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-784-original-account-onboarding.md`
ADR：`ADR-0728-original-account-onboarding.md`
Replay：`d02-original-account-onboarding.mjs`（6/6）

## 本阶段做了什么

登记 `ui_account__` 26 键账号面、`data_onboarding__` +5
首用提示与 `READ_CALENDAR` 权限差。

## 发现

- ui_account__ = 登出面迁移新址（键名重组第二实例）：
  sign_out/change_password/switch_account 三流程共享
  同步门控——未同步警告丢失、已同步方放行、倒计时按钮、
  一次性 spend-link 语义。
- onboarding 五键逐一绑定已登记面（尺子角度/彩虹笔刷/
  尺子开关/手机 undo/存为模板）。
- Manifest 组件差 4/4 全部有主（IMAGE_CAPTURE/HWR/Firebase
  Provider/READ_CALENDAR）。

## 分类

- 账号流程：后端边界 fail-closed；UX 语义入 T-042。
- 其余：已登记面的配套数据。

## 验收

- Replay 6/6 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
