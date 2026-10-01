# ADR-1371：连接触控笔触觉反馈轴 fail-closed

## 状态

Accepted — 2026-09（Phase 1436）

## 背景

原版含完整的"连接触控笔"触觉反馈功能（haptic stylus，BLE/厂商私有
通道）：

- `p5h` `stylusConnection` DataStore：`isConnected` 连接态。
- `iu6` `hapticPreferences` DataStore：`intensity`（默认 100）+
  `au6` "Haptic" 设置分组读写/重置。
- `ou6` 8 触觉纹理 `{None,Ink,Pencil,Brush,Marker,ChiselMarker,
  Eraser,Sparkle}`；`ygg` 把工具（`eti`）映射到纹理（pen→Ink、
  pencil→Pencil、chisel→ChiselMarker、eraser→Eraser、其余→None），
  `on4` 分发进 `nu6.i`。
- `nu6` 会话管理器经 `ju6` 设备门面向笔下发纹理；`w32:70` 笔画路径
  按 `i==None` 门控触觉交互；断连 `f.java` case17 复位 None。
- 用户面仅：`feature_note__options_menu_disconnect_stylus` 菜单项
  （连接态才渲染）+ 设置 Haptic/intensity 行。

证据：`docs/migration/evidence/phase-1436-stylus-haptic.md`。

## 决定

**fail-closed，不实现**。理由：

1. 功能驱动源是厂商私有连接触控笔硬件（BLE 下行触觉通道）；HarmonyOS
   无对应硬件生态与 API（PenKit 仅输入预测，无触觉下行通路），
   `isConnected` 在 Harmony 侧恒假。
2. 入口全部连接态门控（`disconnect_stylus` 菜单项仅 `isConnected`
   时渲染；设置 Haptic 行服务笔会话）——不实现即天然不可达，
   无静默失败/坏路径。
3. 不虚构配对界面、不写假触觉通路、不注册 `disconnect_stylus` 字符串。

## 已知差异

- 设置页无 "Haptic" 分组（Harmony 无对应偏好，非差距）。
- 工具切换无触觉纹理分发（无硬件消费者）。
- 若未来 Harmony 生态出现等效连接触控笔，可重新立项：
  `stylusConnection`/`hapticPreferences` 两个偏好模型与 `ygg`
  工具→纹理映射是可移植的纯软件语义。

## 验证

- `d02-original-stylus-haptic.mjs`：11 checks 全绿。
- 基线与构建：见 `reports/phase-1436-stylus-haptic.md`。

## 交叉引用

- ADR-0767/0719（worker/leaf 包族裁定，DemoResetWorker 同边界）
- ADR-0652（transcription/learn 后端面）
- 证据：`phase-1436-stylus-haptic.md`
