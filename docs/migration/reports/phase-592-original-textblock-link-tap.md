# Phase 592 — 文本块链接点按 → [Open, Copy Link] 菜单

- 日期：2026-09-28
- 结果：已实现对齐（含 fail-closed 偏差记录）
- 证据：`docs/migration/evidence/original-textblock-link-tap-2026-09-28.md`
- ADR：`docs/migration/adr/ADR-0561-original-textblock-link-tap.md`
- Replay：`docs/migration/replays/d02-original-textblock-link-tap.mjs`（29 项断言）

## 背景

Phase 591 收尾 `dl1` 手势分发审计时发现 `ttc`（文本块命中）在各
分支走 `uw2` case4：`qke` TextBlock 事件 + `rej.i` 点按偏移 →
`hqe` 链接 span → `fke` 锚定 → `xj2.A` 弹出链接菜单。
`g1f` 的 `pca` 路径出 [Open, Copy Link] 两项（`wg7.OPEN/COPY_LINK`），
`ww2` 编辑表面出含 Edit/Remove 的四项。

Harmony 侧链接数据链早已完整（解码 → `RichTextCharacterStyle.link`
→ 下划线渲染），但点按交互从未移植——点按文本块只走
TapToSelect/套索，链接只是静态样式。

## 实现

- `Canvas2DTextRenderer.linkAtPoint`：复刻 `layoutLines` 行切分、
  行带 y 命中（`fontSize+8` 行高 × `lineSpacing`）、逐字
  `measureRange` x 偏移定位；`buildLinkHit` 扩展连续同 url span 并
  对跨行段逐行测宽合成世界包围盒。
- `NoteCanvasView`：
  - `linkHitOnTextBlock`/`textBlockLinkAt` 探测助手；
  - 选区外按下路径在 TapToSelect 之前拦截链接命中；
  - 无选区按下路径在套索开始之前拦截链接命中；
  - `showTextBlockLinkMenu`：`showActionMenu`（title=url）+
    `link_open`→`openLink`（失败 toast `link_open_failed`）、
    `copy_link`→`pasteboard` 纯文本（成功 toast `link_copied`）。
- 字符串：base/zh_CN 各增 `link_open`/`copy_link`/`link_open_failed`/
  `link_copied`。

## 偏差

见 ADR-0561 §偏差：菜单用 `showActionMenu` 底部动作菜单而非锚定
弹窗；`ww2` 编辑表面 Edit/Remove 未移植；`displayHandles` 把手态
未移植；非链接 `ttc` 聚焦语义未移植；行盒用 `fontSize+8` 近似。

## 验证

- `node docs/migration/replays/d02-original-textblock-link-tap.mjs` → 29/29。
- 全量 Desktop Replay、`note@default`、`note@ohosTest` 见 commit 记录。
