# Phase 757：文本块编辑表面链接四项菜单（ww2/wg7.N）

> 日期：2026-09-28
> 证据：`docs/migration/evidence/phase-757-textblock-edit-link-menu.md`
> ADR：`docs/migration/adr/ADR-0705-textblock-edit-link-menu.md`（取代
> ADR-0561 偏差 #2）
> Replay：`d02-original-textblock-link-tap.mjs`（47 断言，全绿）

## 背景

Phase 592 移植了 `pca` 非编辑命中两项菜单 [Open, Copy Link]；
`ww2.java:350` 编辑表面 `wg7.N` 全枚举四项（Open/Copy Link/
Edit/Remove）登记为未移植偏差——Harmony 原生 `TextArea` 编辑
表面当时无 tap→链接段定位机制。

## 原版行为（decompiled_1.0.3）

- `ww2.java:350`：编辑表面内链接段包围盒锚定 → `wg7.N` 四项菜单。
- `wg7.java`：枚举 `OPEN(0)/COPY_LINK(1)/EDIT(2)/REMOVE(3)`。
- `n94.java:240-250` + `strings.xml:487-490`：文案
  Open/Copy Link/Edit/Remove。
- EDIT → `en5.c` Edit hyperlink sheet（URL 预填）；
  REMOVE → `aue`/`wm5`→`removeHyperlinkFromSelection`。

## 实现（TextBlockOverlay.ets）

- `linkRunAtCaret()`：`rej.i` 点检的 TextArea 等价物——探测
  `caret-1`（优先）/`caret`（兜底）两侧 `style.link` run。
- `TextArea.onClick`：仅折叠 caret（非拖选）且命中链接 run 时
  弹菜单。
- `showEditLinkMenu(run)`：`showActionMenu`（title=url）+ 四项
  同序按钮：
  - Open → `UIAbilityContext.openLink` + `link_open_failed` toast
  - Copy Link → pasteboard + `link_copied` toast
  - Edit → 选区置链接段 → `openLinkSheet()`（`linkUrlAt` 预填 →
    Edit hyperlink 标题态）
  - Remove → 选区置链接段 → `removeLink()`（`applyLinkUrl(null)`）
- 字符串：`link_menu_edit`/`link_menu_remove` 新增（base/zh_CN）。

## 偏差（见 ADR-0705）

1. tap 点坐标命中 → 折叠 caret→run 探测（原生 TextArea 无 tap
   几何 API；语义等价）。
2. 底部 ActionMenu 呈现（沿用 Phase 592 同一偏差）。
3. 仅折叠 caret 触发——拖选经过链接不弹（与原版 tap 语义一致）。

## 验证

- 专项 Replay：47/47（新增 18 项编辑表面 pins）
- 全量 Desktop Replay：见下方运行结果
- `note@default` HAP：BUILD SUCCESSFUL
- `note@ohosTest` HAP：BUILD SUCCESSFUL
