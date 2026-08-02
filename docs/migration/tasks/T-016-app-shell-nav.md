# T-016 应用壳与双层导航

## 目标

重构应用入口：Index 重定向到 LibraryPage，建立 LibraryPage → NotePage 的双层路由结构。

## 参考

- 知识库：REVERSE_ANALYSIS.md §39.2（根入口 MainActivity→ComposeView→s4g.d→aq8/jk8 主栈）、§39.5（f89 NoteRoute→xs7 笔记内部导航→zz8 NoteCanvasRoute）
- 契约：`docs/migration/phase-3-tools-ui.md` §2.1 页面结构
- 依赖：Phase 2 NoteCanvasPage（画布核心逻辑后续重构为组件）

## 实现要求

### 创建/修改文件

1. 创建 `note/src/main/ets/ui/library/LibraryPage.ets`（空壳 @Entry 页面）
2. 创建 `note/src/main/ets/ui/editor/NotePage.ets`（空壳 @Entry 页面，包含 NoteCanvasView 占位）
3. 修改 `note/src/main/ets/pages/Index.ets`（添加 router.replaceUrl 到 LibraryPage）
4. 修改 `note/src/main/resources/base/profile/main_pages.json`（注册新页面路由）

### LibraryPage.ets 空壳

```typescript
import { router } from '@kit.ArkUI';

@Entry
@Component
struct LibraryPage {
  build() {
    Column() {
      Text('Library').fontSize(24)
      Button('New Note').onClick(() => {
        router.pushUrl({ url: 'ui/editor/NotePage' });
      })
      // T-018 会填充完整资料库 UI
    }.width('100%').height('100%')
  }
}
```

### NotePage.ets 空壳

```typescript
import { router } from '@kit.ArkUI';

@Entry
@Component
struct NotePage {
  build() {
    Column() {
      Row() {
        Button('← Back').onClick(() => { router.back(); })
        Text('Note Editor').fontSize(20)
      }.width('100%').height(48)
      // T-019 会添加工具栏
      // T-020 会嵌入画布组件
      Text('Canvas Placeholder').width('100%').layoutWeight(1)
    }.width('100%').height('100%')
  }
}
```

### main_pages.json

```json
{
  "src": [
    "pages/Index",
    "ui/library/LibraryPage",
    "ui/editor/NotePage",
    "ui/editor/NoteCanvasPage"
  ]
}
```

### 鸿蒙特有约束

- 使用 `router.pushUrl` / `router.back()`（不用 Navigation 组件，MVP 阶段）。
- Index 页面用 `router.replaceUrl`（不保留 Index 在栈中）。
- NotePage 接收参数：`router.getParams()` 获取 noteId（T-017 数据层后使用）。
- 页面文件路径必须与 main_pages.json 中的 src 一致。

## 验收标准

- [ ] `check_ets_files` 零错误 + `build_project` 通过
- [ ] `start_app` 运行后 Index 自动跳转到 LibraryPage
- [ ] LibraryPage 点击 "New Note" 进入 NotePage
- [ ] NotePage 点击 "Back" 返回 LibraryPage
- [ ] 不修改 Phase 1/2 契约文件

## 完成报告

`docs/migration/reports/T-016-完成.md`
