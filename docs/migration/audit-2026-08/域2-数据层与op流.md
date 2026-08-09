# 域2 审计报告：数据层与 op 流持久化

审计范围：`note/src/main/ets/data/`（DatabaseHelper / DatabaseManager / *RepositoryImpl / StrokePersistence / NotePackageSpec / WebDAVClient / WebDAVConfigStore）与 `note/src/main/ets/core/op/`。
基准：`decompiled_1.0.3/sources/com/gingerlabs/notability/data/**`（事实优先级：反编译源码 > 文档）。

证据等级：✅ 直接源码/SQL 佐证 | 🟡 间接佐证（结构/命名） | ⚠️ 仅移植侧静态可判定（基准无对应物） | ❓ 证据不足

---

## D-01 【P0 数据丢失】笔画持久化完全没有页维度，多页笔记所有页共用一份元素集合

- 移植侧：`note/src/main/ets/data/StrokePersistence.ets:32-74`（`saveElements(noteId, strokes, textBlocks)`）、`:77-107`（`loadElements(noteId)`）；表定义 `note/src/main/ets/data/DatabaseHelper.ets:34-41`（`client_op` 无 `page_id` 列）。
- 基准证据（🟡）：原版把每篇笔记的操作流按 **note bundle** 组织，元素带页归属；`data/note/ops/`（`NoteBundleMetadataDatabase`）与 `data/note/state/`（`NoteStateDatabase`）分离存储，页是笔记内的一级实体；移植侧 `page_info` 表存在页实体（`DatabaseHelper.ets:65-75`）但元素表与之毫无关联，属结构性缺失而非风格差异。
- 差异描述：
  - `client_op` 表只有 `(op_id, note_id, op_type, payload, client_time)`，**没有 `page_id`**。
  - `saveElements` 第一步就是 `DELETE FROM client_op WHERE note_id = ?`（`StrokePersistence.ets:39-41`），任何一次保存都会抹掉该笔记下**所有页**的元素，再只写入调用方传入的那一批。
  - 移植侧自己的注释已确认该缺陷：`NoteImporter.ets:307-308`「⚠ 必须一次性写入：saveElements 会先删除该 noteId 的全部记录，逐页调用会互相清空」，`NoteImporter.ets:357`「StrokePersistence 按 noteId 整存整取、没有页维度（T-025 MVP），NoteCanvasView 也是」。导入侧靠把所有页笔画拍平成 `allStrokes` 一次性写入来规避（`NoteImporter.ets:150,178`），代价是**页归属信息在导入时即永久丢失**。
  - 后果：① 导入多页 .note 后，所有页的笔画叠在同一张画布上；② 编辑器 `NoteCanvasView.ets:125` 只保存当前内存中的元素集合，若将来引入分页视图，切页保存会清空其他页数据；③ 缩略图 `ThumbnailRenderer.ets:21` 渲染的是全笔记元素而非首页。
- 修复指令：
  1. `DatabaseHelper.ets` 的 `DDL_CLIENT_OP` 增加 `page_id TEXT NOT NULL DEFAULT ''` 列，并新增索引 `CREATE INDEX IF NOT EXISTS idx_client_op_page ON client_op(note_id, page_id, client_time)`；`DB_VERSION` 升至 3 并在 `DatabaseManager` 中补 `ALTER TABLE client_op ADD COLUMN page_id ...` 的升级分支（见 D-04）。
  2. `StrokePersistence.saveElements` 签名改为 `saveElements(noteId: string, pageId: string, strokes, textBlocks)`，删除谓词改为同时 `equalTo('note_id')` 与 `equalTo('page_id')`；新增 `loadElements(noteId, pageId)`，保留 `loadAllElements(noteId)` 供缩略图/导出使用。
  3. 更新全部调用点：`NoteImporter.ets:178,308` 改为按页写入；`NoteCanvasView.ets:102,125` 传当前 pageId；`NoteExporter.ets:61` 改用按页读取以恢复导出的分页结构。
- 验收标准（静态可判定）：
  - `grep -n "page_id" note/src/main/ets/data/DatabaseHelper.ets` 在 `DDL_CLIENT_OP` 块内命中；
  - `grep -rn "saveElements(" note/src` 的所有调用点参数个数 ≥ 4；
  - `StrokePersistence.ets` 中 `saveElements` 的删除谓词同时出现 `equalTo('note_id'` 与 `equalTo('page_id'`；
  - `NoteImporter.ets` 中不再存在 "必须一次性写入" 的规避注释。

---

## D-02 【P1 行为不一致】op-log 模型退化为整体快照，undo 不可持久化、增量同步不可实现

- 移植侧：`note/src/main/ets/data/StrokePersistence.ets:31-74`（注释自陈「每次变更全量重写」）；`note/src/main/ets/core/op/OpStore.ets:6-17`（`OpStore` 接口定义了 `appendOp` / `getOpsSince` / `getOpCount`，**全仓无任何实现类**）。
- 基准证据（✅ 结构 / 🟡 语义）：原版包路径即 `com/gingerlabs/notability/data/note/ops/`，并有 `ops/synced/` 下的一整组同步专用异常：`CorruptedSyncedOpException.java`、`StaleSyncedNoteException.java`、`NoteHasNoOpsException.java`、`NoteOpsNotFoundException.java`、`AccessDeniedException.java`。这些异常的存在直接证明原版是**按 op 粒度追加并同步**的模型（"note has no ops"、"stale synced note"、"corrupted synced op" 三者只在 op-log + 增量同步语义下才有意义），而非快照覆盖。
- 差异描述：
  - 移植侧复用了 `client_op` 表来存「当前全部元素」，`op_type` 恒为 `10 (INSERT_ELEMENTS)`（`StrokePersistence.ets:52,65`），`op_id` 直接取元素 id（`:50,63`）。这使得该表语义从「操作日志」变成「元素快照表」——同一元素被修改后是覆盖而非追加新 op。
  - `OpStore` 接口存在但无实现，`appendOp`/`getOpsSince` 从未被调用，说明 op 流路径整体未落地。
  - 代价：① undo/redo 无法跨会话持久化（重启后历史归零）；② 无法做增量同步（`getOpsSince` 无数据源）；③ 每次落笔都触发全量删除+全量重插，笔画数上千时写放大严重，且删除与重插之间无事务保护（见 D-03）。
- 修复指令：短期至少标注该退化为已知技术债并在 `docs/REVERSE_ANALYSIS.md` 记录；中期实现 `OpStoreImpl implements OpStore`，`appendOp` 走 INSERT（`op_id` 用独立 UUID 而非元素 id），元素状态由 op 回放得出，`saveElements` 仅作为压缩/快照点（配合 `op_type` 区分 SNAPSHOT 与 INSERT/DELETE/UPDATE）。
- 验收标准（静态可判定）：存在 `implements OpStore` 的类，且 `grep -rn "appendOp(" note/src` 有非接口定义的调用点；`StrokePersistence.ets` 中 `'op_id': stroke.id` 不再出现（op_id 与元素 id 解耦）。

---

## D-03 【P0 数据丢失】saveElements 的「先删后写」没有事务包裹，中途失败即全篇笔迹清零

- 移植侧：`note/src/main/ets/data/StrokePersistence.ets:38-73`。
- 差异描述：`await store.delete(del)` 之后是一个 `for` 循环逐条 `await store.insert(...)`，整段仅由一个 `try/catch` 包住且 catch 内**只打日志不回滚**（`:71-73`）。若任一 insert 抛异常（磁盘满、约束冲突、进程被杀），已执行的 DELETE 无法撤销 → 该笔记的笔迹**永久丢失且无任何用户可见提示**。`await` 循环还使删除与写入之间存在较长的时间窗口，期间应用被系统回收同样导致数据归零。
- 基准证据（🟡）：原版基于 Room，`@Transaction`/`runInTransaction` 是 DAO 批量写的默认形态；且原版为追加模型，根本不存在「先删全部」这一危险步骤。
- 修复指令：用 `store.beginTransaction()` / `store.commit()` / `store.rollBack()` 包裹 `saveElements` 全过程，catch 分支中调用 `rollBack()` 并向上抛出（或返回 boolean 让调用方提示保存失败）；同时把逐条 `insert` 改为 `batchInsert`，减少写入窗口。
- 验收标准（静态可判定）：`StrokePersistence.ets` 中出现 `beginTransaction()` 且 catch 块内出现 `rollBack()`；`saveElements` 返回类型不再是无信息的 `Promise<void>`（或调用方对失败有分支处理）。

---

## D-04 【P0 数据丢失】数据库无版本号与升级路径，`StoreConfig` 未设 version、无 onUpgrade

- 移植侧：`note/src/main/ets/data/DatabaseManager.ets:28-31`（`StoreConfig` 只有 `name` 与 `securityLevel`，**未传 version**）；`note/src/main/ets/data/DatabaseHelper.ets:7`（`DB_VERSION = 2` 定义了但全仓无人读取）。
- 差异描述：
  - `DB_VERSION` 是死常量：`grep` 显示 `DatabaseManager.ets` 的 import 列表（`:5-7`）根本没有引入 `DB_VERSION`。数据库 `version` 恒为 0，`store.version` 从不被检查或写入。
  - 升级策略完全依赖 `CREATE TABLE IF NOT EXISTS`（`:40-48`），这只能处理「新增整张表」；**任何列的新增/改名/类型变更都不会生效**（旧表已存在 → IF NOT EXISTS 直接跳过），运行时表现为查询报「no such column」并被 `catch` 吞掉，最终静默返回空数据 = 用户视角的数据丢失。D-01 要求新增 `client_op.page_id` 时会立刻踩中这一点。
  - 注释 `DatabaseHelper.ets:6` 自称「版本 2（CREATE TABLE IF NOT EXISTS 幂等迁移）」，属于对迁移能力的误判。
- 修复指令：`StoreConfig` 补 `version: DB_VERSION`；`initialize()` 中读取 `store.version`，为 0 时执行全量建表并置为 `DB_VERSION`，否则按 `oldVersion → DB_VERSION` 逐级执行 `ALTER TABLE` 迁移脚本（在 `DatabaseHelper.ets` 中新增 `MIGRATIONS: Record<number, string[]>`），迁移整体置于事务内，成功后再更新 `store.version`。
- 验收标准（静态可判定）：`DatabaseManager.ets` 的 import 含 `DB_VERSION`，`StoreConfig` 字面量含 `version:`；文件中出现 `store.version` 的读与写；存在按版本分支的迁移语句数组。

---

## D-05 【P1 数据不一致】DDL 完全没有外键与唯一约束，删除不级联、重复插入不拦截

- 移植侧：`note/src/main/ets/data/DatabaseHelper.ets:11-90`（7 张表 DDL 中 **零个** `FOREIGN KEY`、零个 `UNIQUE`）。
- 基准证据（🟡）：原版为 Room 多库设计（`NoteStateDatabase` / `NoteAssetDatabase` / `NoteBundleMetadataDatabase` / `RawLibraryStateDatabase` / `ToolboxDatabase` / `SettingsDatabase`），Room 的 `@Entity` 默认生成主键与索引；跨表引用在 Room 中通过 `@ForeignKey(onDelete = CASCADE)` 或显式 DAO 事务处理。移植侧两者皆无。
- 差异描述：
  - `page_info.note_id`、`client_op.note_id`、`note_meta.folder_id` 均无外键约束。删除笔记只靠 `NoteRepositoryImpl.deleteNote`（`:135-153`）手工删 4 张表，**遗漏了 `note_asset`**（该表用 `note_ids TEXT` 存 JSON 数组，`DatabaseHelper.ets:47`，删除笔记后引用残留 → 资产永远不会被回收，孤儿文件累积）。
  - 删除文件夹时 `note_meta.folder_id` 不会被置空（`FolderRepositoryImpl` 无对应处理），产生指向不存在文件夹的孤儿笔记，`getNotesByFolder` 查不到 → 笔记从库页「消失」。
  - `page_info` 缺 `UNIQUE(note_id, page_index)`，`PageRepositoryImpl.addPage:38-48` 用「查全表取 max+1」计算索引，两次并发 addPage 会算出相同 index 且无约束拦截 → 页序错乱。
  - `note_asset.note_ids` 用 JSON 字符串存多对多关系，无法索引、无法保证一致性；应为独立关联表。
- 修复指令：
  1. DDL 加 `FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE`（page_info、client_op）与 `FOREIGN KEY(folder_id) REFERENCES folder(id) ON DELETE SET NULL`（note_meta），并在 `DatabaseManager.initialize` 中执行 `PRAGMA foreign_keys = ON`（ArkData 需显式开启）。
  2. `page_info` 加 `UNIQUE(note_id, page_index)`；`client_op` 加 `UNIQUE(note_id, page_id, op_id)`。
  3. `deleteNote` 补上 `note_asset` 的引用清理（从 `note_ids` 移除该 noteId，数组空则删行并删本地文件）。
- 验收标准（静态可判定）：`DatabaseHelper.ets` 中 `FOREIGN KEY` 出现 ≥ 3 次、`UNIQUE(` ≥ 2 次；`DatabaseManager.ets` 含 `PRAGMA foreign_keys`；`NoteRepositoryImpl.deleteNote` 中出现 `note_asset`。

---

## D-06 【P1 行为不一致】deleteNote 非事务，四次删除任意一步失败即留下半删状态

- 移植侧：`note/src/main/ets/data/NoteRepositoryImpl.ets:135-153`。
- 差异描述：`note_meta` → `page_info` → `client_op` → `note_state` 四个 `await store.delete` 串行执行，共用一个 `try/catch`，catch 内只 `console.error`。若在删完 `note_meta` 后失败，笔记从库页消失但其页/笔画/视图状态永久残留，且**再也没有入口能清理**（后续所有清理都以 noteId 为线索，而 noteId 已不可见）。返回 `Promise<void>` 使调用方无法感知失败。
- 修复指令：整段包 `beginTransaction()/commit()/rollBack()`；删除顺序改为先子后父；返回 `Promise<boolean>` 或抛出，让 UI 能提示。
- 验收标准：`deleteNote` 中出现 `beginTransaction()` 与 `rollBack()`。

---

## D-07 【P1 行为不一致】PageRepository 的页序模型与 PageInfo 契约脱节，reorderPages 非事务且静默半成功

- 移植侧：`note/src/main/ets/data/PageRepositoryImpl.ets:33-63`（addPage）、`:95-110`（reorderPages）、`:112-125`（rowToPage 丢弃 `page_index`）。
- 差异描述：
  - `PageInfo` 模型**不含 `pageIndex` 字段**（`rowToPage:114-121` 读了 6 列，唯独不读 `page_index`；`addPage` 的注释 `:36` 也承认「PageInfo 契约无 pageIndex 字段」）。因此上层拿到的 `PageInfo[]` 只有隐式的数组顺序，任何一次乱序处理都无法自纠，也无法把某一页的真实序号回写。
  - `addPage` 为算 index 把该笔记**全部页行拉进内存遍历**（`:38-48`），O(n) 且非原子；正确做法是 `SELECT MAX(page_index)`。并发插入会得到相同 index（叠加 D-05 缺 UNIQUE 约束 → 直接产生重复页序）。
  - `reorderPages:98-106` 在循环里逐条 `update`，无事务。中途失败 → 一部分页是新序号、一部分是旧序号，可能出现重复 index，页顺序永久错乱且无提示。
  - `deletePage` 删除后**不重排后续页的 `page_index`**（`:65-75`），留下空洞（0,1,3,4）。虽然 `orderByAsc` 读取仍正确，但与 `addPage` 的 `max+1` 组合会让 index 无限增长；更关键的是任何依赖「index == 数组下标」的上层逻辑都会错位。
- 修复指令：
  1. 在 `PageInfo` 中补 `pageIndex: number` 并在 `rowToPage` 读取、`updatePage` 写入。
  2. `addPage` 改用 `store.querySql('SELECT IFNULL(MAX(page_index), -1) + 1 FROM page_info WHERE note_id = ?', [noteId])`。
  3. `reorderPages` 与 `deletePage`（含后续 index 压缩）各自包事务。
- 验收标准：`PageRepositoryImpl.ets` 中 `rowToPage` 含 `page_index`；`addPage` 不再出现 `while (countSet.goToNextRow())`；`reorderPages` 含 `beginTransaction()`。

---

## D-08 【P1】所有 Repository 吞异常返回空值，上层无法区分「无数据」与「读写失败」

- 移植侧：`NoteRepositoryImpl.ets:73-76,91-94,110-113,172-175`（catch → `return null` / `return []`）、`:30-32,45-47,130-132,150-152,188-190`（catch → 仅 log，`void` 返回）；`PageRepositoryImpl.ets:27-30,60-62,72-74,90-92,107-109`；`StrokePersistence.ets:71-73,103-105`；`AssetRepositoryImpl` / `ToolRepositoryImpl` / `FolderRepositoryImpl` 同一模式。
- 差异描述：这是全数据层的统一反模式。最危险的组合是「写失败静默」+「读失败返回空」：一次写失败后，下一次读返回空集合，UI 渲染为「这篇笔记是空的」，用户继续编辑并触发 `saveElements` 的先删后写 → 用空集合覆盖磁盘上原本完好的数据，**把一次瞬时写错误放大成永久数据丢失**。
- 修复指令：写方法返回 `Promise<boolean>` 或抛出；读方法失败时抛出而非返回空。至少 `loadElements` 失败必须抛出，且 `NoteCanvasView` 在加载失败时禁止后续自动保存。
- 验收标准：`StrokePersistence.loadElements` 的 catch 分支不再 `return result`（改为 throw）；`NoteCanvasView.ets` 中存在 "加载失败则不保存" 的标志位判断。

---

## D-09 【P2】DatabaseManager.initialize 失败后静默半初始化，且并发调用会重复建表

- 移植侧：`note/src/main/ets/data/DatabaseManager.ets:33-38`（getRdbStore 失败仅 log 后 `return`，`rdbStore` 保持 null）、`:42-56`（DDL 每条独立 try/catch，失败继续）、`:24-26`（`if (this.rdbStore !== null) return` 的重入保护对**并发 await 无效**）。
- 差异描述：
  - `getRdbStore` 失败后 `initialize()` 正常返回，调用方以为初始化成功；随后任何 `getStore()` 都抛 `DatabaseManager not initialized`，异常从各 Repository 的 `try` 外泄（如 `NoteRepositoryImpl.ets:15` 的 `getStore()` 在 try 之外）→ **未捕获异常，可能崩溃**。
  - DDL 逐条吞异常：某张表建失败后数据库处于不完整状态但仍被标记为已初始化（`:57`），后续查询全部失败并被吞掉。
  - `initialize` 是 async，两个并发调用都会通过 `:24` 的 null 检查并各自执行全套 DDL 与 `getRdbStore`。应缓存 in-flight Promise。
- 修复指令：`getRdbStore` 失败改为 `throw`；DDL 循环中任一失败即 throw 并保持 `rdbStore = null`；用 `private initPromise: Promise<void> | null` 做并发去重。
- 验收标准：`DatabaseManager.ets` 中 catch 分支含 `throw`；存在 `initPromise` 字段且 `initialize` 首行返回缓存 Promise。

---

## D-10 【P2】note_meta.folder_id 允许 NULL，但 rowToNote 用 getString 读取

- 移植侧：`note/src/main/ets/data/DatabaseHelper.ets:61`（`folder_id TEXT`，可空）与 `note/src/main/ets/data/NoteRepositoryImpl.ets:202`（`folderId: resultSet.getString(resultSet.getColumnIndex('folder_id'))`）。
- 差异描述：`NoteMeta.folderId` 类型为 `string | null`（见 `createNote` 签名 `folderId: string | null`），但读路径用 `getString` 而非先 `isColumnNull` 判空。ArkData `ResultSet.getString` 在列值为 NULL 时行为不保证（抛异常或返回空串）。若抛异常，`rowToNote:206` 会 `throw`，而该 throw 发生在 `getAllNotes` 的 `try` 内 → 整个列表被吞成 `[]`，**用户所有未归档笔记（folder_id 为 NULL，即绝大多数）在库页全部消失**。这与 `createNote(title, null)` 的默认路径直接冲突，实际发生概率很高。
- 修复指令：`rowToNote` 改为 `const fi = resultSet.getColumnIndex('folder_id'); folderId: resultSet.isColumnNull(fi) ? null : resultSet.getString(fi)`。同时 `createNote` 的 bucket 中 `'folder_id': folderId` 传 null 时应确认 ValuesBucket 接受 null（否则显式省略该键）。
- 验收标准：`NoteRepositoryImpl.ets` 中出现 `isColumnNull`。

---

## D-11 【P1 功能不可用】PROPFIND 解析硬编码 `d:` 命名空间前缀，非 Nextcloud 类服务器一律解析为空

- 移植侧：`note/src/main/ets/data/WebDAVClient.ets:181-185`

```ts
const responseRe = /<d:response[\s>][\s\S]*?<\/d:response>/gi;
const hrefRe = /<d:href>([\s\S]*?)<\/d:href>/i;
```

- 差异描述：WebDAV 的 XML 命名空间前缀由服务器自行决定，RFC 4918 只规定命名空间 URI `DAV:`，不规定前缀。常见形态有三类：① `<d:response>`（Nextcloud/ownCloud）；② `<D:response>`（Apache mod_dav、多数 Java 实现）——`/i` 标志恰好覆盖；③ **无前缀、用默认命名空间** `<response xmlns="DAV:">`（IIS、部分 Python/Go 实现）以及 `<lp1:getcontentlength>` 这类服务器私有前缀（Apache 对活属性的实际输出）。第 ③ 类会让 `responseRe` 零命中，`parsePropfind` 返回空数组，`listDir` 返回 `[]`。
- 用户可见现象：连接测试显示"连接成功"，但备份列表永远是空的，恢复功能形同虚设，且**没有任何错误提示**（`listDir` 的 catch 也返回 `[]`，无法区分"目录为空"与"解析失败"）。
- 修复指令：把前缀改为通配。`responseRe` → `/<([a-z0-9]+:)?response[\s>][\s\S]*?<\/([a-z0-9]+:)?response>/gi`，其余四个同理；`getcontentlength`/`getlastmodified` 额外容忍私有前缀。更稳妥的做法是改用 `@ohos.xml` 的 `XmlPullParser` 按 localName 匹配并忽略前缀。另需区分"解析出 0 条"与"responseRe 零命中"，后者应记录 warning 并让上层提示"服务器响应格式无法识别"。
- 验收标准（静态）：`WebDAVClient.ets` 中五个正则均不含裸 `d:` 字面前缀；`parsePropfind` 在 `responseRe` 零命中且 xml 非空时有显式的 warning 分支。
- 证据等级：⚠️（RFC 4918 与常见服务器实现推断；基准侧 Android 原版不使用 WebDAV，本项为移植方自研功能，无原版可对照）

---

## D-12 【P1 功能不可用】远端路径与 href 全程不做百分号编码/解码

- 移植侧：`WebDAVClient.ets:115-117`（`remoteNotePath`）、`:129-139`（`backupUrl` 直接字符串拼接）、`:194-195`（href 原样用作 path，未 decode）
- 差异描述：
  - 写路径：`backupPath` 由用户在设置页自由输入（`WebDAVSettingsPage`），含中文、空格、`#`、`?` 时直接拼进 URL。`#` 会把其后内容变成 fragment 被丢弃 → PUT 打到错误路径；空格在部分服务器上导致 400。
  - 读路径：PROPFIND 返回的 `<d:href>` 按规范是**已百分号编码**的，移植侧 `path: hrefMatch[1].trim()` 原样保存，随后 `download(remotePath)` 拿它再次请求时是双重编码（若中间有编码环节）或显示乱码；`name` 从 href 尾段取时（`nameMatch` 为空的服务器）会显示 `%E4%B8%AD%E6%96%87.note`。
- 修复指令：新增 `private encodePath(p: string): string`，对路径段逐段 `encodeURIComponent` 后用 `/` 连接（不能整串 encodeURIComponent，会把 `/` 也编码）；`backupUrl` 与 `remoteNotePath` 统一走它。`parsePropfind` 中对 href 做 `decodeURIComponent` 后再存入 `path`，并在重新发起请求时重新编码；`name` 取自 decode 后的尾段。
- 验收标准（静态）：`WebDAVClient.ets` 中存在 `encodeURIComponent` 与 `decodeURIComponent` 各至少一处；`remoteNotePath` 的返回值经过编码函数。
- 证据等级：⚠️（RFC 3986 / RFC 4918 §8.3；无原版可对照）

---

## D-13 【P1 功能不可用】ensureBackupDir 不递归建目录，多级 backupPath 必然失败

- 移植侧：`WebDAVClient.ets:55-62`
- 差异描述：只对 `backupUrl('')` 发一次 MKCOL。RFC 4918 §9.3.1 规定：若父集合不存在，MKCOL 返回 **409 Conflict**。用户把 backupPath 填成 `/apps/nota/backup/`（相当常见，Nextcloud 用户尤其习惯放在子目录）时，若 `/apps/nota/` 不存在则整条备份链路失败，而 `ensureBackupDir` 只返回 `false`，`BackupPage` 无法告诉用户"是父目录缺失"。
- 修复指令：改为逐级建。拆分 `backupPath` 为路径段，从第一段起累积拼接并依次 MKCOL，把 `201`/`405` 都视为该级成功，遇到非 `201/405` 才判失败并把失败层级带回给调用方。
- 验收标准（静态）：`ensureBackupDir` 内出现对路径段的循环（`split('/')` + `for`），且单次 MKCOL 调用不再直接 return。
- 证据等级：✅（RFC 4918 §9.3.1 明文规定 409 语义）

---

## D-14 【P1 数据不可恢复】PUT 不发 Content-Length / Content-Type，且 upload 忽略 Uint8Array 的视图偏移

- 移植侧：`WebDAVClient.ets:66-73`、`:150-176`
- 差异描述：
  - 注释（`:65`）自陈"ArkTS 头字段无法携带连字符（Content-Type），MVP 不传"。这个结论不成立：`http.HttpRequestOptions.header` 接受 `Object`，用 `{'Content-Type': 'application/octet-stream'}` 这种带引号的键在 ArkTS 中是合法的（其自身代码 `:93` 就写了 `{ 'Depth': '1' }` 带引号的键）。真正的问题是 `WebDAVHeaders` 这个 interface 只声明了 `Authorization`/`Depth` 两个字段，把自己限死了。部分服务器（含 IIS、部分 nginx dav 配置）对无 Content-Type 的 PUT 直接 415 拒绝。
  - `data.buffer as ArrayBuffer` 丢弃 `byteOffset` 与 `byteLength`。当前调用链（`ZipArchive.ets:280` 返回精确尺寸的新数组）恰好安全，但这是**偶然安全**：任何一处改用 `subarray()`/`slice` 视图，上传的就是整个底层缓冲区，备份文件被写入尾部垃圾字节且**不会报错**，直到恢复时才暴露。
- 修复指令：
  1. `WebDAVHeaders` 增加 `'Content-Type'?: string`，`request` 在 `body !== undefined` 时补 `'Content-Type': 'application/octet-stream'`。
  2. `upload` 改为 `options.extraData = data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength)`，或在入口断言 `data.byteOffset === 0 && data.byteLength === data.buffer.byteLength`。
- 验收标准（静态）：`WebDAVClient.ets` 中出现 `Content-Type`；`upload` 内不再出现裸的 `data.buffer as ArrayBuffer`。
- 证据等级：✅（ArkTS 带引号键的合法性由本文件 `:93` 自证；视图偏移语义为 TypedArray 规范）

---

## D-15 【P2】request 在 finally 中 destroy，随后仍返回 resp 供调用方读 result

- 移植侧：`WebDAVClient.ets:169-175`
- 差异描述：`await client.request(...)` 拿到 `resp` 后立即在 `finally` 中 `client.destroy()`，再把 `resp` 返回给上层读 `resp.result`。`http.HttpRequest.destroy()` 会释放该请求持有的原生资源，`resp.result`（尤其 ARRAY_BUFFER 形态）是否在 destroy 后仍然有效，官方文档未明确保证。若底层是零拷贝映射，`download()` 读到的可能是已释放内存。
- 证据等级：❓ —— 需要查阅 `@kit.NetworkKit` 中 `destroy()` 与 `HttpResponse.result` 生命周期的官方说明，或用 `harmonyos_knowledge_search` 检索确认。当前**不能断定是 bug，但风险点必须记录**。
- 修复指令（保守）：在 `finally` 之前把 `resp.result` 需要的数据拷贝出来（ARRAY_BUFFER 走 `new Uint8Array(arr).slice()`），改为返回自定义的 `{code, body}` 结构而非透传 `HttpResponse`。
- 验收标准（静态）：`request` 的返回类型不再是 `http.HttpResponse`，或 destroy 之前存在显式的结果拷贝语句。

---

## D-16 【P2 安全】WebDAV 密码以明文存入 preferences，且不阻止 http:// 明文传输

- 移植侧：`note/src/main/ets/data/WebDAVConfigStore.ets:9,24,37`（`KEY_PASSWORD` 明文 put/get，文件头注释自陈"MVP 密码明文"）；`WebDAVClient.ets:142-146`（Basic Auth = base64，非加密）
- 差异描述：preferences 存储位于应用沙箱，root 或备份提取场景下可直接读出。叠加 `serverUrl` 不校验 scheme，用户填 `http://` 时 Basic Auth 的 base64 凭据在网络上等同明文。原版对凭据的处理在 `com/gingerlabs/notability/core/user/` 与 `data/subscription/storage/`，使用的是平台密钥库而非明文偏好设置（🟡 结构佐证，未逐行核对）。
- 修复指令：密码改存 `@ohos.security.huks` 加密后的密文，或至少改用 `@ohos.data.preferences` 之外的受保护存储；`WebDAVSettingsPage` 在 `serverUrl` 以 `http://` 开头时给出明确的安全警告并要求二次确认。
- 验收标准（静态）：`WebDAVConfigStore.ets` 中 `KEY_PASSWORD` 的写入路径经过加密调用；`WebDAVSettingsPage.ets` 中存在 `startsWith('http://')` 的告警分支。

---

## D-17 【P2】parseManifest 对更高 version 直接判为非法，包格式无前向兼容

- 移植侧：`note/src/main/ets/data/NotePackageSpec.ets:47-49`（`parsed.version !== NOTE_FORMAT_VERSION` 即 `return null`）
- 差异描述：一旦将来 `NOTE_FORMAT_VERSION` 升到 2，旧版本 App 读新包会得到"格式无法识别"，这是可接受的；但**新版本 App 读旧包同样会被拒**（严格不等），等于每次升版都让用户此前所有备份失效。原版对 note bundle 的版本处理带迁移路径（`data/note/ops/` 下有 synced op 的版本化异常体系，🟡）。
- 修复指令：改为 `parsed.version > NOTE_FORMAT_VERSION → 返回 null（太新，提示升级 App）`；`parsed.version < NOTE_FORMAT_VERSION → 进入按版本的字段补全逻辑后接受`。
- 验收标准（静态）：`parseManifest` 中版本判据为 `>` 而非 `!==`，且存在低版本分支。

---

## D-18 【P2】parsePage 静默修正非法数据，损坏的页被当作空白页导入

- 移植侧：`NotePackageSpec.ets:80-82`（`if (!Array.isArray(parsed.elements)) { parsed.elements = []; }`）
- 差异描述：`elements` 字段类型错误（例如被截断成字符串、或是 `null`）时不报错，静默替换为空数组。调用方 `NoteImporter` 无从得知这一页的内容其实是损坏的，导入结果显示"成功"，用户看到的是一张空白页——**静默数据丢失**。这与域3 F-03 指出的"缺少 PartialImportException 语义"是同一类问题。
- 修复指令：`elements` 非数组时 `return null`（视为该页解析失败），由 `NoteImporter` 决定是跳过该页并计入"部分导入"警告，还是整体失败。
- 验收标准（静态）：`parsePage` 中不再对 `parsed.elements` 做赋值修正；`NoteImporter` 对 `parsePage` 返回 null 的页有计数与用户可见提示。

---

## D-19 【P3】OpStore 接口定义完整但零实现，属悬空契约

- 移植侧：`note/src/main/ets/core/op/OpStore.ets:6-17`
- 差异描述：接口五个方法（appendOp/getOps/getOpsSince/deleteOps/getOpCount）全仓无 `implements OpStore`，也无任何调用点。它是 D-02 所述"op-log 退化为快照"的直接证物——契约层按原版 op 流设计，实现层却走了另一条路，两者从未对接。
- 修复指令：与 D-02 合并处理。在 D-02 落地前，至少在文件头补注释标明"契约已定义，实现见 T-XXX，当前由 StrokePersistence 的快照模型临时替代"，避免后续工人误以为已实现。
- 验收标准（静态）：文件头注释含实现状态说明，或存在 `implements OpStore` 的类。

---

## ⚠️ 指挥官更正：D-05 部分结论过度断言

D-05 原文称"7 张表 DDL 中 **零个** `FOREIGN KEY`、零个 `UNIQUE`"。经复核 `DatabaseHelper.ets:11-90`：**七张表全部带 `PRIMARY KEY`**（note_state.note_id、tool_state.tool_id、client_op.op_id、note_asset.asset_hash、note_meta.id、page_info.page_id、folder.id）。

因此：
- "零个 FOREIGN KEY" ✅ 成立，D-05 关于级联删除与孤儿数据的结论有效。
- "零个 UNIQUE" ❌ **不成立**。主键即隐含唯一约束，`ON_CONFLICT_REPLACE` 在 tool_state / note_asset 上能正常工作，不存在"重复插入不拦截"的问题。
- D-05 真正成立的缺口是**复合唯一约束**缺失：`page_info` 缺 `UNIQUE(note_id, page_index)`（这条原文说对了），`client_op` 在补上 page_id 后需要 `UNIQUE(note_id, page_id, op_id)`。

派工时请按本更正执行，不要按 D-05 原文去"补主键"。

---

## D-20 【P1 数据不一致】getAssetsByNote 用 LIKE 模糊匹配 JSON 字符串，既会漏也会误命中

- 移植侧：`note/src/main/ets/data/AssetRepositoryImpl.ets:52`

```ts
predicates.like('note_ids', '%' + noteId + '%');
```

- 差异描述：`note_ids` 是 `JSON.stringify(string[])` 存的文本（`:37`），用子串匹配来做多对多查询有两个方向的错误：
  - **误命中**：任何 noteId 是另一个 noteId 子串的情况都会错配。当前 noteId 由 `createNote` 生成（需确认是否为完整 UUID），若将来改为短 id 或递增 id（`note1` / `note12`），`note1` 的查询会把 `note12` 的资产也捞出来 → 删除 note1 时误删 note12 仍在用的资产文件。
  - **无法走索引**：前置 `%` 使 SQLite 必须全表扫描，资产表增长后每次打开笔记都线性扫描。
  - 与 D-05 指出的 `deleteNote` 遗漏 note_asset 叠加后，孤儿资产只增不减，这条查询会越来越慢。
- 修复指令：把多对多关系改为独立关联表 `note_asset_ref(note_id TEXT NOT NULL, asset_hash TEXT NOT NULL, PRIMARY KEY(note_id, asset_hash))`，`getAssetsByNote` 改为 JOIN 查询；`note_asset.note_ids` 列保留一版用于迁移后删除。若短期不改表结构，至少把匹配串改为 `'%"' + noteId + '"%'`（带引号锚定完整 JSON 元素），消除子串误命中。
- 验收标准（静态）：`AssetRepositoryImpl.ets` 中不再出现裸的 `'%' + noteId + '%'`；存在关联表 DDL 或带引号锚定的匹配串。
- 证据等级：✅（移植侧代码自证）/ 🟡（原版 Room 侧的资产-笔记关系表结构未逐行核对）

---

## D-21 【P0 数据丢失】saveAsset 用 REPLACE 整行覆盖，共享资产的 noteIds 会被后写方抹掉

- 移植侧：`AssetRepositoryImpl.ets:32-47`
- 差异描述：`saveAsset` 直接 `insert(..., ON_CONFLICT_REPLACE)`，`note_ids` 取入参 `asset.noteIds` 全量覆盖。当同一张图片（同 hash）被插入到第二篇笔记时，调用方若传的是 `[noteB]` 而非 `[noteA, noteB]`，数据库里 noteA 的引用就被静默抹除。此后：
  - `getAssetsByNote(noteA)` 查不到该资产 → noteA 的图片在导出/备份时缺失（对应域3 的 `MissingAssetsException` 场景）；
  - 若将来实现资产 GC（按 `note_ids` 为空回收文件），noteA 仍在显示的图片会被删除文件 → **不可逆数据丢失**。
  这是"读-改-写"缺失的典型：正确语义是把新 noteId 并入已有集合。
- 修复指令：`saveAsset` 改为先 `getAsset(asset.assetHash)`，存在则把 `asset.noteIds` 与已有 `noteIds` 求并集后再写；整个读-改-写包在 `beginTransaction()/commit()` 内防并发丢更新。若采纳 D-20 的关联表方案，则改为向 `note_asset_ref` 插入一行（`ON_CONFLICT_IGNORE`），`note_asset` 表不再存 noteIds，本缺陷自然消失。
- 验收标准（静态）：`saveAsset` 内出现对既有行的读取（`getAsset` 或 query）与集合合并逻辑，且包含 `beginTransaction()`；或 `note_ids` 列已从 `saveAsset` 的 bucket 中移除。

---

## D-22 【P1 资源泄漏】deleteAsset 只删数据库行，从不删除 local_path 指向的文件

- 移植侧：`AssetRepositoryImpl.ets:67-76`
- 差异描述：`deleteAsset(hash)` 仅执行 `store.delete(predicates)`。`local_path`（`:40` 写入、`:95` 读出）指向沙箱内的实际文件，删行之后该文件**再无任何引用能找到它**，也没有任何清理入口。原版有专门的 `ExportSweepWorker.java` 与 `NoteAssetTransferWorker.java` 负责资产文件的生命周期（🟡 结构佐证，未逐行核对其清理策略）。
- 用户可见现象：反复导入含图片的笔记再删除，应用占用空间只增不减。
- 修复指令：`deleteAsset` 改为先查出 `local_path`，在事务提交成功后调用 `@ohos.file.fs` 的 `unlink` 删除文件（先删行后删文件的顺序，保证失败时是"文件残留"而非"行没了文件还在被引用"）；文件不存在时忽略错误。同时在 `NoteRepositoryImpl.deleteNote` 中（见 D-05）调用它。
- 验收标准（静态）：`AssetRepositoryImpl.ets` 中出现文件删除 API（`fs.unlink` 或 `fileIo`）；`deleteAsset` 在删除前读取 `local_path`。

---

## D-23 【P2】rowToAsset 把空串与 NULL 混为一谈，且 local_path 为 NULL 时读取方式与 D-10 同病

- 移植侧：`AssetRepositoryImpl.ets:88,95`
- 差异描述：`local_path` 在 DDL 中是可空列（`DatabaseHelper.ets:49` `local_path TEXT`，无 NOT NULL）。`rowToAsset` 用 `getString` 直读，与 D-10 指出的 `folder_id` 是同一个问题：ArkData 对 NULL 列的 `getString` 行为不保证，抛异常时会经 `:98` 转成 `throw`，进而让 `getAssetsByNote` 整个返回 `[]`。此外 `localPathRaw.length > 0 ? localPathRaw : null` 把"空串"也归为 null，使得"已下载但路径为空串"这种脏数据无法被识别和修复。
- 修复指令：改为 `const i = resultSet.getColumnIndex('local_path'); localPath: resultSet.isColumnNull(i) ? null : resultSet.getString(i)`；空串不再转 null（或转 null 时记 warning 日志）。
- 验收标准（静态）：`AssetRepositoryImpl.ets` 中出现 `isColumnNull`。

---

## D-24 【P2】ToolRepository 缺删除与批量重排能力，tray_index 只写不整理

- 移植侧：`note/src/main/ets/data/ToolRepositoryImpl.ets`（全文仅 `getToolStates` / `saveToolState` 两个方法）
- 差异描述：原版工具盘对应 `ToolboxDatabase` 与 `com/gingerlabs/notability/data/toolbar/`（🟡 结构佐证），支持工具的增删与拖拽重排。移植侧没有 `deleteToolState`，用户删除工具盘中的笔后旧行永久残留；`tray_index` 只在 `saveToolState` 里单行写入，多个工具重排时是逐行 REPLACE，无事务（与 D-07 的 `reorderPages` 同型缺陷），中途失败会出现重复或空洞的 index，`orderByAsc('tray_index')` 的结果顺序随之不确定。
- 修复指令：补 `deleteToolState(toolId)`；新增 `saveToolStates(states: ToolState[])` 批量方法，内部包事务并整体重写 tray_index。
- 验收标准（静态）：`ToolRepositoryImpl.ets` 中存在 delete 方法与含 `beginTransaction()` 的批量保存方法。

---

## D-25 【P3】client_op.payload 声明为 BLOB NOT NULL，实际写入的是 JSON 字符串

- 移植侧：DDL `DatabaseHelper.ets:38`（`payload BLOB NOT NULL`）vs `StrokePersistence.ets` 写入的是 `JSON.stringify(...)` 文本。
- 差异描述：SQLite 是动态类型，TEXT 存进 BLOB 列不会报错，但列的声明类型影响比较与排序语义，也会误导后续维护者以为是二进制格式（原版 op payload 确实是二进制，见 `core/flatbuffers/`）。属"声明与实现不符"的技术债。
- 修复指令：二选一并在注释中写明理由——① 列类型改为 TEXT（承认当前是 JSON 快照）；② 保持 BLOB 并在实现 D-02 的 op 流时改为写真正的二进制。当前阶段建议选 ①，避免误导。
- 验收标准（静态）：DDL 中该列类型与 `StrokePersistence` 的写入形态一致，且注释说明选型理由。

---

## 覆盖度声明（域2，截至指挥官接手后的补审）

| 文件 | 覆盖程度 |
|---|---|
| DatabaseHelper.ets | ✅ DDL 全部逐行核对（含本轮对 D-05 的更正） |
| DatabaseManager.ets | ✅ 逐行 |
| StrokePersistence.ets | ✅ 逐行 |
| NoteRepositoryImpl.ets | 🟡 关键路径（create/delete/rowToNote）逐行，查询方法抽查 |
| PageRepositoryImpl.ets | ✅ 逐行 |
| AssetRepositoryImpl.ets | ✅ 逐行（本轮补） |
| ToolRepositoryImpl.ets | ✅ 逐行（本轮补） |
| WebDAVClient.ets | ✅ 逐行（本轮补） |
| WebDAVConfigStore.ets | ✅ 逐行（本轮补） |
| NotePackageSpec.ets | ✅ 逐行（本轮补） |
| core/op/OpStore.ets | ✅ 逐行（本轮补） |
| FolderRepositoryImpl.ets | ⚠️ 由域5 覆盖（U-02/U-06/U-07/U-08），域2 未重复审 |
| RepositoryInterfaces.ets | ⚠️ 仅作为签名参照读取，未单独审 |

**基准侧覆盖**：原版 Room 的 `*Database_Impl.java` 建表 SQL **未逐表比对**（D-01/D-02/D-05 中标 🟡 的结论均属结构性推断）。这是本域最大的证据缺口，建议单独出一张"Room schema 逐表比对"任务卡。

---
