# ADR-0246：编辑器乐观持久化的 committed boundary

## 状态

Accepted - Phase 268（2026-08-18）

## 背景

原版 1.0.3 将每个 `ToolStateEntity` 与 `ToolboxEntity` 分开持久化，并由 Room 同时观察 ToolState、Tray 和
Toolbox。Harmony 的 `EditorViewModel` 为保持 ArkUI 即时反馈，先改界面，再把 ToolState、Toolbox 与独立
Shapes preference 串入 Promise 保存队列。

旧实现用“本次调用前的乐观值”作为失败回滚目标。这只在单次失败时成立，连续交错会破坏数据库权威：

- A、B 两次工具状态写均失败，B 恢复到同样失败的 A；
- A、B 两次工具选择写均失败，B 恢复到未持久的 A；
- Shapes preference 有同样问题；
- Partial/Whole Eraser 在等待模式写入时若用户选择新工具，迟到失败会无条件覆盖新选择，迟到成功也会继续
  `applyActiveState()` 把旧 Eraser 重新激活；
- selection failure 把 generation 重置为旧值，破坏“迟到 continuation 只能失效”的单调门。
- 同一 ViewModel 在旧保存仍 pending 时再次 `initialize()`，会先读取旧数据库快照，随后旧写落盘，使 UI 与 repository
  在重入后立即分叉。

原版数据库证据及 Harmony 边界见
`docs/migration/evidence/original-toolbox-persistence-and-harmony-rollback-2026-08-18.md`。

## 决策

### 可见值与确认值分层

- `states`、active/previous tool 和 `shapeDetectionEnabled` 继续承担乐观可见值；
- `committedStates`、`committedToolbox`、`committedShapeDetectionEnabled` 保存各域最后一次成功写入的快照；
- 初始化成功后从实际加载/补全结果建立 committed baseline；加载失败 fallback 也建立确定性本地 baseline，避免后续
  失败回滚到未定义状态。

### 串行队列的持久前缀

- 保存仍使用单一 FIFO `saveChain`，因此成功项构成一个明确的持久前缀；
- 每个写成功后都更新对应 committed snapshot，即使它完成时 UI 已经存在更新 version；
- 旧失败不得改 committed snapshot；若该失败仍是最新 version，则 UI 回到当前持久前缀；若已有更新 version，失败只
  报错，不覆盖后续可见值。

该规则覆盖三种关键顺序：A/B 都失败回到初值；A 失败 B 成功保留 B；A 成功 B 失败回到 A。

### 单调 generation

- ToolState 继续按 tool ID 维护独立 version；Shapes preference 新增独立 version；Toolbox 使用 selection version；
- 所有 version 只递增，失败恢复状态时不得恢复旧 version；
- 因此一次 continuation 失效后不会因另一次回滚把数值倒退而重新获得发布资格。

### Eraser 的两阶段选择

Partial/Whole Eraser 选择先持久化共享 Eraser ToolState 中的 `eraserIsPartial`，再保存 Toolbox selection。模式写
是一次 `await` 边界，因此返回后必须再次检查 selection version：

- 模式失败且选择仍最新：恢复 committed Toolbox；
- 模式失败但已有新选择：不触碰新选择；
- 模式成功但已有新选择：保留已成功的 Eraser mode，但不再 apply/persist 旧 Eraser selection；
- 只有 version 仍匹配时才发布 active state 并进入 Toolbox 保存。

### 生命周期重入顺序

- `initialize()` 立即进入 loading，并先等待现有 `saveChain`；
- 旧调用的成功/失败 continuation 完成后，才替换 repository、清理 version/committed baseline 并重新读取数据库；
- 因而不会出现“先加载旧值、后完成旧写”的 read-after-pending-write 反序。

## 后果

- 连续失败不会让 UI 与数据库停在一个从未写成功的中间值；
- 前一个成功、后一个失败时能准确恢复持久前缀，而不是恢复调用栈快照；
- 擦除模式的迟到成功/失败均不能覆盖用户后续选择；
- 原版 ToolState/Toolbox 的持久实体权威在 Harmony 乐观 UI 中得到保持；
- committed snapshot 是 ViewModel 内存副本，不改变 Repository 接口或数据库 schema。

## 验证契约

- `EditorViewModel.test.ets` 使用 deferred fake 覆盖：
  - ToolState 双失败、先失败后成功、先成功后失败；
  - Toolbox 双失败、先成功后失败；
  - Eraser mode 迟到失败与迟到成功期间的新工具选择；
  - Shapes preference 双失败与先成功后失败；
  - pending ToolState save 完成后才允许同一 ViewModel reinitialize；
- `d02-editor-tool-state-rollback-concurrency.mjs` 执行独立 FIFO/committed-prefix 模型，并静态核验生产与 fixture；
- `note@ohosTest` 证明 fixture 可通过 ArkTS 编译/打包，但不冒充设备执行 Hypium assertions。

## 边界

- 本 ADR 不改变原版 ToolState 字段、toolbox history 产品语义或 SettingsPage 的 saveBusy UI；
- toast 显示、用户连续点击观感、离开编辑器 flush、真实 RDB/Preferences 故障、重启恢复仍需设备任务验证；
- 未启动设备、模拟器、虚拟机、真机或 Hypium。
