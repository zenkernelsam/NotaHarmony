# Phase 713：原版 `hq9` 兄弟 datastore 键 fail-closed 登记

Phase 712 移植 `onboardingTooltipSeen` 后，`gq9` 三字段模型剩余两键
未审：`defaultNotesRolePromptSeen`（`gq9.b`）与
`sixMonthsPlusOnboardingSeenUserIds`（`gq9.c`，`hq9.java:13` 定义，
`s89` case 13/14 暴露为流）。

## 原版证据链

### `defaultNotesRolePromptSeen` → 共享笔记角色提示

- `m8.java`/`h3.java`/`ccj.java` 渲染
  `feature_library__notes_role_prompt_title`（插值角色名）/
  `notes_role_prompt_message`/`confirm`/`deny`，及确认后 info 变体
  `notes_role_info_message`/`notes_role_info_dismiss`（`gl8` 布尔切换
  双形态）。
- 角色状态源自 `SyncedNoteMetadata.shared/linkAccessLevel/
  linkPermissionScope/userAccessLevel`（`cha.java:21` schema）——
  协作同步后端产物（ADR-0513/ADR-0658 COLLAB_RTL 同族边界）。

### `sixMonthsPlusOnboardingSeenUserIds` → "6 months of Plus" 促销弹窗

- `tt8.java:74`：弹窗构建自 `ui_designsystem__six_months_plus_onboarding_
  title/description`；analytics 键 `qtb = androidSixMonthsPlusOnboarding`。
- `lq7.java:253`：`onSeenSixMonthsPlusOnboarding()` 将当前 userId 写入
  seen-set——**按账号 ID 去重**。
- `q31.java:539` 内部工具注明原文："the '6 months of Plus, on us' modal
  will show again on the next library visit (**only for an eligible promo
  subscription**)"。

## 决定

两键均 fail-closed 登记（`ADR-0661`）：

- 角色提示需共享笔记协作后端 + `userAccessLevel` 角色解析；
- 六个月促销弹窗需账号身份 + 促销订阅资格。
- Harmony 无协作后端、无账号/订阅体系，两提示永远不会 eligible——
  缺席即忠实边界行为；`notes_role_*`（6 条）与
  `six_months_plus_onboarding_*`（2 条）字符串不进入资源。

## 验证

- `d05-original-onboarding-sibling-keys-fail-closed.mjs`（318 断言：
  键/模型/字符串面/消费站点/协作字段/订阅资格/全部 ets 文件无实现/
  OnboardingTooltipStore 不含六个月键/ADR+证据）。
- 全套件重跑、双 HAP 构建通过后记录于修复总纲。
