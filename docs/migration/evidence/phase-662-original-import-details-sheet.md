# Phase 662 证据：原版 ou5/zvh.a 导入详情页（目的地 + 逐文件题）

日期：2026-09-24
关联：ADR-0629；前置 Phase 657（Add Files）、658（多选导入）、
660（密码处理——`w7a`/`zvh.e` 同 sheet 内承载）、661（共享入口）

## 原版实现（decompiled_1.0.3）

### 入口：`zvh.a` —— 共享导入详情 sheet

`defpackage/zvh.java:127`：

```java
public static final void a(List list, ttf ttfVar, utf utfVar, String str,
    ix4 ix4Var, Function0 function0, Function1 function1, t42 t42Var,
    int i, int i2) throws IOException
```

签名展开（Compose 重组参数省略后）：待导入 `List`（`utf` 文件描述符
集合）、`ttf` 预置目的地（编辑器上下文为当前笔记 id）、`utf` 预置
文件夹、`ix4` 导航、`Function0` = Dismiss 取消、`Function1` =
onPasswordSubmitted（Phase 660 密码回调）、`t42` 完成回调。
宿主为 `ou5`（ImportDetailsViewModel），sheet 标题 `"Import"`，取消
按钮 `"Dismiss"`（`f2j.c` 组装）。

调用点（同一 sheet 三处复用）：

- `u49` —— 编辑器「Add Files」多选结果 → `zvh.a(list, ttf=当前笔记)`。
- `zvi` —— 库「Import File(s)」菜单 → `zvh.a(list, ttf=null)`。
- `ib0` —— 共享 intent 入口 → `zvh.a(...)`。

### 目的地：`tv5` 三态

`defpackage/ou5.java:191-200`（`ou5.l` 确认分发）：

```java
if (tv5Var instanceof qv5) {
    ou5Var.N.c(new uj(((qv5) tv5Var).a()));      // → 既有笔记
    return;
}
if (!(tv5Var instanceof sv5) && !(tv5Var instanceof rv5)) { o14.t(); return; }
Iterator it = list.iterator();
while (it.hasNext()) {
    xj2.A(ou5Var.h(), dh3.a, null,
        new ku5(ou5Var, ((o69) it.next()).I, (ef2) null), 2);  // 逐文件物化
}
```

payload 形状（各 `.java` `toString` 证实）：

- `qv5(ttf a)` → `AddToExistingNote(noteId=…)` —— 并入既有笔记。
- `sv5(String a, utf b)` → `CreateSingleNewNote(title=…, folderId=…)`
  —— 一篇新笔记，可带文件夹。
- `rv5(utf a, Map b)` → `CreateSeparateNotes(folderId=…, titleOverrides=…)`
  —— 每文件一篇，`Map` 为逐文件题覆盖。

### 事件：`fu5` 归约（`o1.java`，sheet 事件处理器）

| 事件 | 原版代码 | 语义 |
|------|----------|------|
| `wt5` | `fu5Var instanceof wt5` → `lvd.b1(200, lvd.d1(wt5Var.b))` | 逐文件题编辑，**trim + 截 200 字符** |
| `st5` | `instanceof st5` → `new qv5(((st5) fu5Var).a)` | 选定既有笔记 → 生成 qv5 目的地 |
| `tt5` | `instanceof tt5` → `ou5Var2.X.j(((tt5) fu5Var).a)` | 笔记搜索 query 更新 |
| `yt5` | `instanceof yt5` → `new iq4(((yt5) fu5Var).a)` | 文件夹选择（`utf`） |
| `zt5` | `fu5Var.equals(zt5.a)`，`toString=OnImportClicked` | 确认导入（单例事件） |

Dismiss / 遮罩取消 → `Function0` 取消回调，整个 sheet 关闭不导入。

### 编辑器上下文默认值

`u49` 在「Add Files」路径里把 `ttf` 传为当前打开笔记 —— 即 sheet 的
默认目的地是 `qv5(当前笔记)`；库/共享上下文 `ttf=null`，默认走新笔记。

## Harmony 对齐实现

### 契约（`note/src/main/ets/data/NoteImporter.ets`）

```ts
export interface ImportFileDescriptor { uri; fileName; size; }
export enum ImportDestination { SEPARATE_NOTES=0, SINGLE_NOTE=1, EXISTING_NOTE=2 }
export interface ImportPlan {
  destination: ImportDestination;
  noteId: string;                  // qv5
  folderId: string | null;         // sv5/rv5
  singleTitle: string;             // sv5
  titleOverrides: Map<string,string>;  // rv5（uri → 题）
}
export type ImportSheetPrompt =
  (files: ImportFileDescriptor[], context: 'standalone'|'note',
    currentNoteId: string) => Promise<ImportPlan | null>;
```

### 分发（`dispatchImportPlan`，对齐 `ou5.l`）

- `EXISTING_NOTE` → `importPickedFilesIntoNote(target, uris, passwordPrompt)`
  —— 与 qv5 同语义（目标笔记缺省时回退 `fallbackNoteId` = 编辑器当前笔记）。
- `SINGLE_NOTE` → `importFilesIntoSingleNewNote`：先
  `createNoteWithMeta(title, folderId)`（空题回退首文件词干），再把全部
  文件按 qv5 语义并入；全部失败 → `removeFailedImport` 清掉空笔记。
- `SEPARATE_NOTES` → `importPickedFilesStandalone(uris, passwordPrompt,
  titleOverrides)`，逐文件 `importXxxFromBytes(..., titleOverride)`。

### 题覆盖管道（`wt5` 对齐）

- 四个 standalone 物化方法新增可选 `titleOverride?: string`：
  `titleOverride !== undefined && titleOverride.length > 0` 时用之，
  否则 PDF → `pdfImportTitle`、其余 → `importedFileStemTitle`。
- `normalizeImportTitleOverride`：`trim()` + `slice(0, 200)`，对齐
  `lvd.d1` + `lvd.b1(200)`。
- into-note（qv5）路径**不**消费题覆盖 —— 原版 wt5 只出现在 rv5 的
  per-note 题表里，并入既有笔记不改笔记题。

### 共享对话框（`ui/components/ImportDetailsSheet.ets`）

- 文件行：类型 emoji + 名称 + 大小（`utf` 描述符语义）。
- `SEPARATE_NOTES`：逐行 `TextInput`（预填词干）→ `titleOverrides`（wt5）。
- `SINGLE_NOTE`：题输入 + 文件夹 chips（yt5，`null`=未归档）。
- `EXISTING_NOTE`：搜索 `TextInput`（tt5）+ 全量笔记 List（st5），
  编辑器上下文预选当前笔记（`ttf` 预置）。
- `zt5`：「导入」按钮（qv5 未选笔记时禁用）；「取消」/遮罩 → `null`。

### 页面接线

- `LibraryPage`：`importFromFile` 与 `importSharedUris`（Phase 661 共享
  入口）均传 `importSheetPrompt`；笔记/文件夹列表经 `getAllNotes()` /
  `getAllFolders()` 装载（原版 sheet 搜全库）。
- `NotePage`：`importFileIntoNoteFromPicker` 传 `importSheetPrompt`，
  `context='note'` + `currentNoteId=this.noteId` → 默认 qv5(当前笔记)。
- `BackupPage`：备份恢复路径不经此 sheet（原版同样不经），未接线。
- 三个入口的 `sheetPrompt` 均为可选 —— 未接线的既有调用方保持
  Phase 658 默认语义（多选 rv5、单选直接分发）。

### 顺带修复

`PdfPasswordDialog`/`ImportDetailsSheet` 的 `CustomDialogController`
补 `cancel:` 回调 —— 遮罩关闭时把 `null` 回传 pending Promise，
避免导入互斥锁悬挂（原版 Dismiss 即取消）。

## 已登记差异

1. **目的地默认项**：原版库上下文多选默认 `rv5`（各自笔记）；Harmony
   同。单文件库上下文原版默认 `sv5`，Harmony 同（默认 New note）。
   编辑器上下文原版预选 `qv5(当前笔记)`；Harmony 同。
2. **sv5 多文件**：原版 `ou5.l` 对 sv5 也按文件循环起 `ku5` 协程
   （每协程导入一文件入同一新笔记）；Harmony 先建笔记再逐文件并入，
   语义等价。
3. **`.note` 归档**：sv5/qv5 路径下 `.note` 并入既有/单篇笔记的语义
   上游不透明（`yq8.d/e` 未反编译），Harmony 维持 fail-closed
   （该文件项 UNSUPPORTED/CORRUPTED，其余文件正常物化）。
4. **文件夹选择范围**：sheet 文件夹 chips 展示前 8 个文件夹（滚动
   宽度限制）；原版为完整列表。深层嵌套文件夹可后续补搜索。
5. **编辑器上下文文件夹列表**：`NotePage` 即时构造
   `FolderRepositoryImpl` 读取 —— 与库页同一 DB，语义一致。

## 验证

- `docs/migration/replays/d05-original-import-details-sheet.mjs`：
  53 断言全绿（原版证据 + 契约 + 分发 + 题覆盖 + 页面接线 + 字符串）。
- 受影响既有 fixture 更新：`d05-original-shared-pdf-ingress`、
  `d05-original-pdf-file-import`、`d05-original-encrypted-pdf-import`
  （签名/调用点演进，语义不变）。
