# T-017 数据层实现

## 目标

用 @ohos.data.relationalStore 实现 Phase 1 定义的 4 个 Repository 接口 + 数据库初始化管理器。

## 参考

- 契约：`note/src/main/ets/data/DatabaseHelper.ets`（DDL 常量，不得修改）
- 契约：`note/src/main/ets/data/RepositoryInterfaces.ets`（接口定义，不得修改）
- 契约：Phase 1 model 类型（NoteMeta/PageInfo/ToolState/NoteAsset/NoteViewState）
- 知识库：REVERSE_ANALYSIS.md §8（Room 表结构对照）

## 实现要求

### 创建文件

1. `note/src/main/ets/data/DatabaseManager.ets`
2. `note/src/main/ets/data/NoteRepositoryImpl.ets`
3. `note/src/main/ets/data/PageRepositoryImpl.ets`
4. `note/src/main/ets/data/ToolRepositoryImpl.ets`
5. `note/src/main/ets/data/AssetRepositoryImpl.ets`

### DatabaseManager.ets

```typescript
import { relationalStore } from '@kit.ArkData';
import { DB_NAME, DB_VERSION, DDL_NOTE_STATE, DDL_TOOL_STATE, DDL_CLIENT_OP, DDL_NOTE_ASSET, DDL_NOTE_META, DDL_PAGE_INFO, DDL_INDEXES } from './DatabaseHelper';

export class DatabaseManager {
  private static instance: DatabaseManager | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;

  static getInstance(): DatabaseManager

  // 初始化（在 NoteAbility.onCreate 或首次使用时调用）
  async initialize(context: Context): Promise<void> {
    // 1. relationalStore.getRdbStore(context, { name: DB_NAME })
    // 2. 执行全部 DDL（CREATE TABLE IF NOT EXISTS）
    // 3. 执行 DDL_INDEXES
  }

  getStore(): relationalStore.RdbStore  // 获取实例（未初始化则抛异常）
}
```

### NoteRepositoryImpl.ets

实现 `NoteRepository` 接口的全部 8 个方法：
- createNote: INSERT INTO note_meta + 创建默认首页 (INSERT INTO page_info)
- getNote: SELECT * FROM note_meta WHERE id = ?
- getAllNotes: SELECT * FROM note_meta ORDER BY updated_at DESC
- getNotesByFolder: SELECT * FROM note_meta WHERE folder_id = ?
- updateNote: UPDATE note_meta SET ...
- deleteNote: DELETE FROM note_meta + DELETE FROM page_info + DELETE FROM client_op
- getViewState: SELECT * FROM note_state WHERE note_id = ?
- saveViewState: INSERT OR REPLACE INTO note_state

### PageRepositoryImpl / ToolRepositoryImpl / AssetRepositoryImpl

同理实现各自接口的全部方法。使用 `relationalStore.RdbStore` 的 `insert/update/delete/query` API。

### 鸿蒙特有约束

- import `{ relationalStore } from '@kit.ArkData'`（API 9+）。
- 使用 `ValuesBucket` 构造插入/更新数据。
- 查询用 `RdbPredicates` + `resultSet`。
- 所有方法 async/await。
- note_asset.note_ids 存为 JSON 字符串（`JSON.stringify(string[])` / `JSON.parse()`）。
- boolean 字段存为 INTEGER (0/1)。
- 初始化时 context 从 `getContext(this)` 或 UIAbilityContext 传入。

## 验收标准

- [ ] 5 个文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] NoteRepositoryImpl implements NoteRepository（编译验证）
- [ ] createNote 后 getAllNotes 能返回新笔记
- [ ] 不修改 DatabaseHelper.ets / RepositoryInterfaces.ets

## 完成报告

`docs/migration/reports/T-017-完成.md`
