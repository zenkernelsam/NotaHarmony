# Phase 1349 证据 — 单元测试套件

来源：`note/src/test/*.test.ets`（121 文件）+
`note/src/ohosTest/ets/test/List.test.ets`。

## `note/src/test/` = 121 个单元测试

覆盖全部已审计内部子系统：

```
Asset*/Backup*/BinaryPlistParser/AsyncMutex/
CanvasViewport/CubicFitter/ForceSmoother/EraserEngine/
DirtyRectTracker/EditorViewModel/FolderRepository/
IncomingOperationSyncCoordinator/LatestWriteQueue/
MathBlockGeometry/MathCanvasRenderer/NSKeyedArchiver/
NotabilitySessionParser/OperationCompaction/OpStore/
Original*（AudioLinkedInk/BlankNote/ClipboardImage/…）
```

→ 每核心模块均有对应 `.test.ets` —— 算法/CRDT/
持久化/解析/橡皮/录音等的真单元测试。

## 注册状态

```
ohosTest/ets/test/List.test.ets:
  import abilityTest from './Ability.test';
  testsuite() { abilityTest(); }  // 仅注册占位符
```

→ 121 个 `src/test/` 测试**未注册进** ohosTest runner —
— `List.test` 仅挂占位 `abilityTest()`。属 Hypium 设备
测试，需真机运行（用户明确禁止启动模拟器/真机），故
为休眠参考测试；不阻塞 build（`src/test` 非 `ohosTest`）。

## Harmony 决策

单元测试 = 121 个 per-module `.test.ets` 休眠参考套件
（Hypium 设备运行被禁）—— 测试覆盖存在但依赖设备。

## 产出

- fixture `d02-test-suite.mjs`（10 断言）。
- ADR-1291；中文报告。
