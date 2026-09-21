# ADR-0506：原版三托盘工具箱自定义——tray_type 列 + editor_tray 表 + 结构化托盘操作

- 状态：已接受（2026-09-22，Phase 534）
- 背景：原版 ToolboxDatabase 为 `ToolboxEntity → TrayEntity → ToolStateEntity`
  三层模型（e47/cha）：托盘类型 `cgf` = Primary(0)/Secondary(1)/Hidden(2)，
  工具可见性 = 托盘成员关系，`tool_id ≠ toolType` 支持同类型多实例。设置页
  （o6f/ti9）提供隐藏/显示/排序/删除（守卫）/复制/上限/恢复默认；写路径为
  `i8f.a`（跨托盘致密重编号移动）、`x7f`（隐藏到 Hidden 尾 + 仅删重复实例）、
  `wb4`（显示回 Primary<12 否则 Secondary）、`d8f`（清表重播种）。Harmony
  此前为单托盘扁平 6 工具硬编码渲染，无任何自定义面。

## 决策

1. 复用 `tool_state` 表新增 `tray_type INTEGER NOT NULL DEFAULT 0`（版本
   68→69）；`tray_owner_id` 保持 toolbox 所有者语义（原版是 TrayEntity
   外键），成员关系由 `tray_type + tray_index` 表达，可见性 =
   `tray_type != Hidden`（cgf/x6f 对应）。
2. 新表 `editor_tray(tray_id, tray_type, toolbox_owner_id,
   last_used_tool_id)`，复合主键 `(tray_id, toolbox_owner_id)` 对齐
   TrayEntity 且按所有者作用域（原版 id 全局 int）；v69 迁移对每个已存
   toolbox 所有者 INSERT OR IGNORE 播种托盘 0/1/2（gr7/ba8 对应）。
3. 仓储层提供结构化原语：`moveToolToTray`（i8f.a：源托盘致密重编号 +
   钳位插入 + 目标托盘致密重编号，单事务）、`insertToolStateAt`、
   `deleteToolState` 附同源托盘重编号、`deleteAllToolStates`（d8f 清
   tool_state+editor_tray+editor_toolbox_state）、`ensureTrays`、
   `setTrayLastUsedTool`（i8f.g）。`saveToolStates` 修正为按 tray_type
   分组致密编号（此前 flat-index 对多托盘列表会产生非致密编号）。
4. VM 暴露 `toolStates` + `visibleToolStates()/hiddenToolStates()`；
   `hideTool`→Hidden 尾、`showTool`→Primary<12 末尾否则 Secondary 末尾
   （wb4）、`moveToolToIndex`（i8f.a）、`duplicateTool`→唯一 id 相邻插入
   （trayIndex+1，`on(17)` 主体不可反编译，位置登记为推断）、
   `deleteTool`/`canDeleteTool`→可见实例 ≤1 拒绝（x7f）、
   `resetToolsToDefaults`→清表重播种。`runStructuralOp` 深拷贝快照、
   持久化失败整体回滚；`fixActiveToolAfterStructuralOp` 保证活动工具
   不落 Hidden/被删。
5. 工具选择按行进行（`selectToolById`）：tool_id 级选中支持重复实例，
   行自身 `eraserIsPartial`/`selectionIsFreehand` 经 `applyActiveState`
   生效——每个实例携带独立模式位；Hidden 行不可选。
6. UI：`EditorToolbar` 硬编码按钮 → `ForEach(visibleToolStates())` 动态
   渲染，WHOLE_ERASER 行渲染双模式按钮，⚙ 入口 `bindSheet` 打开
   `ToolboxSettingsDialog`（o6f 对应：排序 ▲▼ + ⋯ 菜单换托盘/隐藏/复制/
   删除、Hidden 分区显示、12 上限提示、恢复默认）；资源名沿用原版
   （hidden_tools/reset_to_default/show_tool…）。

## 理由

- 原版字符串（hidden_tools/settings_hide_tool/settings_show_tool/
  settings_duplicate_tool/settings_delete_tool/settings_reorder_tool/
  reset_to_default）+ o94 行菜单 + ti9 事件管线证明这是完整的用户级功能，
  不是死 schema——P1 功能差距。
- `tray_type` 直挂 `tool_state` 而非独立关系表：原版本身就是 ToolStateEntity
  列级 UPDATE（cha），成员关系本就长在工具行上；独立 `editor_tray` 仅为
  TrayEntity 的 lastUsedToolId/托盘存在性而建，职责清晰。
- 删除守卫按"可见托盘中的同类型实例数"判定（x7f 用 `i8f.b` 统计
  Primary+Secondary，不含 Hidden）——Harmony 一致，Hidden 中的实例不参与
  计数，隐藏行也因此可删。
- 上限按"Primary 托盘 ≥12"判定：o6f.maxReached 与 wb4 的 `size < 12` 都是
  对 Primary 计数；显示路径落 Primary 末尾直到 12 再溢 Secondary。

## 后果

- `ToolState` +`trayType` 必填字段；`EditorTray` 新接口；`ToolRepository`
  +6 方法；`FakeToolRepository` 全量实现（内存版 i8f.a/重编号/三托盘）。
- 默认工具集仍为 Harmony 已实现子集（Primary 6 工具）：原版 MEDIA/RECORD/
  POINTER/LASER/REVIEW/RULER/ZOOM 未实现，登记为功能范围差异而非映射错误；
  托盘骨架已就位，新增工具类型时直接进默认列表即可。
- 复制插入位置（源行 +1）为推断项——`on.java` invokeSuspend 反编译失败，
  证据文档如实登记；INSERT 语义与 tool_id 唯一性为已证部分。
- 重排序交互用 ▲▼/菜单代替原版拖拽手势（ArkUI 适配），写路径语义一致。
- Replay `d02-original-toolbox-customization-parity.mjs` 122 项检查；
  全套 replay 429/429；双 HAP 静态构建 0 错误。
