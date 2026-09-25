# ADR-0561 — 文本块链接点按 → [Open, Copy Link] 菜单

- 状态：Accepted
- Phase 592；对齐 `dl1` ttc 分支/`uw2` case4/`rej.i`/`sqa`/`g1f` pca/
  `wg7`/`n94`/`vm5`（decompiled_1.0.3）。

## 背景

原版文本块中的链接 span（`ti3` 内 `ri3`）在点按时经
`rej.i` 偏移映射命中 → `fke` 锚定 → 弹出锚定菜单。`pca` 链接点击
路径出 [Open, Copy Link] 两项；`ww2` 编辑表面出 [Open, Copy Link,
Edit, Remove] 四项。

Harmony 链接数据链早已完整：`OriginalRichTextStyleOperation` 解码
字段 10 → `RichTextCharacterStyle.link` → `Canvas2DTextRenderer`
下划线渲染。缺的是点按交互。

## 决策

- `Canvas2DTextRenderer.linkAtPoint`：复刻 `layoutLines` 行切分 +
  逐字 `measureRange` 测宽做"世界点 → 字符偏移"映射；命中链接时
  `buildLinkHit` 扩展连续同 url span 并合成跨行世界包围盒
  （`fke` 锚定的几何等价物）。
- `NoteCanvasView` 两条 `ttc` 等价路径前置链接探测：
  选区外按下（`linkHitOnTextBlock`，先于 TapToSelect）与无选区按下
  （`textBlockLinkAt`，先于套索开始）。命中 → `showActionMenu`
  [link_open, copy_link]；未命中 → 保持既有行为。
- Open → `UIAbilityContext.openLink(url)`，失败 toast
  `link_open_failed`（对齐 `error_unable_to_open_link`）。
- Copy Link → `pasteboard` 写纯文本，成功 toast `link_copied`。

## 偏差（fail-closed 记录）

1. 菜单呈现为底部 `showActionMenu` 而非链接段锚定弹窗——语义等价。
2. ~~`ww2` 编辑表面的 Edit/Remove 两项未移植~~ —— 已被
   ADR-0705（Phase 757）取代：折叠 caret → link run 探测 +
   wg7.N 四项菜单已移植。
3. `tqa`/`displayHandles` 文本块把手态未移植（无该把手层）。
4. 非链接 `ttc` 的文本块激活/聚焦语义未移植——Harmony 维持
   TapToSelect；属更大 epic，本阶段仅拦截链接命中。
5. 行带命中用 `fontSize+8` 行高近似原版布局行盒（`ti3` 行盒不可达）；
   跨行链接段取逐行测宽并集。

## 验证

- `docs/migration/replays/d02-original-textblock-link-tap.mjs` 29 项断言。
- 证据：`docs/migration/evidence/original-textblock-link-tap-2026-09-28.md`。
