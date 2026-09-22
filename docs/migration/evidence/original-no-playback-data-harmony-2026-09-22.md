# 原版“无回放数据”占位文案对齐证据（Phase 570）

## 原版证据

- 类：`faj.java`（录音回放面板 UI 组装）
- 资源：`feature_note_toolbox__no_playback_data_available` = **"No playback data available"**
- 关键逻辑：回放时间线状态为 `jpa.a`（空变体，无 timeline 数据）时，渲染
  `feature_note_toolbox__no_playback_data_available` 占位文案；数据存在变体
  （`kpa`）才渲染播放器控件（滑块、时间戳、±10s 跳转、倍速等）。

即：原版在录音存在但时间线数据不可用（缺失/损坏/空的 operation-audio
asset）时，**不会**渲染一个禁用的 `0:00` 滑块，而是显示占位文案。

## Harmony 落地

`note/src/main/ets/ui/editor/RecordingPanel.ets` 时间线块改为条件渲染：

```ts
if (this.cumulativeDurationMs <= 0) {
  Text($r('app.string.no_playback_data_available'))
    .fontSize(12).fontColor(textSecondary)
    .width('100%').textAlign(TextAlign.Center)
} else {
  Slider(...)
  Row() { // 当前时间、±10s、总时长 }
}
```

- `cumulativeDurationMs <= 0` 覆盖：已选中录音但 `timelineUiAsset` 缺失、
  `loadState == FAILED` 或 segments 为空 → 显示占位文案。
- 时间行（当前时间、±10s 跳转、总时长）移入 else 分支——空状态只显示占位
  文案，不显示 `0:00` / 跳转按钮，与原版一致。
- 倍速行保持原有位置（原版倍速控件在空态时随播放器整体隐藏与否无独立证据；
  保留现有布局，占位文案替代滑块本身）。
- 新增资源：
  - EN `no_playback_data_available` = "No playback data available"（逐字）
  - zh `no_playback_data_available` = "无可用的回放数据"

## 回放

- `docs/migration/replays/d02-original-no-playback-data.mjs` — 10 项断言
  （字符串逐字、空分支结构、滑块/时间行归属 else 分支、seek 钳位不变）。

## 验证

- 聚焦回放通过（10/10）
- 全套回放 465/465
- `note@default` / `note@ohosTest` HAP 构建成功
