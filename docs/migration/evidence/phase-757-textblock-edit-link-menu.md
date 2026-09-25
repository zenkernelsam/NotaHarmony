# 原版证据：文本块编辑表面链接菜单四项 [Open, Copy Link, Edit, Remove]

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 757 依据。承接 Phase 592 登记的 `ww2` 编辑表面待移植项
  （见 `original-textblock-link-tap-2026-09-28.md` §6）。

## 1. 原版编辑表面链接菜单（`ww2.java` / `wg7.java` / `n94.java`）

- `ww2.java:350`：文本块编辑表面内计算链接段包围盒
  （`z1g`/`l96.A0`）锚定后弹 `wg7.N` 全枚举菜单。
- `wg7.java`：链接菜单枚举 —— `OPEN(0)`、`COPY_LINK(1)`、
  `EDIT(2)`、`REMOVE(3)`；`wg7.N` = 四项全集。
- `n94.java:240-250`：文案键 `link_menu_open`="Open"、
  `link_menu_copy_link`="Copy Link"、`link_menu_edit`="Edit"、
  `link_menu_remove`="Remove"（`res/values/strings.xml` 487-490
  行同序确认）。
- 与 `g1f.java:240-246` 的 `pca`（非编辑命中菜单）对比：
  `pca` 只出 `[OPEN, COPY_LINK]` 两项；编辑表面 `ww2` 出全四项。
- Edit 语义：打开超链接 sheet（`en5.c` 既有链接 → Edit hyperlink
  标题态，URL 预填）——与 Phase 756 前已移植的 `openLinkSheet`
  预填路径一致。
- Remove 语义：`aue`/`wm5` → `removeHyperlinkFromSelection`，
  清除选中链接段 `link` 字段（`applyLinkUrl(null, s, e)` 等价物）。

## 2. Harmony 对齐（Phase 757）

Harmony 编辑表面是原生 `TextArea`（非 Canvas 几何命中）——链接
定位采用折叠 caret → `draftCharRuns` run 探测代替原版的
`rej.i` 点坐标→偏移→span 路径（语义等价、机制适配，见 §3）。

| 原版 | Harmony |
|---|---|
| `ww2` tap → `rej.i` 偏移 → `hqe` span | `TextArea.onClick`（tap 后 caret 已就位）→ `linkRunAtCaret()` 探测 `caret-1`/`caret` 两侧 run，命中 `style.link !== undefined` 的 run |
| `wg7.N` 四项菜单 | `promptAction.showActionMenu`（title=url）+ `[link_open, copy_link, link_menu_edit, link_menu_remove]` 四项同序 |
| `vm5` `OpenLinkClicked(url)` | `UIAbilityContext.openLink(url)`；失败 toast `link_open_failed`（沿用 Phase 592 路径） |
| `link_menu_copy_link` | `pasteboard.createPlainTextData(url)` + `setData`；成功 toast `link_copied`（沿用） |
| EDIT(2) → `en5.c` Edit hyperlink sheet | 选区设为链接段 `[run.start, run.end)` → `openLinkSheet()`（`linkUrlAt` 预填既有 URL → `linkSheetIsEdit=true` → Edit hyperlink 标题态） |
| REMOVE(3) → `removeHyperlinkFromSelection` | 选区设为链接段 → `removeLink()`（`applyLinkUrl(null, s, e)` 清除 `link` 字段） |

新增字符串键：`link_menu_edit`/`link_menu_remove`（base=原版文案
Edit/Remove；zh_CN=编辑/移除）。`link_open`/`copy_link`/
`link_open_failed`/`link_copied` 沿用 Phase 592 既有键。

## 3. 有界偏差（登记）

- 原版 hit-test 按**点坐标**命中链接段包围盒；Harmony 原生
  `TextArea` 无 tap 点几何 API，改为"tap 后折叠 caret 落入链接
  run"判定（`caret-1` 优先、`caret` 兜底——覆盖 tap 在链接首
  字符左侧/尾字符右侧的边界落点）。语义等价、机制适配。
- 原版菜单锚定链接段包围盒浮出；Harmony `showActionMenu` 为
  底部动作菜单（与 Phase 592 `pca` 路径同一有界偏差）。
- caret-区间命中仅在**折叠 caret**（无选区）时触发；按住
  拖选经过链接不弹菜单（`caretSelectionStart !== caretOffset`
  早退），避免打断文本选择——与原版 tap-on-link 语义一致
  （原版 drag-select 不弹链接菜单）。

## 4. 验证

- Replay：`d02-original-textblock-link-tap.mjs` 扩展至
  TOTAL=47（编辑表面路径 pins：helper、四项菜单同序、Edit→
  openLinkSheet 预填、Remove→removeLink、折叠 caret 门槛、
  双语言新键）。
- `note@default` HAP 构建成功（ArkTS 无新增错误）。
