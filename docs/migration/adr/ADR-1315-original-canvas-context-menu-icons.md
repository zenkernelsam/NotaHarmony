# ADR-1315：画布空白处长按菜单挂原版矢量图标

- 状态：Accepted
- 关联：Phase 1379、ADR-1311/1313/1314（菜单图标化）、evidence `phase-1379-original-canvas-context-menu-icons.md`

## 背景

画布空白处长按弹出的上下文菜单
（`NoteCanvasView.ClipboardPasteContextMenu`，对应原版 `yqa.f`/`m18.m0`
的空白长按 `{PASTE, SELECT_ALL}`）在 Phase 1379 之前是纯文字 `MenuItem`。

## 决策

为两个 `MenuItem` 加 `startIcon`，映射到原版 selection/context 菜单的
对应 drawable：

| Harmony 项 | startIcon | 原版 drawable |
|---|---|---|
| paste | `selmenu_paste` | `ui_designsystem__paste_content_manager` |
| select_all | `menuicon_select_all` | `ui_designsystem__select_all` |

`selmenu_paste` 复用 Phase 1375 已生成资产；`menuicon_select_all` 为本阶段
新增 media SVG（`ui_designsystem__select_all`，24×24，双 path 描边）。

## 理由

- 原版空白长按菜单条目带 vector painter；`MenuItem.startIcon` 是等价承载位。
- `select_all` 的 `ui_designsystem__select_all` 与"全选"语义精确对应；
  `selmenu_paste` 与 Phase 1375/1377/1378 的粘贴图标保持一致。

## 兼容性

- 仅加 `startIcon`，`content`/`onClick`/门控不变：
  - `paste` 仍受 `canPasteClipboardNow() || canUseOriginalClipboardImage()`、
    `photoImportBusy` 门控，先元素剪贴板、否则系统图片路径不变。
  - `select_all` 仍调 `selectAllPageElements()`，外层
    `recentInteractionGateActive()` 不变。
- a11y 仍由 `content` 文字提供；图标为纯视觉补充。
