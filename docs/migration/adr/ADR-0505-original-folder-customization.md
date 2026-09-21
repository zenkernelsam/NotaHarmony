# ADR-0505：原版文件夹颜色/emoji 自定义采用非空颜色列 + 增量编辑 API，emoji 空串即无

- 状态：已接受（2026-09-22，Phase 533）
- 背景：Phase 530（ADR-0502）逐表比对登记 SCHEMA-D3——原版
  `SyncedFolderMetadata` 持有 `color INTEGER NOT NULL`、`emoji TEXT`、
  `updatedAt INTEGER NOT NULL`，`ClientFolderEdit` 是"未写字段=保留"的增量编辑
  队列；`pdb` 显示模型逐字段"edit 覆盖 synced"解析，`w09` 笔记行携带
  `folderColor`，emoji 选择器为 `LIBRARY_FOLDER_EMOJI_PICKER` flag 门控的分类
  网格。Harmony `folder` 此前仅 `id/name/created_at/parent_id/sibling_order`，
  无任何自定义字段。

## 决策

1. 三列直挂 `folder`（版本 67→68，ALTER 迁移）：`color INTEGER NOT NULL
   DEFAULT FOLDER_DEFAULT_COLOR(-7431250)`、`emoji TEXT`、
   `updated_at INTEGER NOT NULL DEFAULT 0`，存量行 `updated_at` 回填
   `created_at`（原版 `rdb` 创建时 createdAt/updatedAt 同刻写入）。
2. 颜色列 NOT NULL：原版 `SyncedFolderMetadata.color` 恒非空、`pdb.f()` 无 null
   解析路径（edit/synced 都缺时抛 "Data not found"）——文件夹必然渲染一个
   具体色；因此 `editFolder` 的 `color` 只接受 number，无"清除颜色"语义。
   默认色 `-7431250`（0xFF8E9BAE 石板灰蓝）是文档化近似——原版调色板常量
   位于未反编译的 Compose 资源，无法逐值恢复，如实登记。
3. `editFolder(folderId, { name?, color?, emoji? })` 单 API 对齐
   `beb.e`/`id7.l` 增量语义：未写字段不动、写入在单事务内、
   `updated_at` 恒盖 `Date.now()`（`vdb` 证明 `this.T` 无条件写入）；
   `renameFolder` 保留签名并委托 `editFolder({ name })`；
   `moveFolder` 只给被移动文件夹盖 `updated_at`（`xdb` 对齐），兄弟行
   sibling_order 归一化不算编辑、不盖章。
4. emoji `null`/`''` 均归一化为 NULL 存储（`normalizeFolderEmoji`），对齐
   `pdb.d()` 的"空串即无 emoji"显示语义。
5. UI 单点扩展 `NameDialog`：8 色色块行（首项锁定 `FOLDER_DEFAULT_COLOR`）+
   `∅`/10 个预设 emoji 行；新建默认色+无 emoji，重命名以当前值初始化，确认
   一次性提交 name+color+emoji（`id7.l` 单次调用对齐）。文件夹行在名称前渲染
   10dp 色点与 emoji（`pdb` 行模型对齐）。

## 理由

- `w09.folderColor` 与 `pdb.f()` 证明颜色是用户可见属性而非同步管线私用字段；
  `ac4` flag 证明 emoji 选择器是真实产品功能——本差距是功能级而非纯 schema 级。
- `updatedAt` 恒写是原版跨全部编辑路径（标题/颜色/emoji/移动/甚至全 null 的
  `udb` 空调用）的一致行为；归一化兄弟行不盖章则因原版分数序 siblingOrder
  从不为兄弟生成编辑行。
- 预设 emoji 子集而非分类网格：原版选择器为 flag 门控功能且体量巨大；10 个
  高频预设 + 清除覆盖主要用例，分类面板留作后续增强（证据文档登记）。

## 后果

- `NoteFolder` 接口 +3 必填字段；`FolderRepository.test` 工厂同步补齐；
  `DatabaseHelper.test` 钉 `DB_VERSION = 68`。
- 文件夹对话框每次确认都写 `updated_at`——此前重命名不落时间戳的行为被修正。
- `NameDialog` 的 `onConfirm` 签名 `(name) → (name, color, emoji)`；该组件仅
  服务文件夹对话框，无其他调用方。
- 未实现的残留差异（如实登记）：emoji 全分类选择器、原版确切调色板色值、
  笔记行 `folderColor` 渲染（Harmony 笔记行当前无文件夹色块）。
- Replay `d02-original-folder-customization-parity.mjs` 56 项检查可执行复放
  以上语义与全部锚点。
