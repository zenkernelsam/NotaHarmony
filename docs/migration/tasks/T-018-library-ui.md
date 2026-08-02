# T-018 资料库 UI

## 目标

实现资料库页面：左侧导航栏 + 笔记网格/列表 + 响应式断点（600/840/952/1400vp）+ 新建/删除笔记功能。

## 参考

- 知识库：REVERSE_ANALYSIS.md §39.3（o77 LibraryRoute：侧栏 Home/Notes/Shared/Folder + 内容分发）、§39.4（响应式断点：840vp 常驻侧栏、952vp 侧栏 332vp、1400vp 4 列）
- 契约：`docs/migration/phase-3-tools-ui.md` §3 响应式布局规格
- 依赖：T-017（NoteRepositoryImpl 提供数据）

## 实现要求

### 创建/修改文件

1. 重写 `note/src/main/ets/ui/library/LibraryPage.ets`（完整实现）
2. 创建 `note/src/main/ets/ui/library/LibraryViewModel.ets`

### LibraryPage 布局

```
Row {
  [侧栏（≥840vp 显示）]  Column { Home / Notes / Folders 导航项 }
  [主内容]  Column {
    搜索栏（48vp 高）
    笔记网格（Grid + GridItem，列数按断点）
    FAB 新建按钮（64vp，右下角）
  }
}
```

### 响应式实现

```typescript
// 监听窗口宽度
.onAreaChange((oldArea, newArea) => {
  const widthVp = newArea.width as number;  // 已是 vp
  if (widthVp >= 1400) { this.columns = 4; this.sidebarWidth = 332; this.showSidebar = true; }
  else if (widthVp >= 952) { this.columns = 3; this.sidebarWidth = 332; this.showSidebar = true; }
  else if (widthVp >= 840) { this.columns = 2; this.sidebarWidth = 280; this.showSidebar = true; }
  else { this.columns = widthVp >= 600 ? 3 : 2; this.sidebarWidth = 0; this.showSidebar = false; }
})
```

### LibraryViewModel

```typescript
@Observed
export class LibraryViewModel {
  notes: NoteMeta[] = [];
  isLoading: boolean = true;
  searchQuery: string = '';

  async loadNotes(): Promise<void>  // 从 NoteRepositoryImpl 加载
  async createNote(): Promise<string>  // 创建并返回 noteId
  async deleteNote(noteId: string): Promise<void>
}
```

### 交互

- 点击笔记卡片 → `router.pushUrl({ url: 'ui/editor/NotePage', params: { noteId } })`
- 长按笔记卡片 → 弹出删除确认
- FAB 点击 → createNote → 跳转编辑器
- 搜索栏输入 → 过滤笔记列表

### 鸿蒙特有约束

- 尺寸全部用 vp（不用 px）。
- Grid 组件 + `columnsTemplate` 动态列数。
- 侧栏宽度用 `@State sidebarWidth: number` 动态绑定。
- 笔记卡片：标题 + 更新时间 + 缩略图占位（灰色矩形）。

## 验收标准

- [ ] `check_ets_files` + `build_project` 通过
- [ ] `start_app` 后进入 LibraryPage 可见笔记网格
- [ ] 新建笔记后列表刷新显示新条目
- [ ] 点击笔记进入 NotePage
- [ ] 窗口宽度变化时列数/侧栏正确切换
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-018-完成.md`
