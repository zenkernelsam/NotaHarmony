# Phase 784 证据：原版 1.4.2 账号面/引导增量/权限差

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）
证据源：`decompiled_1.4.2` strings.xml + AndroidManifest.xml；
`decompiled_1.0.3` 对照。
Replay：`docs/migration/replays/d02-original-account-onboarding.mjs`
ADR：`ADR-0728-original-account-onboarding.md`

## 1. ui_account__ 26 键 = 登出面迁移新址（更正性发现）

`feature_settings__logout_*`/`sign_out` 移除键（Phase 780 登记
为重构）的落点即此族——**键名空间迁移第二实例**：

- 登出流程：`sign_out_title`/"You will need to sign back in…"
  + `sign_out_synced_text`（"All changes synced"）/
  `sign_out_unsynced_{title,text}`（未同步丢失警告）+
  `sign_out_sync_now` + `sign_out_countdown`（倒计时按钮）+
  `signing_out`/`stay_signed_in`/`sign_out_sync_failed_text`。
- 改密流程：`change_password_*` 同构（synced/unsynced 警告 +
  countdown 按钮）——**密码重置会登出本机**，未同步则丢失。
- 换号流程：`switch_account_*`——"This device is signed in to
  a different account. Signing in removes the notes already on
  this device" + `spent_link`（一次性登录链接用后即废）。

语义要点：三条流程共享**同步状态门控 UX**——未同步即
明确警告丢失，已同步方可安全继续，倒计时防误触。

## 2. data_onboarding__ +5（首用提示钉住已登记面）

- `first_angle_measure_mode` → 尺子角度读数（Phase 782）
- `first_rainbow_effect` → rainbow 笔刷包（Phase 762/778）
- `first_ruler_enabled` → 尺子开关
- `phone_undo_redo` → 手机形态撤销重做
- `save_as_template` → 自定义模板（Phase 764）

## 3. 权限与组件差

- `+uses-permission READ_CALENDAR`（配合 Phase 765 日历族）。
- 组件差仅 4 项，全部已登记：IMAGE_CAPTURE_SECURE（760）、
  ApiGatedFirebaseInitProvider（771）、HwrEngineService（768）、
  READ_CALENDAR（本阶段关联 765）。
- `com/github/luben/zstd`：zstd-jni 传递依赖（760 已登记）。

## 4. 分类结论

- 账号流程族：账号/同步后端边界（fail-closed），但其
  **同步状态门控 UX 语义**（unsynced 警告→countdown→
  spend-link 一次性）登记为 T-042 输入。
- onboarding 五键：已登记面的首用提示——数据钉住。
- Harmony 无账号面；登记版本差。
