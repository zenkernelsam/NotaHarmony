# 域5 审计报告：库页 / 设置 / 组件 / 主题 UI

审计范围：`note/src/main/ets/ui/library/`、`ui/settings/`、`ui/components/`、`ui/theme/`、`pages/`、`noteability/`
权威基准：`decompiled_1.0.3/sources/com/gingerlabs/notability/data/library/state/folders/` 及 `defpackage/beb.java`、`defpackage/xdb.java`

统计：共 27 条。P0×2、P1×12、P2×8、P3×5。

---

## P0

### U-01 P0 编辑已有文本框时草稿从不初始化，确认即清空原文本

**位置**：`note/src/main/ets/ui/components/TextBlockOverlay.ets:8`、`:22`、`:36`；调用方 `note/src/main/ets/ui/editor/NoteCanvasView.ets:1085-1093`

**证据** ✅：
```ts
// TextBlockOverlay.ets:6-13
@Prop editing: boolean = false;
@Prop element: TextBlockElement | null = null;
@State draftText: string = '';        // ← 从不从 element.text 同步
...
TextArea({ text: this.draftText, ... })
Button('Done').onClick(() => { this.onCommit(this.draftText); })
```
`TextBlockOverlay` 在 `NoteCanvasView.build()` 中恒定实例化（不随 `editing` 创建/销毁），`@State draftText` 生命周期贯穿整个编辑器页；`aboutToAppear` 也未同步 `element.text`。

**描述**：
1. 点击已有文本框进入编辑 → TextArea 显示为空（或上一次编辑其它文本框残留的内容），点 Done 即用空串/错误内容覆盖，原文本永久丢失（覆盖后走 `onTextCommit` 落库）。
2. 连续编辑两个文本框时，第二个会带出第一个的草稿。

**修复指令**：
1. 在 `TextBlockOverlay` 增加 `@Watch('onElementChange') @Prop element`，在回调中 `this.draftText = this.element?.text ?? ''`；或改由父组件传入 `@Prop initialText` 并在 `editing` 由 false→true 的 `@Watch` 中重置 `draftText`。
2. `onCancel` 中也要清空 `draftText`。

**验收标准**：`TextBlockOverlay.ets` 中存在把 `element.text`（或父传 `initialText`）赋给 `draftText` 的语句，且该语句位于 `@Watch` 回调或 `aboutToAppear` 中；`grep -c "draftText = " TextBlockOverlay.ets` ≥ 3（初始化、onChange、cancel 重置）。

---

### U-02 P0 createFolder 在 DB insert 失败时仍返回"成功"对象，文件夹幽灵化

**位置**：`note/src/main/ets/data/FolderRepositoryImpl.ets:27-32`

**证据** ✅：
```ts
try {
  await store.insert('folder', bucket);
} catch (e) {
  console.error(`createFolder failed: ${JSON.stringify(e)}`);
}
return { id: id, name: name, createdAt: now };   // ← 无论成败都返回
```
同类吞异常：`renameFolder:40-44`、`deleteFolder:53-56`、`moveNoteToFolder:87-91`、`getAllFolders:75-78`（失败返回 `[]`，与"没有文件夹"不可区分）。

**描述**：insert 失败（表未建、主键冲突、db 未初始化）时 UI 侧栏仍会出现新文件夹（`this.folders = await getAllFolders()` 实际拿不到它，但 `moveNoteToFolder` 已可被点到并同样静默失败），把笔记"移动到"该文件夹后笔记的 `folder_id` 指向不存在的行 → 该笔记在"全部笔记"能看到、任何文件夹里都进不去，用户视为数据丢失。重启后现象随机变化。

**修复指令**：
1. 四个方法改为 `Promise<boolean>`/抛出，`createFolder` 返回 `NoteFolder | null`；insert 返回值 `rowId < 0` 也视为失败。
2. `getAllFolders` 失败时抛出而非返回 `[]`。
3. `LibraryPage.onFolderDialogConfirm` / `deleteFolder` / `moveNote` 对失败调用 `promptAction.showToast` 给出可见反馈。

**验收标准**：`FolderRepositoryImpl.ets` 中所有 `catch` 块均包含 `throw` 或使函数返回失败值（`return false` / `return null`）；不存在 catch 块内仅有 `console.error` 一行的情况。

---

## P1

### U-03 P1 `onPageShow` 用同一对象引用回写 @State，列表不刷新

**位置**：`note/src/main/ets/ui/library/LibraryPage.ets:69-79`

**证据** ✅：
```ts
onPageShow(): void {
  if (this.viewModel !== null) {
    const vm: LibraryViewModel = this.viewModel;   // ← 同一引用
    vm.loadNotes().then(() => {
      this.viewModel = vm;                          // ← 赋回同一引用，@State 不触发刷新
      this.refreshThumbnails();
    })
```
`@State viewModel` 持有的是 `@Observed LibraryViewModel`，但 `LibraryViewModel` 未通过 `@ObjectLink` 绑定到任何子组件，`@Observed` 对 `@State` 场景无效；且 ArkUI `@State` 赋同一引用不触发 diff。

**描述**：从编辑器返回资料库后，标题、更新时间、排序位置保持陈旧，直到某个真正的 `@State`（如 `thumbIds`）恰好变化才被动刷新。缩略图集合不变（笔记数不变且都能渲染）时列表完全不更新。

**修复指令**：把列表数据本身提升为 `@State notes: NoteMeta[]`，`onPageShow` 中 `this.notes = vm.getFilteredNotes().slice()`（新数组引用）；`viewModel` 降级为 `private`。

**验收标准**：`LibraryPage.ets` 中 `build()` 内的 `ForEach` 数据源为 `@State` 装饰的数组字段，而非 `this.viewModel.getFilteredNotes()` 方法调用；`grep -n "@State viewModel" LibraryPage.ets` 无匹配。

---

### U-04 P1 排序/删除/移动全部只改 ViewModel 内部字段，UI 不刷新

**位置**：`LibraryPage.ets:193-211`（setSortMode）、`:174-180`（moveNote）、`:509-532`（confirmDelete）；`LibraryViewModel.ets:44-47`

**证据** ✅：
```ts
private setSortMode(mode: NoteSortMode): void {
  this.viewModel.setSortMode(mode);   // 只改 vm.notes 内部，无 @State 变化
  ... // 只剩持久化
}
private async moveNote(noteId, folderId) {
  await this.folderRepo.moveNoteToFolder(noteId, folderId);
  await this.viewModel.loadNotes();   // 同上，无 @State 变化
}
```
`confirmDelete` 仅因随后 `refreshThumbnails()` 改了 `thumbIds` 才碰巧刷新。

**描述**：点"排序 → 标题"后网格顺序不变；把笔记移动到文件夹后卡片仍留在当前视图。用户认为功能坏了。

**修复指令**：与 U-03 合并修复——统一在这三处结尾执行 `this.notes = this.viewModel.getFilteredNotes().slice()`。

**验收标准**：`setSortMode`、`moveNote`、`deleteFolder`、`selectFolder`、`confirmDelete` 五个方法体内均出现对 `@State` 列表字段的重新赋值语句。

---

### U-05 P1 `setFolder` 内部 `loadNotes()` 未 await，与 `refreshThumbnails` 竞态

**位置**：`LibraryViewModel.ets:38-41`、`LibraryPage.ets:183-190`

**证据** ✅：
```ts
// LibraryViewModel.ets
setFolder(folderId: string | null): void {
  this.currentFolderId = folderId;
  this.loadNotes();          // ← async，未 await，返回值被丢弃
}
// LibraryPage.ets
private selectFolder(folderId: string | null): void {
  this.viewModel.setFolder(folderId);
  this.refreshThumbnails();  // ← 此刻 vm.notes 仍是旧文件夹的数据
}
```

**描述**：点击侧栏切换文件夹，缩略图基于上一个文件夹的笔记列表渲染；快速连点两个文件夹时两个 `loadNotes` 竞争写 `this.notes`，最终显示的可能是先点的那个文件夹。

**修复指令**：`setFolder` 改为 `async setFolder(...): Promise<void>` 并 `await this.loadNotes()`；`selectFolder` 改为 `private async selectFolder(...)`，`await this.viewModel.setFolder(...)` 后再刷新；`loadNotes` 内引入自增 `loadSeq` 令牌，回填前比对丢弃过期结果。

**验收标准**：`LibraryViewModel.setFolder` 签名返回 `Promise<void>` 且函数体含 `await this.loadNotes()`；`LibraryPage.selectFolder` 中 `refreshThumbnails()` 位于 `await` 之后。

---

### U-06 P1 文件夹不支持嵌套，与原版层级模型不一致

**位置**：`note/src/main/ets/data/DatabaseHelper.ets:78-83`（无 `parent_id` 列）、`FolderRepositoryImpl.ets:5-9`（`NoteFolder` 无 `parentId`）、`LibraryPage.ets:293-324`（平铺 ForEach）

**证据** ✅（原版）：`decompiled_1.0.3/sources/defpackage/xdb.java:90-92`
```java
iH = (beb.h(lq4VarI) - lq4VarI.getDepth()) + lq4Var.getDepth() + 1;
if (iH <= 6) {
    throw new MaxFolderDepthExceededException(iH);
}
```
以及 `com/gingerlabs/notability/data/library/state/folders/MaxFolderDepthExceededException.java`。原版文件夹是带 `getDepth()` / `c()`（子集合）的树，上限 6 层，并在移动时校验"目标不是自身子树"（`!lq4VarI.g(utfVar2)`，同文件 `:87`）。

**描述**：移植侧文件夹是单层平铺，无法建立"课程/学期/科目"这类原版核心信息架构；从原版导入的嵌套结构无处安放。

**修复指令**：
1. `folder` 表增加 `parent_id TEXT`（DB_VERSION → 3，迁移用 `ALTER TABLE ... ADD COLUMN`，需判存在性）。
2. `NoteFolder` 增加 `parentId: string | null`、`depth: number`。
3. `createFolder(name, parentId)` / 新增 `moveFolder(folderId, newParentId)`，两者均校验 `depth > 6` 抛 `MaxFolderDepthExceededException` 等价错误，并校验 `newParentId` 不在 `folderId` 的子树中（循环引用防护）。
4. 侧栏改为可展开树（`ListItemGroup` 或递归 `@Builder`）。

**验收标准**：`DatabaseHelper.ets` 的 `DDL_FOLDER` 含 `parent_id`；`FolderRepositoryImpl.ets` 存在 `moveFolder` 方法，且该方法体内同时含深度上限 `6` 的判断和祖先环检测（遍历 parent 链比对 `folderId`）。

---

### U-07 P1 文件夹名无合法性/重名校验，与原版 `beb.a` 不一致

**位置**：`LibraryPage.ets:140-151`

**证据** ✅（移植侧）：
```ts
private async onFolderDialogConfirm(name: string): Promise<void> {
  const trimmed: string = name.trim();
  if (trimmed.length === 0 || this.folderRepo === null) { return; }   // 仅空判断
  ...
```
原版 `decompiled_1.0.3/sources/defpackage/beb.java:133-153`：
```java
if (str.length() == 0 || lvd.s0(str, '/') || lvd.s0(str, '\\')) return false;
...
for (lq4 lq4Var2 : listC) {
    if (!ba6.o(lq4Var2.a(), utfVar) && svd.g0(lq4Var2.getTitle(), str)) return false;   // 同级重名（忽略大小写）
}
```
不满足即 `throw new InvalidFolderNameException(str)`。

**描述**：可创建任意多个同名文件夹，侧栏出现多个"数学"，用户无法区分且移动菜单里出现重复项；含 `/` `\` 的名称会污染后续导出/WebDAV 远端路径。空名时对话框静默关闭，无任何提示。

**修复指令**：在 `FolderRepositoryImpl` 增加 `validateName(name, siblings, selfId): string | null`，实现三条规则（非空、不含 `/` 与 `\`、同 parent 下 `toLowerCase()` 去重）；`onFolderDialogConfirm` 校验失败时用 `promptAction.showToast` 提示并保持对话框可重输。

**验收标准**：存在一处代码同时检查 `indexOf('/')`、`indexOf('\\')` 与同级 `toLowerCase()` 重名；`onFolderDialogConfirm` 的所有 `return` 前均有用户可见提示调用。

---

### U-08 P1 `deleteFolder` 用 `getFilteredNotes()` 找待迁移笔记，导致孤儿笔记

**位置**：`LibraryPage.ets:154-171`

**证据** ✅：
```ts
const notes: NoteMeta[] = this.viewModel.getFilteredNotes();  // ← 只含"当前浏览文件夹 + 搜索过滤"后的笔记
for (const n of notes) {
  if (n.folderId === folderId) { await this.folderRepo.moveNoteToFolder(n.id, null); }
}
await this.folderRepo.deleteFolder(folderId);
```

**描述**：当前正在浏览「A」而长按删除「B」时，`getFilteredNotes()` 返回的全是 A 的笔记，条件 `n.folderId === folderId` 恒不成立 → B 里的笔记 `folder_id` 仍指向已删除的 B。这些笔记在侧栏任何入口都进不去（B 已不在列表），只在"全部笔记"可见；若后续把"全部笔记"实现为按 folder 分组即完全丢失。搜索框有内容时同样命中。

**修复指令**：在 `NoteRepositoryImpl` 用 `getNotesByFolder(folderId)` 直查 DB 取全量，或在 `FolderRepositoryImpl` 增加 `clearFolderOfNotes(folderId)` 用一条 `UPDATE note_meta SET folder_id=NULL WHERE folder_id=?` 完成（同时避免 N 次往返）。删除前给出"文件夹内 N 个笔记将移至根目录"的确认文案。

**验收标准**：`LibraryPage.deleteFolder` 中不再出现 `getFilteredNotes()`；迁移动作由单条 repo 调用完成（`grep -c "moveNoteToFolder" LibraryPage.ets` 中 deleteFolder 内为 0）。

---

### U-09 P1 `NoteCard` 的 `bindMenu` 默认点击触发，与 `onClick` 打开笔记冲突

**位置**：`LibraryPage.ets:494-506`

**证据** ✅：
```ts
.onClick(() => { router.pushUrl({ url: 'ui/editor/NotePage', ... }); })
.gesture(LongPressGesture().onAction(() => {
  // T-039：长按弹出原生 bindMenu（删除/移动到文件夹）    ← 空实现，注释与行为不符
}))
.bindMenu(this.buildNoteMenu(note))                        // ← 默认 click 触发
```

**描述**：`bindMenu(content)` 的默认响应类型是点击。单击卡片时会同时弹出"删除/移动到…"菜单并 push 编辑器页；返回后菜单可能仍悬浮。而声称的"长按菜单"实际是空回调。

**修复指令**：删除空的 `LongPressGesture`，把 `.bindMenu(...)` 换为 `.bindContextMenu(this.NoteMenuBuilder(note), ResponseType.LongPress)`（配套把 `buildNoteMenu` 改写为 `@Builder`），保留 `onClick` 打开笔记。

**验收标准**：`LibraryPage.ets` 中 `NoteCard` 上不存在 `.bindMenu(`；存在 `ResponseType.LongPress`；不存在空函数体的 `LongPressGesture`。

---

### U-10 P1 切回"最近修改"排序不生效

**位置**：`LibraryViewModel.ets:50-61`

**证据** ✅：
```ts
private applySort(): void {
  const sorted: NoteMeta[] = this.notes.slice();
  if (this.sortMode === NoteSortMode.CREATED) { sorted.sort(...); }
  else if (this.sortMode === NoteSortMode.TITLE) { sorted.sort(...); }
  // UPDATED：repo 已按 updatedAt DESC（默认保持）
  if (this.sortMode !== NoteSortMode.UPDATED) { this.notes = sorted; }   // ← UPDATED 分支什么都不做
}
```

**描述**：切到"标题"后 `this.notes` 已被就地改成标题序；再切回"最近修改"时 `applySort` 直接跳过，列表仍是标题序，用户以为排序按钮坏了（要退出重进才恢复）。

**修复指令**：`applySort` 补 `UPDATED` 分支 `sorted.sort((a, b) => b.updatedAt - a.updatedAt)`，并无条件 `this.notes = sorted`。

**验收标准**：`applySort` 中存在 `b.updatedAt - a.updatedAt` 比较器，且函数末尾 `this.notes = sorted;` 不带条件包裹。

---

### U-11 P1 设置页文本未接主题 token，暗色模式下黑底黑字不可读

**位置**：`BackupPage.ets:240`、`:257`、`:258`、`:259`、`:282`、`:288`；`WebDAVSettingsPage.ets:109-133`、`:156`；`LibraryPage.ets:404`、`:475`

**证据** ✅：
```ts
// BackupPage.ets:240,257-259 —— 容器已用 this.resolveTokens().background，文本却没有 fontColor
Text('本地文件').fontSize(18).fontWeight(FontWeight.Medium).margin({ bottom: 8 })
Text(`服务器: ${this.serverText}`).fontSize(14).margin({ bottom: 4 })
Text(`上次备份: ${this.lastBackupText}`).fontSize(14).margin({ bottom: 8 })
```
```ts
// LibraryPage.ets:404,475 —— 硬编码
Text('无匹配笔记').fontSize(16).fontColor('#999999')
Column().backgroundColor('#E0E0E0')     // 缩略图占位，暗色下刺眼白块
```

**描述**：`DarkTheme.background = '#1A1A1A'`（`EditorTheme.ets:25`），而上述 `Text` 使用系统默认前景色（浅色主题的黑）。深色模式下"本地文件""WebDAV 云备份""服务器: …""上次备份: …"以及全部 `TextInput` 内容不可见。

**修复指令**：为上述所有 `Text`/`TextInput` 补 `.fontColor(this.resolveTokens().textPrimary)` 或 `textSecondary`；`TextInput` 另需 `.backgroundColor(this.resolveTokens().surface)` 与 `.placeholderFontColor(...)`；缩略图占位改用 `this.resolveTokens().surface`。

**验收标准**：`BackupPage.ets`、`WebDAVSettingsPage.ets`、`LibraryPage.ets` 中不存在形如 `.fontColor('#` 的十六进制字面量（`#E84026` 等语义化的错误/删除色除外，应集中到 token）；`grep -c "fontColor" BackupPage.ets` ≥ 6。

---

### U-12 P1 面板类组件整体硬编码白底，暗色模式失效

**位置**：`PageSettingsPanel.ets:121`、`:41-42`、`:90-91`、`:131-133`、`:148`、`:162`；`ColorPicker.ets:51`；`WidthSlider.ets:26`

**证据** ✅：
```ts
// PageSettingsPanel.ets:119-122
.padding(16).width(380)
.backgroundColor(Color.White)      // ← 与 ThemeStore 无关
.borderRadius(12)
// ColorPicker.ets:49-52 / WidthSlider.ets:25-27 同样 .backgroundColor(Color.White)
```
这三个组件均未引入 `ThemeStore` / `@StorageLink(THEME_MODE_KEY)`。

**描述**：深色模式下打开"页面设置""颜色""粗细"弹层会出现刺眼纯白面板，且面板内 `#F0F0F0` 未选中态与白底几乎无对比。主题覆盖不完整。

**修复指令**：三个组件均加 `@StorageLink(THEME_MODE_KEY) themeMode` / `@StorageLink(THEME_SYSTEM_DARK_KEY) systemDark` 与 `resolveTokens()` 方法（照 `LibraryPage.ets:59-61` 的普通方法写法，勿用 getter），把 `Color.White` → `surface`、`#3366FF` → `accent`、`#F0F0F0`/`#DDDDDD` 新增 token。

**验收标准**：`ui/components/` 下 `.ets` 文件中 `grep -c "Color.White"` 为 0；三个组件文件均含 `THEME_MODE_KEY`。

---

### U-13 P1 WebDAV 配置保存后返回，BackupPage 状态不更新

**位置**：`BackupPage.ets:38-55`（只有 `aboutToAppear`，无 `onPageShow`）；`WebDAVSettingsPage.ets:72-91`

**证据** ✅：`BackupPage` 通过 `router.pushUrl` 打开设置页（`BackupPage.ets:199-203`），返回时 `BackupPage` 未销毁，`aboutToAppear` 不再触发，`this.hasConfig` / `this.serverText` 保持旧值。

**描述**：首次配置 WebDAV 并保存成功、返回备份页后，仍显示"服务器: 未配置"、"提示：请先配置 WebDAV 服务器"，且两个云端按钮因 `.enabled(this.hasConfig && ...)` 保持灰化。用户必须退出整个页面重进才能备份。

**修复指令**：`BackupPage` 增加 `onPageShow(): void { this.init(); }`。

**验收标准**：`BackupPage.ets` 中存在 `onPageShow` 且其函数体调用 `this.init()`。

---

### U-14 P1 设置/备份页无返回入口

**位置**：`BackupPage.ets:229-303`、`WebDAVSettingsPage.ets:101-164`

**证据** ✅：两个 `@Entry` 页面的 `build()` 中不存在 `router.back()`、也无 `NavDestination`/标题栏返回键，`grep -n "router.back" ui/settings/` 无匹配。

**描述**：进入备份页/WebDAV 配置页后，只能依赖系统侧滑或实体返回；平板横屏与 2in1 形态下无可点击的返回控件，属信息架构缺失。

**修复指令**：在两页顶部标题行左侧加 `Button` / `SymbolGlyph` 触发 `router.back()`，或整体改为 `Navigation` + `NavDestination` 自带标题栏。

**验收标准**：`ui/settings/*.ets` 中 `grep -c "router.back()"` ≥ 2。

---

## P2

### U-15 P2 FAB 重复点击可创建多个空笔记

**位置**：`LibraryPage.ets:456-458`、`:559-568`

**证据** ✅：
```ts
private async createAndOpen(): Promise<void> {
  if (this.viewModel === null) { return; }
  const noteId: string = await this.viewModel.createNote();   // 无 in-flight 保护
  router.pushUrl(...)
```
`createNote` 内部还要 `await this.loadNotes()`（`LibraryViewModel.ets:64-68`），窗口期可达数百毫秒。

**修复指令**：加 `private creating: boolean = false` 守卫，进入即置位、`finally` 复位；同时给 FAB `.enabled(!this.creating)`。

**验收标准**：`createAndOpen` 首行存在 in-flight 布尔判断并 `return`，且函数含 `finally` 复位。

---

### U-16 P2 `refreshThumbnails` 串行阻塞且无销毁保护

**位置**：`LibraryPage.ets:88-103`

**证据** ✅：`for (const note of this.viewModel.notes) { ... await this.thumbRenderer.renderThumbnail(...) }`，逐个串行；结束后无条件 `this.thumbMap = newMap; this.thumbIds = ...`。页面已 `pushUrl` 跳走或被销毁时仍写 `@State`。

**描述**：笔记数量多时首屏长时间只显示灰色占位；快速切换文件夹会有多个 `refreshThumbnails` 并发，后启动的可能先完成、被先启动的覆盖 → 显示错误文件夹的缩略图。

**修复指令**：引入自增 `thumbSeq` 令牌，回填前校验 `seq === this.thumbSeq` 否则丢弃；只渲染当前可见（`getFilteredNotes()`）的笔记；限制并发或改为逐张增量写入。

**验收标准**：`refreshThumbnails` 中存在序号/令牌变量，且 `this.thumbIds = ` 赋值语句被该令牌比较条件包裹。

---

### U-17 P2 缩略图 PixelMap 从不释放

**位置**：`LibraryPage.ets:29`、`:100`；无 `aboutToDisappear`

**证据** ✅：`private thumbMap: Map<string, PixelMap>`，每次 `refreshThumbnails` 整体替换为 `newMap`，旧 map 中的 `PixelMap` 未调用 `release()`；`grep -n "aboutToDisappear\|release()" LibraryPage.ets` 无匹配。

**修复指令**：替换前遍历旧 map 调用 `pm.release()`；新增 `aboutToDisappear()` 释放全部并 `this.thumbRenderer.clearCache()`。

**验收标准**：`LibraryPage.ets` 含 `aboutToDisappear` 且其中出现 `.release()`。

---

### U-18 P2 仅 LibraryPage 监听系统色模式变化

**位置**：`LibraryPage.ets:251-253`；`BackupPage.ets`、`WebDAVSettingsPage.ets`、`ui/editor/NotePage.ets` 无 `onConfigurationUpdate`；`NoteAbility.ets` 亦无

**证据** ✅：`grep -rn "onConfigurationUpdate" note/src/main/ets/` 仅命中 `LibraryPage.ets:251`。

**描述**：`themeMode='system'` 时，用户在备份页/编辑器页切换系统深浅色，`THEME_SYSTEM_DARK_KEY` 无人更新，界面保持旧配色，直到回到资料库页才跟随。

**修复指令**：把监听上移到 `NoteAbility.onConfigurationUpdate(newConfig)` 中调用 `ThemeStore.setSystemDark(...)`（AppStorage 全局，所有 `@StorageLink` 自动同步），删除页面级实现避免重复。

**验收标准**：`NoteAbility.ets` 中存在 `onConfigurationUpdate` 且调用 `ThemeStore.setSystemDark`。

---

### U-19 P2 `ThemeStore.init()` 依赖 LibraryPage 先加载

**位置**：`LibraryPage.ets:216`（唯一调用点）；`NoteAbility.ets:8-15`

**证据** ✅：`grep -rn "ThemeStore.init()" note/src/` 仅 `LibraryPage.ets:216`，且位于 `initData()` 中。

**描述**：任何绕过资料库页直达（如后续加入的快捷方式/卡片跳转、或冷启恢复到编辑器页）的路径下，`AppStorage` 中主题键不存在，`@StorageLink` 只能落到声明默认值，用户已保存的"深色"偏好失效一次。持久化的读取（`preferences`）也只在 LibraryPage 里做。

**修复指令**：把 `ThemeStore.init()` + 从 `preferences` 恢复 `themeMode` 移到 `NoteAbility.onCreate`（`await` 完成后再 `loadContent`）。

**验收标准**：`NoteAbility.ets` 中出现 `ThemeStore.init()`；`LibraryPage.initData` 中不再读取 `PREF_THEME_KEY`。

---

### U-20 P2 `CustomDialogController` 每次新建且旧实例未关闭

**位置**：`LibraryPage.ets:38-47`、`:110-120`、`:127-137`

**证据** ✅：字段初始化处已 `new CustomDialogController(...)`（此时 `this.folderDialogTitle` 为初值"新建文件夹"），`showCreateFolderDialog` / `showRenameFolderDialog` 又各自 `this.folderDialog = new CustomDialogController(...)` 覆盖，旧实例既未 `close()` 也未置空。

**描述**：反复打开对话框累积未释放的 controller；字段处的那一个从未被使用，属死代码。

**修复指令**：只保留一个 controller，改为在 `builder` 中读 `this.folderDialogTitle` / 新增 `@State folderDialogInitialText`，由状态驱动内容，`show*Dialog` 只设状态后 `this.folderDialog.open()`。

**验收标准**：`LibraryPage.ets` 中 `new CustomDialogController` 出现次数为 1。

---

### U-21 P2 WebDAV 密码明文存储

**位置**：`WebDAVSettingsPage.ets:156`（自述）、`note/src/main/ets/data/WebDAVConfigStore.ets`

**证据** ✅：UI 文案"密码明文存储于本地 Preferences（MVP，后续可加密）"。

**修复指令**：改用 `@ohos.security.huks` 加密后存 Preferences，或使用 `@kit.CoreFileKit` 的应用私有加密存储；至少不要把明文写进可被备份的 preferences 文件。

**验收标准**：`WebDAVConfigStore.ets` 中密码字段的读写经过加解密函数，且 `WebDAVSettingsPage.ets` 不再存在"明文存储"提示文案。

---

### U-22 P2 `SelectionOverlay` 操作按钮无屏幕边界钳制

**位置**：`ui/components/SelectionOverlay.ets:33-40`

**证据** ✅：
```ts
.position({
  x: this.selectionRect.left,
  y: Math.max(this.selectionRect.bottom + 8, this.selectionRect.bottom),  // Math.max 恒等于 bottom+8，无意义
})
```

**描述**：选区靠近屏幕底部/右侧时"操作"按钮被推出可视区，用户无法调出选区菜单，只能取消重选。且 `Math.max` 两个操作数中前者恒大，代码意图不明。

**修复指令**：接收父组件传入的画布尺寸，`y = Math.min(rect.bottom + 8, canvasHeight - 48)`、`x = Math.min(rect.left, canvasWidth - 80)`。

**验收标准**：`SelectionOverlay.ets` 的 `.position` 计算中同时出现 `Math.min` 与容器尺寸变量。

---

## P3

### U-23 P3 `LibraryPage.initData` 重复打开同一 Preferences 实例
**位置**：`LibraryPage.ets:218` 与 `:229` 都是 `preferences.getPreferences(context, 'library_prefs')`。
**修复指令**：取一次存为局部变量复用。**验收标准**：`initData` 中 `getPreferences` 调用次数为 1。

### U-24 P3 `buildNoteMenu` 为每个文件夹生成一个顶层菜单项
**位置**：`LibraryPage.ets:535-547`。文件夹多于 5~6 个时菜单超长且无滚动语义分组。
**修复指令**：改用 `bindContextMenu` + `Menu`/`MenuItemGroup` 二级子菜单（"移动到…" → 子列表）。**验收标准**：`LibraryPage.ets` 中存在 `MenuItemGroup` 或二级 `Menu` Builder。

### U-25 P3 `PageSettingsPanel` 尺寸列表缺 A7
**位置**：`PageSettingsPanel.ets:4-12`（`SIZE_OPTIONS` 无 A7）vs `:199-200`（`dimForSize` 有 `case PaperSize.A7: return [74, 105]`）。枚举有该值但 UI 不可选，属死分支。
**修复指令**：补入 `{ size: PaperSize.A7, label: 'A7', dim: '74×105' }` 或从枚举中移除 A7。**验收标准**：`SIZE_OPTIONS.length` 与 `dimForSize` 的 `case` 数量一致。

### U-26 P3 搜索仅匹配标题
**位置**：`LibraryViewModel.ets:76-88` 只比对 `n.title.toLowerCase()`。原版资料库检索覆盖手写识别文本与 PDF 文本 ❓（未逐条核实原版检索实现，标记为待确认）。
**修复指令**：确认原版检索范围后，至少接入已有的识别文本索引。**验收标准**：待原版行为确认后补充。

### U-27 P3 搜索关键词存放在非响应式的 ViewModel 字段
**位置**：`LibraryPage.ets:362-367`（`this.viewModel.searchQuery = value` 后依赖同语句上方的 `this.searchText = value` 触发重绘）。
**修复指令**：搜索词只保留 `@State searchText`，`getFilteredNotes(query)` 改为接受入参的纯函数。**验收标准**：`LibraryViewModel` 中不再存在 `searchQuery` 字段。

---

## 与原版对照的确认项

| 项 | 原版 | 移植侧 | 结论 |
|---|---|---|---|
| 文件夹最大层级 | 6（`xdb.java:91`） | 无层级 | ⚠️ U-06 |
| 文件夹名非法字符 | `/`、`\`、空串（`beb.java:135`） | 仅空串 | ⚠️ U-07 |
| 同级重名 | 忽略大小写拒绝（`beb.java:148`） | 不校验 | ⚠️ U-07 |
| 移动文件夹到自身子树 | 校验（`xdb.java:87`） | 无"移动文件夹"功能 | ⚠️ U-06 |
| 菜单/对话框原生控件 | — | `bindMenu` / `showAlertDialog` / `@CustomDialog` / `bindPopup` 均为原生 ✅ | 无自绘替代品，红线未违反（`SelectionOverlay` 与 `PageSettingsPanel` 的虚线框、模板缩略图为纯展示，可接受） |
