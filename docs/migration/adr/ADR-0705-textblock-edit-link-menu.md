# ADR-0705：文本块编辑表面链接四项菜单（ww2/wg7.N 移植）

- 日期：2026-09-28
- Phase：757
- 状态：Accepted
- 证据：`docs/migration/evidence/phase-757-textblock-edit-link-menu.md`
- 关联：ADR-0561（Phase 592 `pca` 两项菜单 + `ww2` 登记偏差——本条取代其偏差 #2）

## 背景

原版链接菜单分两面：

- `g1f.java` `pca` 非编辑命中 → `wg7.OPEN, COPY_LINK` 两项
  （Phase 592 已移植）。
- `ww2.java:350` 文本块**编辑表面** tap 命中链接段包围盒 →
  `wg7.N` 全枚举 `[OPEN, COPY_LINK, EDIT, REMOVE]` 四项——此前
  登记为未移植偏差（Harmony 编辑表面无链接编辑操作）。

Phase 757 移植 `ww2` 路径。

## 决策

1. **tap 触发**：`TextArea.onClick` 回调（ArkUI 原生 tap 事件，
   在 `onTextSelectionChange` 更新 caret 之后触发）→ 仅当
   `caretSelectionStart === caretOffset`（折叠 caret，即 tap 非
   拖选）且 caret 落入带 `style.link` 的 run 时弹菜单。
2. **caret→run 探测**（`linkRunAtCaret`）：`rej.i` 点坐标→偏移→
   span 的 TextArea 等价物。探测 `caret-1`（优先，覆盖 tap 落尾
   字符右侧）与 `caret`（兜底，覆盖落首字符左侧）两个探测点，
   命中 `run.start <= probe < run.end` 且 `style.link !==
   undefined` 的 run。
3. **四项菜单**（`showEditLinkMenu`）：`showActionMenu`（title=url）
   + 按 `wg7` 序 `[link_open, copy_link, link_menu_edit,
   link_menu_remove]`。
4. **行为接线**（全部复用既有机制）：
   - Open → `UIAbilityContext.openLink(url)`，失败 toast
     `link_open_failed`。
   - Copy Link → `pasteboard` 纯文本写入，成功 toast `link_copied`。
   - Edit → 选区置为链接段 `[run.start, run.end)` → `openLinkSheet()`；
     `linkUrlAt` 预填既有 URL → `linkSheetIsEdit=true` →
     `en5.c` Edit hyperlink 标题态。
   - Remove → 选区置为链接段 → `removeLink()`（`applyLinkUrl(null,…)`
     = `removeHyperlinkFromSelection` 等价物）。
5. **字符串**：新增 `link_menu_edit`/`link_menu_remove`（base=原版
   文案 Edit/Remove；zh_CN=编辑/移除）；`link_open`/`copy_link`
   沿用既有键。

## 偏差（fail-closed 记录）

1. 链接定位：原版按 tap 点坐标命中链接段包围盒；Harmony 原生
   `TextArea` 无 tap 点几何 API，改为折叠 caret→run 探测
   （`caret-1` 优先、`caret` 兜底覆盖边界落点）。语义等价、机制
   适配。
2. 菜单呈现为底部 `showActionMenu` 而非锚定弹窗（沿用 Phase 592
   同一偏差）。
3. 触发门槛为折叠 caret——拖选/双击选区经过链接不弹菜单，与原版
   "tap-on-link"语义一致（原版编辑表面 drag-select 亦不弹）。

## 验证

- `d02-original-textblock-link-tap.mjs` TOTAL=47（新增 18 项
  编辑表面 pins）。
- `note@default` HAP：BUILD SUCCESSFUL。
