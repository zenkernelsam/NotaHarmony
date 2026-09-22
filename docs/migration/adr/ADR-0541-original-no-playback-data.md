# ADR-0541：原版“无回放数据”空态文案对齐

## 状态

已实施（Phase 570）

## 背景

Harmony `RecordingPanel` 在录音已选中但时间线无可用数据
（`timelineUiAsset` 缺失 / `loadState == FAILED` / segments 为空）时，
此前仍渲染一个禁用的 `0:00` 滑块加时间行——视觉上暗示“录音时长为 0”，
与原版行为不符。

## 原版行为（decompiled_1.0.3 证据）

`faj.java`：回放面板根据时间线状态分支渲染——

- 空变体 `jpa.a`：渲染 `feature_note_toolbox__no_playback_data_available`
  占位文案（"No playback data available"），不渲染播放器控件。
- 数据变体 `kpa`：渲染滑块、时间戳、±10s 跳转、倍速控件。

## 决策

在 `RecordingPanel.ets` 时间线块按 `cumulativeDurationMs <= 0` 分支：

- 空态：仅渲染居中的 `no_playback_data_available` 占位文案
  （textSecondary 次要色），不渲染滑块、时间行、±10s 按钮。
- 数据态：渲染滑块 + 时间行（原有 Phase 569 的 ±10s 控件保留在数据态）。
- 倍速行保持原位置（原版证据未单独区分倍速控件的空态归属；占位文案
  替代的是滑块区域本身）。
- 新增 `no_playback_data_available` 资源（EN 逐字 / zh 本地化）。

## 差异

- 无行为差异；倍速行归属为保守保留（原版空态面板的倍速控件归属无单独
  证据，占位文案本身已忠实替代滑块）。

## 验证

- `docs/migration/replays/d02-original-no-playback-data.mjs`：10 断言。
- 全套回放 465/465；`note@default` + `note@ohosTest` 构建成功。
