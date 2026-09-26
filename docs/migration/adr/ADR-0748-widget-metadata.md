# ADR-0748：桌面小部件尺寸映射（4×2 → 2*4 平台差异）

- 状态：accepted
- 日期：2026-09-23
- 证据：`docs/migration/evidence/phase-804-widget-metadata.md`
- Replay：`docs/migration/replays/d02-widget-metadata.mjs`

## 决定

维持 Harmony `forms_config.json` 现状：5 个 form 与原版 5 个小部件
一一对应；列表型小部件默认 `2*4`（原版推荐 4×2），登记为平台网格
约束差异，不改码。

## 依据

- 原版 widget-info 两版零 delta；全部 `home_screen` + 双向 resize。
- Android `targetCellWidth×Height`：三单块部件 2×2，两列表部件 4×2。
- Harmony `formDimension` 枚举仅 `1*2/2*2/2*4/4*4`，无 4 宽×2 高
  档位——`2*4` 是可用档内最接近等价，并附 `2*2/4*4` 多档支持保持
  与原版 resizeMode 语义一致。
- 2×2 单块（create_note/create_recording/note_thumbnail）精确对齐。

## 影响

小部件元数据面关闭。唯一尺寸差异（列表型 4×2→2*4）为平台枚举
限制，功能面无损；卡片内容布局按 Phase 800 已映射的页面实现。
