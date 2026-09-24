# ADR-0645 — 选区菜单 `dsc` 全表对账（CONVERT_*/FIT_TO_PAGE/MORE fail-closed）

- 状态：Accepted
- Phase 678；对齐 `dsc`（decompiled_1.0.3 `dsc.java:30-74`）、
  `dhb` case13 派发（17696-18060）、`msc`/`esc` 双行结构、
  `ux9` 菜单渲染与 `xsc.p()` 后端门禁。

## 背景

原版选区菜单动作枚举 `dsc` 共 22 项。Harmony
`SelectionMenuAction` 覆盖 18 项 + 3 项 Harmony 特有
（PASTE/DESELECT_CONFIRM/CANCEL），LOCK 已按 ADR-0586 合并
UNLOCK 为开关。遗留 4 项需逐一定性：

- `CONVERT_TO_MATH`（11）/`CONVERT_TO_TEXT`（12）：`dhb` 派发
  先 `xsc.p()` 探测 `j4e` 转换后端（MyScript iink 会话
  `tqd`），再过 `ba6.o` 页面门禁、`xsc.v` 跨页校验，最终由
  `com.myscript.iink` SDK 识别替换选区。
- `FIT_TO_PAGE`（15）：`dhb:17985` `throw new
  NotImplementedError(0)`——1.0.3 死桩，点击即抛。
- `MORE`（21）：仅翻转 `msc.b`（`esc` 双行 options 的
  showSubmenu），属原版两行菜单 UI 结构。

## 决策

1. **CONVERT_* 不渲染**：HarmonyOS 无 MyScript iink 等价物，
   `OriginalHandwritingRecognitionProvider` 无生产实现。原版
   `xsc.p()` 后端不可用时本就不显示转换项——Harmony 缺省与
   其 fail-closed 语义一致，不虚构死按钮。
2. **FIT_TO_PAGE 不补**：原版即 NotImplementedError 桩，
   无行为可对齐。
3. **MORE 不补**：`SelectionOverlay` 单行 `bindMenu` 全量列出
   为已注册适配；补 MORE 需要虚构双行结构，收益为零。
4. `SelectionOverlay.ets` 菜单注释更新为全表口径并引用本 ADR。
5. `OriginalHandwritingConversionCoordinator` 保留为接入点：
   未来若有 OCR 提供方，按 `dhb` case12 管线（选区笔画 →
   跨页校验 → 识别 → 文本块替换）接入即可恢复
   CONVERT_TO_TEXT；CONVERT_TO_MATH 需另建数学识别器。

## 后果

- 菜单行为与原版在「后端不可用」场景等价；无新增代码路径。
- Replay fixture `d02-original-selection-menu-dsc-reconcile.mjs`
  锚定枚举、死桩、双行结构与 Harmony 缺省口径。

## 验证

- 专用 fixture 43/43；全量 Desktop Replay 562/562（FAIL=0）。
- `note@ohosTest` clean + `note@default` 双 HAP `BUILD SUCCESSFUL`。
- 无设备/模拟器/Hypium 运行时验证。
