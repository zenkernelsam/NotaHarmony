# Phase 1436 — 连接触控笔触觉反馈轴裁定

## 背景

`com.gingerlabs.notability` 叶面包簇复核：billing/samsungbilling
（ADR-0786/0662/1113）、learn/flashcard（ADR-0652/0631）、calendar
Coming-up（strings 轴收口已裁）、transcription live+GCS upload
（ADR-0652，私有 LLM 后端）、widgets（ADR-0632）、demo
DemoResetWorker（ADR-0719/0767 零售演示重置）均已裁毕；仅剩
`data/stylus/haptic` + 关联运行时类未裁决 —— 本 Phase 裁定。

## 原版证据（decompiled_1.4.2）

### 数据面

- `iu6.java`：`hapticPreferences` DataStore，`intensity` 键
  默认 `100`（0–? 范围未界）。
- `p5h.java`：`stylusConnection` DataStore，`isConnected` 键默认 false。
- `HapticPreferencesInitializer`：androidx.startup 初始化器，
  `onCreate` 链 `iu6.c()` 预热。

### 会话与纹理

- `ou6.java`：8 触觉纹理枚举
  `{None, Ink, Pencil, Brush, Marker, ChiselMarker, Eraser, Sparkle}`。
- `nu6.java`：触觉会话管理器——`i` 字段持当前纹理；
  `c(long)` 持久化 intensity；`b()` 返回 `ju6`（设备门面，lazy）；
  `a()` 记录 "Interactive effect not supported, skipping"；
  `oha` 互斥 + `rm4` 双会话槽（j/k 字段）。
- `ygg.java`（约 :723-775）：工具 → 纹理映射——`eti` 序数
  case0/1→`ou6.G`(Ink)、case2→`ou6.H`(Pencil)、case3→`ou6.I`
  (ChiselMarker)、case5→`ou6.J`(Eraser)、其余→`ou6.F`(None)；
  经 `on4` 分发写入 `nu6.i`。
- `w32.java:70`：笔画渲染路径 gate `nu6.i == ou6.F`（无纹理时跳过
  触觉交互路径）。
- `f.java` case17：断开/会话结束 `nu6.i = ou6.F` 复位 + 设备调用容错。

### 用户面

- `yb0.java`（options 菜单）：`feature_note__options_menu_disconnect_stylus`
  项仅在连接态渲染（`z2` 门）。
- `au6.java`：`rf3` 设置分组 "Haptic"，`intensity` 读/写/重置（默认 100）。

## Harmony 侧现状

- 无任何 stylusConnection/haptic/ou6/intensity/disconnect_stylus 面；
  设置页无 Haptic 分组；工具切换链无纹理写入。
- HarmonyOS 无对应连接触控笔触觉生态：PenKit/`InkInputProvider` 仅
  输入预测（`PenKitPredictor`），无 BLE 触控笔下行触觉通道；
  `isConnected` 永假 → 菜单/设置行天然不可达。

## 裁定

**fail-closed**：硬件/厂商生态边界（与 Samsung IAP、S Pen SDK 同类）。
不虚构连接笔配对面/触觉写路径/设置行；无可达坏路径（无任何入口
可在无设备时呈现）。`disconnect_stylus` 字符串不入资源表。

## 验证

- 新增 Replay：`d02-original-stylus-haptic.mjs`（11 checks）。
- 全量基线与双 HAP：见 Report。
