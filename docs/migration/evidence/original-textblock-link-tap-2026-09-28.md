# 原版证据：文本块链接点按 → 锚定菜单 [Open, Copy Link]

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 592 依据。

## 1. 点按分发（`dl1.java`）

各 `ftc`/`gtc`/无选区分支中，`ttc`（文本块实体命中结果）→
`new uw2(xtcVar, (ttc) ttcVar, z2, 4)`（出现于 138/174/205/260/312/358
共 6 处分支）——文本块点按是独立命中类别，与 `otc`（普通元素）/
`ntc`（组）区分。

## 2. 文本块点按处理（`uw2.java` case4）

```java
xtcVar2.d(new qke(ttcVar.a), true, z);        // TextBlock 事件（qo5 块 id）
ake akeVar = (ake) xtcVar2.e.t.I.getValue();  // 当前活动文本块
if (akeVar != null && (ekeVar = akeVar.r) != null &&
    (yqaVar = ekeVar.h) != null) {
  long j = ttcVar.b;                          // 点按位置
  uub uubVar = (uub) yqaVar.a.getValue();     // 文本布局态（ti3）
  if (uubVar != null) {
    yqaVar.g.m(new sqa(rej.i(zn9.f(j, uubVar.f), uubVar.e), 0));
    yqaVar.b.b(new tqa(uubVar, 0));           // 切 CursorDisplayState
  }
}
```

- `rej.java:261` `rej.i(j, ti3)`：点按坐标 → 文本偏移 → `hqe`（int 范围
  `{I=offset, J=length}`）。
- `sqa`：`dgj.d(jtc, hqe)` —— 命中链接段以 `fke(hqe,hqe)` 锚进文本块态。
- `tqa`：`hr2(CursorDisplayState)` 的 `displayHandles` 切换（非编辑态
  `!vej.c(e)` 时打开把手）。

## 3. 链接菜单（`g1f.java` / `ww2.java` / `wg7` / `n94`）

- `g1f.java:240-246`：`pca` 链接点击事件 → `xj2.A(g39.a, ns(…))`
  锚定弹出菜单，项集 `m18.m0(wg7.OPEN, wg7.COPY_LINK)` =
  **Open / Copy Link 两项**。
- `ww2.java:350`：文本块编辑表面内计算链接段包围盒
  （`z1g`/`l96.A0`）锚定后弹 `wg7.N` 全枚举 =
  Open/Copy Link/**Edit/Remove** 四项。
- `wg7.java`：链接菜单枚举 OPEN(0)/COPY_LINK(1)/EDIT(2)/REMOVE(3)。
- `n94.java:240-250`：文案 `link_menu_open`="Open"、
  `link_menu_copy_link`="Copy Link"、`link_menu_edit`、
  `link_menu_remove`。
- `vm5.java`：`OpenLinkClicked(url=…)`；`cq.java:2322+` 失败时
  `error_unable_to_open_link`。

## 4. 链接数据来源

- `ti3`（文本布局）的 `ri3` span 列表 = 链接段；`rej.i` 按
  code-point 偏移检索。
- Harmony 等价物：`RichTextCharacterStyle.link`（
  `OriginalRichTextStyleOperation` 解码字段 10 链接字符串），
  `Canvas2DTextRenderer:370` 已按 `style.link !== undefined` 画下划线。

## 5. Harmony 对齐（Phase 592）

| 原版 | Harmony |
|---|---|
| `ttc` 文本块命中 → `qke` + 链接探测 | `topmostPageElementIdAt` 命中文本块 → `linkHitOnTextBlock`（选区外按下）/ `textBlockLinkAt`（无选区按下） |
| `rej.i` 偏移 → `hqe` span | `Canvas2DTextRenderer.linkAtPoint`：复刻 `layoutLines` 行切分与逐字测宽，行带 y 命中 + x 偏移定位字符，查 `characterStyles[i].link` |
| `fke(hqe,hqe)` 链接段锚定 | `buildLinkHit` 连续同 url span 扩展，跨行逐行测宽合成世界包围盒 `worldRect` |
| `xj2.A` 锚定弹出 [Open, Copy Link] | `promptAction.showActionMenu`（title=url）+[link_open, copy_link] |
| `OpenLinkClicked` → 系统打开 | `UIAbilityContext.openLink(url)`；失败 toast `link_open_failed` |
| `link_menu_copy_link` | `pasteboard.createPlainTextData` + `setData`；成功 toast `link_copied` |

## 6. 有界偏差

- 原版菜单锚定在链接段包围盒；Harmony 用 `showActionMenu` 底部动作
  菜单（语义等价、呈现不同）。
- 原版 `pca` 只出 [Open, Copy Link]；`ww2` 编辑表面另出
  [Edit, Remove]——本阶段只移植 `pca` 路径。
  ⚠️ 已被 Phase 757 取代：`ww2` 编辑表面四项菜单已移植
  （`phase-757-textblock-edit-link-menu.md`、ADR-0705）。
- `tqa` 的 `displayHandles` 文本块把手态未移植（Harmony 无该把手层）。
- 非链接的 `ttc`（文本块激活/聚焦）未改变既有 TapToSelect 行为——
  原文本块聚焦表面属更大 epic，本阶段只拦截链接命中。
