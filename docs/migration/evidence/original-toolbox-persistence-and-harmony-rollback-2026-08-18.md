# 原版 Toolbox 持久模型与 Harmony 乐观回滚证据（2026-08-18）

## 基准与证据边界

- 原版基准：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- `e47.java` SHA-256：`54F175BFB7A5C881A46166D241E26668278539C317D075C9BDEE6D6A79BA8467`
- `cha.java` SHA-256：`04F9DC3D1CC88E57AE9252BF8ADBDAF1A67D199102D9090757C8F3F4374F64F7`
- `vb4.java` SHA-256：`B5C6D5DC167331CB10218F087B835AF296B04431B2B61739CEA9D1F06A343D23`
- `na4.java` SHA-256：`CBF89F4D56DB166A5423809D11A4EFD02CE54E4C2606CF306E5EBA4DAE44C68E`
- `f7f.java` SHA-256：`C99CFE73E9895AFA7A6682B41832968AA995A544FA3FA36B51507C9D481D64F0`
- `i8f.java` SHA-256：`36B5E3E4838B39E319FFEE8CE7050965511231F2AE9A5B2D1C000FE125DCE3A5`

原版证据能确定“ToolState 与 Toolbox 是独立、可观察、持久的数据库实体”，但不能直接给出 Harmony
`EditorViewModel` 的 JavaScript Promise 队列、乐观 UI 与失败交错规则。Phase 268 的 committed snapshot、版本门和
迟到完成防护属于 Harmony 平台适配；本文件明确分开原版事实与移植侧一致性决策。

## 1. 原版按工具持久化完整状态

`e47.java:376-382` 建立 Toolbox 数据库：

- `TrayEntity` 属于一个 `ToolboxEntity`；
- `ToolStateEntity` 以 `tool_id` 为主键，并保存 `toolType`、`trayIndex`、color、width、style、选中色/宽 well、
  `selectionIsFreehand` 与 `eraserIsPartial`；
- `ToolboxEntity` 独立保存 `mostRecentlySelectedToolId` 和 `previouslySelectedToolId`。

`f7f.java:102-121` 又从 `ToolStateEntity` 逐列读取上述字段，并按 `tray_owner_id` 组装每个 tray 的工具列表。由此可知
Pen、Pencil、Highlighter、Eraser 和 Selection 不是一份共享临时 brush 状态，最近/上一个工具也不是由 UI 临时推断。

## 2. ToolState 与 Toolbox 写入具有明确数据库失败边界

- `cha.java:23` 使用 `UPDATE OR ABORT ToolStateEntity`，单个工具状态更新发生约束冲突时不能静默改写为成功；
- `vb4.java:33` 提供独立 `DELETE FROM ToolStateEntity WHERE tool_id = ?`；
- `vb4.java:35` 使用 `UPDATE OR ABORT ToolboxEntity` 更新最近/上一个工具；
- `na4.java:599` 使用 `INSERT OR REPLACE ToolboxEntity` 建立或替换 toolbox identity；
- `f7f.java:207-209` 通过 Room transaction helper 更新 `ToolboxEntity`。

这些证据要求 Harmony 不得在仓储写失败后继续把未确认的 UI 值当成已持久状态。原版 DAO 的 ABORT/transaction
边界并不等于“UI 自动回滚到上一次函数调用前的值”；Harmony 必须自行区分最后确认值与仍在队列中的乐观值。

## 3. 原版通过数据库观察发布完整 Toolbox

`i8f.java:40` 对 `ToolStateEntity`、`TrayEntity`、`ToolboxEntity` 三表建立同一观察链，说明可见工具模型来自数据库
实体组合，而不是只观察当前按钮字段。`i8f.java:266-280` 在切回 previous tool 时先取得当前完整 toolbox；若不存在，
记录 `No toolbox found when trying to switch back to previous tool` 并停止，不会伪造一个 previous identity。

因此 Harmony 的失败恢复应回到最后确认的 `EditorToolboxState`；连续选择 A、B 均失败时，不能恢复到 A 的乐观
临时值，也不能因回滚把 generation 倒退后让迟到的旧操作再次通过。

## 4. Phase 268 重放出的 Harmony 竞态

旧 `EditorViewModel` 只有“本次调用前快照”而没有 committed snapshot，产生四类可确定错误：

| 交错 | 旧行为 | 正确持久前缀 |
|---|---|---|
| 黑色→红色失败，随后蓝色失败 | 第二次恢复红色 | 两次均未写成，应恢复黑色 |
| Pen→Pencil 失败，随后 Highlighter 失败 | 第二次恢复未确认的 Pencil | 两次 toolbox 写均失败，应恢复 Pen |
| Shapes true→false 失败，随后 true 失败 | 第二次恢复 false | 两次均失败，应恢复已确认 true |
| Partial Eraser 模式写等待期间选择 Pencil | 擦除写失败会无条件恢复旧选择；成功也会继续 `applyActiveState()` 重激活 Eraser | 新选择 generation 必须独占最终 UI/toolbox 发布 |
| 旧保存等待期间同一 ViewModel 再次初始化 | 先读旧数据库快照，旧保存随后落盘 | 初始化必须先等待已有保存尾部，再读取 repository |

旧选择失败还执行 `selectionVersion = oldSelectionVersion`。generation 因此不再单调，已经迟到的旧 continuation
存在重新命中相同版本值的可能。

## 5. Harmony 适配结论

- 工具状态、Toolbox 和 Shapes preference 各维护最后一次真正写成功的 committed snapshot；
- 每个成功队列项都推进已持久前缀，即使界面上已经有更新的乐观值；
- 失败只有在自己的 version 仍为最新时才发布回滚，目标是当前 committed snapshot，而不是调用前可能同样未确认的值；
- version 只递增，不在回滚时恢复旧数字；
- 擦除选择在等待模式写入后再次检查 selection version。若已被新选择取代，无论模式写成功或失败，都不能再发布旧
  active tool，也不能写旧 toolbox snapshot；
- `initialize()` 先置 loading，再等待当前 `saveChain`。同一 ViewModel 生命周期重入时，旧写不会在新读取之后落盘；
- 原版 Room 模型是持久实体权威；上述 Promise/版本语义是为 Harmony 异步 UI 保持同一权威而建立的适配契约，不能标成
  Android 原版逐行算法。

## 验证边界

`EditorViewModel.test.ets` 使用可控 deferred repository 覆盖工具状态三种双写结果、Toolbox 连续失败/前缀成功、
擦除模式迟到成功与失败，以及 Shapes preference 连续失败/前缀成功。桌面专项 Replay 同时执行独立队列模型并静态锁定
生产门禁，并覆盖 save-before-reinitialize 顺序。仍需设备验证 toast、快速连续点击手感、编辑器离开时 flush、重启恢复和真实数据库/Preferences 故障注入；
HAP 编译不冒充 Hypium 已在设备执行。
