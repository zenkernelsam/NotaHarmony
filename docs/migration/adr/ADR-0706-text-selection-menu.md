# ADR-0706：文本选区菜单定制项（tqe.a() 尾部三项）

- 日期：2026-09-28
- Phase：758
- 状态：Accepted
- 证据：`docs/migration/evidence/phase-758-text-selection-menu.md`
- 关联：Phase 622（空白处长按照 {PASTE,SELECT_ALL}）、ADR-0705
  （编辑表面链接四项菜单）

## 背景

原版文本编辑表面的选区上下文菜单是自定义 `ActionMode`
（`q39`/`r39.j`）：非折叠选区产出 `tqe.a()` 全量枚举
[CUT, COPY, PASTE, SELECT_ALL, LINK, HIGHLIGHT, REMOVE_HIGHLIGHT]
，其中 PASTE 需 `hasPrimaryClip`、REMOVE_HIGHLIGHT 需 `eh5.b`
（选区高亮态）。Harmony 原生 `TextArea` 此前只有系统默认项。

## 决策

1. **`editMenuOptions`（API12+）**：`onCreateMenu` 在系统项尾部按
   `tqe` 序追加 `LINK(4)`/`HIGHLIGHT(5)`/`REMOVE_HIGHLIGHT(6)`
   定制项（`TextMenuItemId.of` 自定义 id）——系统四项原生承担。
2. **折叠 caret 不追加**：原版折叠态菜单仅 [PASTE, SELECT_ALL]，
   系统菜单已等价覆盖。
3. **REMOVE_HIGHLIGHT 门**：`rangeIntersectsHighlight`（选区与任一
   `highlightColor` run 相交）≈ `eh5.b`。
4. **HIGHLIGHT 施加 `eh5.a` 当前色**：新增 `@State
   lastHighlightColor`（默认调色板黄 `1716898048`，语义对齐
   `iu1.i = 0xFFFFFF00`），`toggleHighlightColor` 单一漏斗内更新
   ——调色板/最近色/HSV 三入口全覆盖。
5. **dispatch**（`onTextSelectionMenuItem`）：LINK → 选区置
   `range` → `openLinkSheet`（en5.c 预填路径复用）；HIGHLIGHT →
   `applyHighlightColor(lastHighlightColor)`；REMOVE →
   `applyHighlightColor(null)`。返回 true = `r39` finish 消费语义。

## 偏差

- 锚定呈现交给 ArkUI 选区菜单（原版 `onGetContentRect` 手工锚定
  选区包围盒——语义等价）。
- `rbb.m()` 剪贴板动态载荷项 fail-closed（同 Phase 622 登记）。
- `eh5.b` 为相交判定近似（原版内部语义为"高亮态标志"）。

## 验证

- `d02-original-text-selection-menu.mjs`：tqe 序数/门控/分发钉死。
- 全量 Desktop Replay 见提交；`note@default`/`note@ohosTest` HAP
  构建通过。
