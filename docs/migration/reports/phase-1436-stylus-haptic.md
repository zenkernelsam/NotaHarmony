# Phase 1436 — 连接触控笔触觉反馈轴裁定（fail-closed）

## 范围

`com.gingerlabs` 叶面包簇复核收官：其余叶子（billing/samsungbilling、
learn/flashcard、calendar、transcription、widgets、demo）此前均已裁；
本 Phase 裁定仅剩的 `data/stylus/haptic` 连接触控笔轴。

## 原版证据

- `iu6` `hapticPreferences` DataStore：intensity（默认 100）。
- `p5h` `stylusConnection` DataStore：isConnected。
- `ou6` 8 纹理 {None,Ink,Pencil,Brush,Marker,ChiselMarker,Eraser,
  Sparkle}；`ygg` 工具→纹理映射（pen→Ink、pencil→Pencil、
  chisel→ChiselMarker、eraser→Eraser、其余→None）。
- `nu6` 会话管理器（`i` 当前纹理、`c(j)` intensity 持久化、`ju6`
  设备门面下发、oha 互斥双会话槽）。
- `w32` 笔画路径 `i==None` 门控；`f.java` case17 断连复位。
- 用户面：`disconnect_stylus` 菜单项（连接态才渲染）+ `au6` "Haptic"
  设置行。

## 裁定

**fail-closed**：厂商私有连接触控笔硬件生态边界——HarmonyOS 无对应
BLE 触控笔触觉下行通道（PenKit 仅输入预测），`isConnected` 恒假使
全部入口不可达，无静默失败路径。不虚构配对/设置/纹理分发。

Harmony 侧确认零残留：无 disconnect_stylus 字符串、无 haptic 面、
无工具→纹理写入。

## 交付物

- 证据 `phase-1436-stylus-haptic.md`
- ADR-1371
- Replay `d02-original-stylus-haptic.mjs`（11 checks）
- 三追踪文档条目

## 验证

- fixture 11/11；全量基线 1287（1286+1）；双 HAP 构建成功。

## 差异登记

- 设置页无 Haptic 分组（无对应偏好，非差距）。
- 若未来出现等效连接触控笔生态，`stylusConnection`/`hapticPreferences`
  偏好模型与 `ygg` 纹理映射可再立项移植。
