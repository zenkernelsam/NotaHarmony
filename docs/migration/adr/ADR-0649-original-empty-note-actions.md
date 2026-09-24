# ADR-0649 — 原版 u49/mw3 空笔记动作面（Record/Import/Scan/Capture）

## 状态

已接受（Phase 682）。

## 背景

P680（ADR-0647）移植资料库「+」Document Scan 时登记了第二处扫描入口：
`u49.java`/`mw3.java` 空笔记动作面——笔记无内容时显示
Record/Import/Scan(ac4.a0)/Capture 四动作卡，结果全部作用于**当前**笔记。

## 决定

完整移植该表面（非 fail-closed）：

- 空判定：`page_element_snapshot` 元素总数为 0（与 d05 页面总览同一
  数据源）；异步评估，失败 fail-closed 不显示。
- Scan 卡：`canIUse(SystemCapability.AI.Component.DocScan)` 等价
  `lc4.a(ac4.a0)`；VisionKit `DocumentScanner` 全屏 cover，配置与
  P680 同一契约（DOC/PDF/50 页/不可分享）。
- Capture 卡：原版仅当相机回调存在时显示；Harmony 编辑器相机入口
  恒可用 → 恒显示，等价语义。
- 导入语义：Scan/Capture/Import 均并入当前笔记
  （`importPickedFilesIntoNote` / `cameraCaptureSignal` / 既有
  `importFileIntoCurrentNote`），不复用 P680 的建新笔记路径。

## 有界差异

| 项 | 原版 | Harmony | 影响 |
|----|------|---------|------|
| 卡面样式 | `p40.b` 图标+标签 | `CreateActionChip` 文本风格 | 视觉差异，无功能影响；媒体图标资源未建 |
| `scan_failed` 文案 | 含「Google Play services 需更新」 | 「请重试」 | GMS 专属提示不可移植 |
| 空判定时机 | 会话内模型为空 | 持久化快照总数为 0（异步） | 语义等价，评估点略晚 |

## 验证

- `docs/migration/replays/d02-original-empty-note-actions.mjs`：39 项
  断言（原版 mw3/u49/strings 证据钉 + Harmony 表面/门控/管线/刷新钉）。
- 全量 Desktop Replay 565+1 全绿；`note@ohosTest`/`note@default` 双 HAP
  clean。
- 未做真机/模拟器验证（遵循约束）；DocScan 实机行为沿用 P680 登记的
  待验证项。
