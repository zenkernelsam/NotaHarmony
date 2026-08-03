# T-039 文件夹管理

## 目标

资料库侧栏支持文件夹：创建/重命名/删除文件夹，笔记可移入文件夹，按文件夹浏览。

## 实现要求

### 1. 数据层

数据库已有 note_meta.folder_id 字段。新建 folder 表（需 DDL 迁移）：

修改 `DatabaseHelper.ets` 添加：
```sql
CREATE TABLE IF NOT EXISTS folder (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL
)
```
DB_VERSION 升到 2，DatabaseManager 初始化时执行版本迁移（CREATE TABLE IF NOT EXISTS 幂等）。

创建 `note/src/main/ets/data/FolderRepositoryImpl.ets`：createFolder/renameFolder/deleteFolder/getAllFolders。

### 2. 资料库 UI

修改 `LibraryPage.ets` 侧栏：
- "全部笔记" 项（默认）
- 文件夹列表（图标 + 名称 + 笔记数）
- 侧栏底部 "+ 新建文件夹" 按钮 → 原生 TextInput 对话框输入名称
- 长按文件夹 → bindMenu（重命名/删除）；删除文件夹时内部笔记回到根目录（不删笔记）

### 3. 笔记移动

- 笔记卡片长按菜单（已有删除）→ 增加"移动到文件夹" → 二级菜单列出文件夹 + "根目录"
- 选择后 updateNote(folderId) 刷新

### 4. 文件夹浏览

- 点击侧栏文件夹 → 主内容区显示该文件夹的笔记（getNotesByFolder）
- 顶部显示当前文件夹名 + 返回"全部笔记"

## 验收标准

- [ ] 创建/重命名/删除文件夹可用
- [ ] 笔记可移入/移出文件夹
- [ ] 点击文件夹过滤显示其笔记
- [ ] 删除文件夹后笔记回到全部笔记
- [ ] `check_ets_files` + `build_project` 通过 + 模拟器不崩溃

## 完成报告

`docs/migration/reports/T-039-完成.md`
