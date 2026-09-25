# Phase 715：原版导入详情页 arrange 模式移植

`ui_fileimport__*` 族审计发现实缺口：原版 `zvh.a` 导入详情页有
arrange 排序模式，Phase 662 的 `ImportDetailsSheet` 未移植。

## 原版证据链

- `w8.java:155`：头部按钮在 `arrange`↔`done` 间切换（`z11` =
  arranging 态），进出排序模式。
- `te4.java:76-77`：arrange 态每行挂 `ui_fileimport__move_up`/
  `move_down` 无障碍标签的移动动作（`oe4` 处理交换；`z5c.H`
  拖拽柄向 TalkBack 暴露）；非 arrange 态行 onClick 为预览/移除。
- 排序先于物化：`rv5` 按列表序建笔记、`qv5`/`sv5` 按列表序并页。

## 实现（Harmony）

- `ImportDetailsSheet`：`@State orderedFiles`（`files` 副本）+
  `@State arranging`；全部迭代（ForEach/题草稿/confirm）走
  `orderedFiles`。
- 头部切换（`Arrange`/`Done`，复用既有 `done` 串）仅
  `orderedFiles.length > 1` 渲染——单文件排序无意义。
- arrange 态行尾 ↑/↓ 按钮（`import_move_up`/`import_move_down`
  无障碍文本，ArkUI 无拖拽重排，取可见控件等价）；越界禁用；
  题输入在 arrange 态隐藏（行配饰位被移动控件占用，同 te4 行构）。
- `ImportPlan.orderedUris?: string[]`；`dispatchImportPlan` 在场且
  与选择器集等长时优先（防越界 plan），三分支全走重排序；缺省
  保持选择器序（向后兼容）。
- 题草稿随文件移动（下标对齐交换）。

## 验证

- `d02-original-import-arrange-mode.mjs`（23 断言：原版字符串/w8
  切换/te4 行/arranging+orderedFiles+moveFile/无障碍标签/头部切换/
  多文件门控/orderedUris 回传/arrange 隐题/dispatch 长度校验+
  三分支/双 locale/ADR+证据）。
- `d05-original-import-details-sheet.mjs` 三个 dispatch 锚点合法演进
  （uris→effective），53/53 全绿。
- 全套件重跑、双 HAP 构建通过后记录于修复总纲。
