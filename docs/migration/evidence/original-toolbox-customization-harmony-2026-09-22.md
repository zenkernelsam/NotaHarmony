# Harmony 证据：原版工具箱自定义（Primary/Secondary/Hidden 托盘）— 2026-09-22

## 目标

对照原版 Notability 1.0.3（decompiled_1.0.3）ToolboxDatabase 的三托盘工具箱模型，
补齐 Harmony 缺失的工具箱自定义面：隐藏/显示、排序、删除（守卫）、复制、12 工具上限、
恢复默认。原版该能力以 `ToolboxEntity → TrayEntity → ToolStateEntity` 三层持久化，
可见性 = 托盘成员关系，不存在单独的 "hidden" 标志位。

## 原版证据

### 托盘类型与表结构

- `defpackage/cgf.java:13-17`：`cgf("Primary",0)` / `cgf("Secondary",1)` /
  `cgf("Hidden",2)` —— 三托盘枚举，序数 0/1/2。
- `defpackage/e47.java`：`TrayEntity(tray_id, tray_type, toolbox_owner_id,
  lastUsedToolId)` + 索引 `index_TrayEntity_toolbox_owner_id`；
  `ToolStateEntity(tool_id PK, tray_owner_id INTEGER, toolType, trayIndex, …)`——
  `tray_owner_id` 是 TrayEntity 外键，`tool_id ≠ toolType` 支持同类型多实例。
- `defpackage/cha.java`：Room UPDATE adapter 同时覆盖 ToolStateEntity 全字段
  （含 tray_owner_id/trayIndex，按 tool_id）与 TrayEntity.lastUsedToolId——托盘
  成员关系是列级 UPDATE，不是关系表写入。

### 种子/默认布局（gr7 + ba8 + rz1）

- `gr7.java:151` `new j7f(0, 1, 1)`：ToolboxEntity（active=1, previous=1）。
- `gr7.java:164` `agf(0, cgf.I, 0, 1)` / `agf(1, cgf.J, 0, 10)` /
  `agf(2, cgf.K, 0, -1)`：Primary(id 0, lastUsedTool=1)、Secondary(id 1,
  lastUsedTool=10)、Hidden(id 2, lastUsedTool=-1)。
- `rz1.java:1070` Primary 默认 8 工具（trayOwner=0，tool_id 自 1 起）：
  PEN、PENCIL、HIGHLIGHTER、TEXT、ERASER、SELECT、MEDIA、RECORD。
- `rz1.java:1075` Secondary 默认 5 工具（trayOwner=1，tool_id 自 10 起）：
  POINTER、LASER、REVIEW、RULER、ZOOM。Hidden 初始为空。
- `a6f.java:23-47`：13 个工具枚举（PEN…ZOOM）。

### 写路径语义

- **移动/排序 `i8f.a`**（i8f.java:55 起）：移出源托盘→源托盘按 `u5f.a(...,0,0,
  index,null,119)` 致密重编号；目标托盘剔除同 id→`rh8.v(i2,0,size)` 钳位插入→
  `u5f.a(...,0,dest,index,null,117)` 致密重编号；`t5f.d` 批量写回。
- **隐藏 `x7f` case 1**（x7f.java:135-147）：`h(cgf.K)` 取 Hidden 托盘→
  `i8f.a(tool, hiddenTrayId, size)`——移到 Hidden **末尾**；Hidden 缺失时日志报错。
- **显示 `wb4`**（wb4.java:115-140）：`h(cgf.I)` 取 Primary→`size < 12` 时
  `i8f.a(tool, primaryId, size)` 落 Primary 末尾；否则 `h(cgf.J)` 落 Secondary
  末尾。Primary 缺失日志 "No Primary tray found when unhiding a tool"。
- **删除 `x7f` case 0**（x7f.java:87-98）：`i8f.b(toolType)` 统计该类型在可见
  托盘中的实例数，`<= 1` 时日志 "Refusing to delete the sole instance of a
  tool type" 拒绝；否则 `t5f` 删除该行并重编号源托盘。**删除仅允许移除重复实例。**
- **复制**：设置项存在（o94.java case 13 图标 + w43 case 8 → `on(17,…)`），
  写路径为插入一条新 tool_id 的 `u5f` 拷贝（`s5f` case 0 = INSERT）。`on.java`
  的 invokeSuspend 主体为 JADX 反编译失败块，精确插入位置属推断——按相邻插入
  （源行 trayIndex+1）实现并在本文登记为推断项。
- **上限 `o6f.java:142`**：`list5.size() >= 12 → maxReached`；`wb4.java:127`
  `size < 12` 双重印证 Primary 托盘容量 **12**。
- **恢复默认 `d8f`**：设置 VM `sg9` 事件（ti9.java:448）→ `ai9.java:52`
  `fag.w0(this, new d8f(i8fVar, null), i8fVar.a)`；`yne.java:162`
  `DELETE FROM ToolStateEntity` + gr7 重播种管线。
- **选择 `i8f.g`**：写 ToolboxEntity（mostRecent/previous）并重写所属托盘
  `lastUsedToolId`。
- **聚合 `x6f`**：toolbox = `{a: ToolboxEntity, b: 可见托盘列表, c: Hidden 托盘}`
  ——Hidden 不进入可见列表。

## Harmony 落点

### Schema（DatabaseHelper.ets，版本 68→69）

- `tool_state.tray_type INTEGER NOT NULL DEFAULT 0`——cgf 序数列；Harmony 保留
  `tray_owner_id` 作为 toolbox 所有者（原版是 TrayEntity 外键），成员关系由
  `tray_type + tray_index` 表达。
- 新表 `editor_tray(tray_id, tray_type, toolbox_owner_id, last_used_tool_id)`，
  复合主键 `(tray_id, toolbox_owner_id)` 使托盘按所有者作用域（原版 id 全局 int）。
- v69 迁移：ADD COLUMN + CREATE TABLE + 对每个 `editor_toolbox_state` 所有者
  `INSERT OR IGNORE` 播种托盘 0/1/2（gr7/ba8 对应）。

### 模型（BrushTypes.ets）

- `TRAY_TYPE_PRIMARY/SECONDARY/HIDDEN = 0/1/2`；`MAX_PRIMARY_TOOLS = 12`。
- `ToolState.trayType`（成员关系=可见性）；`EditorTray` 镜像 TrayEntity。

### 仓储（ToolRepositoryImpl / ToolRepository）

- `getToolStates`：`ORDER BY tray_type, tray_index`（托盘序 + 托盘内序）。
- `ensureTrays`：INSERT OR IGNORE 播种三托盘（幂等）。
- `setTrayLastUsedTool`：`UPDATE editor_tray SET last_used_tool_id`（i8f.g）。
- `moveToolToTray`（i8f.a 对应）：源托盘致密重编号→目标托盘钳位插入→目标
  托盘致密重编号，单事务批量 upsert。
- `deleteToolState`（x7f 对应）：删除后同源托盘致密重编号。
- `insertToolStateAt`：`tray_index >= ?` 的行 +1 后插入（复制工具相邻插入）。
- `deleteAllToolStates`（d8f/yne 对应）：清 tool_state + editor_tray +
  editor_toolbox_state 三表。
- `saveToolStates`：改为按 tray_type 分组的致密编号（修复 flat-index 缺陷）。

### 视图模型（EditorViewModel）

- `toolStates` 公开数组 + `visibleToolStates()/hiddenToolStates()` 分区
  （x6f 可见托盘 + Hidden 分列对应）。
- `hideTool` → Hidden 末尾；`showTool` → Primary<12 落 Primary 末尾否则
  Secondary 末尾（wb4 对应）；`moveToolToIndex`（i8f.a 对应，支持跨托盘）；
  `duplicateTool` → 新唯一 tool_id（`xxx-copy[-n]`）插入源行 +1；
  `deleteTool`/`canDeleteTool` → 可见实例 ≤1 拒绝（x7f 对应）；
  `resetToolsToDefaults` → 清表 + 重播种 + 重选 pen。
- `runStructuralOp`：结构性操作先深拷贝快照，持久化失败整体回滚并回调
  `onPersistenceError`。
- `selectToolById`：按行选择（支持重复实例），Hidden 行不可选；行自身
  `eraserIsPartial`/`selectionIsFreehand` 经 `applyActiveState` 生效——
  每个重复实例携带独立模式位。
- `fixActiveToolAfterStructuralOp`：活动工具被隐藏/删除后回退到首个可见行并
  持久化选择历史。
- 初始化：loaded 合并 + 缺失默认类型回填 Primary 尾部（x7f"类型必有可见
  实例"不变量）+ trayType 越界收敛 Primary。

### UI

- `EditorToolbar`：硬编码按钮 → `ForEach(visibleToolStates())` 按托盘序动态渲染；
  WHOLE_ERASER 行渲染 整笔/局部 双按钮（行级模式位）；⚙ 入口 `bindSheet` 打开
  设置面板；选中高亮改为 `isActiveTool(toolId)`（tool_id 级）。
- `ToolboxSettingsDialog`（o6f 对应）：可见工具行（▲▼ 排序 + ⋯ 菜单：换托盘/
  隐藏/复制/删除）、Hidden 分区（显示）、`tool_max_reached` 提示、恢复默认；
  资源名沿用原版命名（hidden_tools、reset_to_default、show_tool…）。

### 测试桩（note/src/test/EditorViewModel.test.ets）

`FakeToolRepository` 实现全部新接口（内存版 i8f.a / 致密重编号 / 三托盘），
`cloneState` 带 trayType，`deleteToolState` 镜像源托盘重编号。

## 登记差异（原版 → Harmony 适配）

| 项 | 原版 | Harmony | 说明 |
|---|---|---|---|
| 托盘 id | TrayEntity 全局 int 0/1/2 | (tray_id, toolbox_owner_id) 复合键 | 多所有者作用域，语义等价 |
| tray_owner_id | TrayEntity 外键 | toolbox 所有者 + 独立 tray_type 列 | 原 schema 复用 |
| 默认工具集 | Primary 8 + Secondary 5（13 枚举） | Primary 6（已实现工具子集） | MEDIA/RECORD/POINTER/LASER/REVIEW/RULER/ZOOM 未实现——登记为功能范围差异，非映射错误 |
| 复制回调 | `on(17)` 主体不可反编译 | 相邻插入（trayIndex+1） | 推断项：数据模型/INSERT 语义已证，精确位置未证 |
| 重排序手势 | 拖拽（Compose LazyColumn） | ▲▼ 按钮 + ⋯ 菜单 | ArkUI 手势适配，写路径语义一致 |

## 验证

- `docs/migration/replays/d02-original-toolbox-customization-parity.mjs`：
  122 项断言（原版锚点 + Harmony 锚点 + i8f.a/x7f/wb4 可执行模型）。
- 全套 replay 429/429；`note@default` / `note@ohosTest` 静态构建通过，0 ArkTS 错误。
