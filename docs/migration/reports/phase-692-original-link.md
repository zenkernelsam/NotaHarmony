# Phase 692 — 原版链接（tte / aue / en5 → zyd.h）移植

## 范围

`zyd` 最后一个未移植字段 `h`（link）补进 `TextBlockOverlay`：链接
sheet（URL+标题）→ `replaceSelectedText` 语义替换选区并写
`{link:url}` run；Remove Link 清选区链接字段。至此 `zyd` 全部
11 字段（a~k）均有 Harmony authoring 入口。

## 原版行为（证据见 phase-692 evidence）

- `tqe.LINK(4)` 选择菜单 → `tm5`→`en5{title,url,edit}` 对话框态，
  `edit`=标题非空；`um5`→`mte` 编辑既有链接（预填 url+title）。
- `tte`（OnHyperlinkConfirmed）→ `fm7.l(linkTitle, zyd{link:url})` =
  `replaceSelectedText`：选区替换为标题文本 + 写链接样式。
- `aue`/`wm5` → `removeHyperlinkFromSelection` 清选区链接。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `applyLinkUrl(url|null)`：区间三切分写 `link`；`null`→`undefined`
    （JSON 归并剔空），非 null gap-fill `{link:url}`。
  - `linkUrlAt(s,e)`：首个携 link run 的 url（编辑预填，um5→mte 语义）。
  - `openLinkSheet()`：预填标题=选中文本、url=既有链接；sheet 弹出。
  - `confirmLink()`：`draftText` 选区（或折叠光标处）替换为标题 →
    `adjustCharRunsForEdit` 差分平移既有 run → `applyLinkUrl` 写插入段
    → 光标落标题尾 → `onDraftChange` 同步草稿 —— 忠实
    `replaceSelectedText` 语义。
  - `removeLink()`：`applyLinkUrl(null)` 清选区 link（aue 语义）。
  - `buildLinkSheet()`：URL+Link title 双 `TextInput`；Add Link
    `enabled(url非空 && title非空)`（en5.c 标题必填语义）；Remove Link。
  - `Link` 钮置 Color 之后、列表装饰之前。
- 新增字符串 ×5（en/zh）：`text_link`/`link_url_hint`/`link_title_hint`/
  `add_link`/`remove_link`。

## 验证

- Replay：`d02-original-link.mjs` 18 项全绿；lease-bound enabled
  计数 23→25（Add 钮为复合条件不计入字面值匹配）。
- 构建：`note@default` assembleHap BUILD SUCCESSFUL；`note@ohosTest`
  clean 构建见提交记录。
- 真机/模拟器：未验证（约束内）。

## 限制

- 链接点击/打开交互（`vm5`/`sm5` emit 路径、长按弹出编辑/移除菜单）
  未实现——authoring 已完整，交互打开属后续 Phase。
- 链接无下划线/蓝色专属渲染差异：renderer 仅识别 link run 存在性，
  视觉上与原版的链接样式区分有限（记 evidence）。
- 沿用 ADR-0648/0650 登记差异。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`
- `docs/migration/replays/d02-original-link.mjs`
- `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
