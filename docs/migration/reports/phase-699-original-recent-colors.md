# Phase 699 — 原版最近色行（zw1/sw1/ms0/rw1.f）移植

## 范围

原版色彩面板内"Recent colors"行——持久化、7 槽、前景/高亮
面板共享。此前 Harmony 无最近色记录。

## 原版行为（证据见 phase-699 evidence）

- `mli.c` 面板恒含 `zw1`（RecentColors）项；`rw1.f` 渲染 7 槽
  最近色行（不足补透明占位）。
- `ms0`/`bhb`：最近色持久化记录 → `sw1{recentColors}`。
- 点按 recent 走与预设相同的 `ix4` 应用路径。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `@State colorRecents` + `preferences` store
    `text_color_recents`（key `recents` = JSON 数组）；
    `aboutToAppear` 异步加载。
  - `recordRecentColor`：去重前移 + `slice(0,7)` + 异步落盘；
    挂 `pickTextColor`/`toggleHighlightColor` 两入口（预设、
    Custom、recent 点按均经此）。
  - `buildColorRecentsRow` @Builder：24px 圆点行，非空才渲染，
    挂载于文字色 sheet（预设网格下）与 HSV sheet（Apply 行上）。
  - `pickRecentColor`：按 `hsvTarget` 分派前景/高亮管线；文字色
    sheet 打开时置 `hsvTarget=0` 保证分派正确。

## 验证

- Replay：`d02-original-recent-colors.mjs` 19 项全绿；
  lease-bound 计数 33→34（recent 圆点 lease 门控）。
- 构建：`note@ohosTest`/`note@default` assembleHap 成功。
- 真机/模拟器：未验证（约束内）。

## 限制

- 原版 7 槽不足位补透明占位圆——移植只渲染已有记录（更直观），
  登记差异。
- 原版最近色持久化在 DB（bhb）且与笔色板共用同一记录源；
  移植为文本色独立 store（`text_color_recents`），笔色板
  recents 不在本期范围。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `docs/migration/replays/d02-original-recent-colors.mjs`
- `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
