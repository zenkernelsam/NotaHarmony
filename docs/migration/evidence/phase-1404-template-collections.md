# Phase 1404 证据 — 捆绑纸样集合区块细节 / See all 钻入 / Current 徽记

Phase 1402/1403 与原版收集到的剩余差异，`decompiled_1.4.2` 硬证据：

## 集合区块语义（dt + m56 + zia）

`ria` 集合枚举：`FAVORITES / RECENTS / CUSTOM`，各持 `F`（区块标题 res）
与 `G`（空态文案 res，`ria.G`）。

- `dt.java` case8：主列表分页器遍历 `ria.K` 时过滤条件
  `ria != RECENTS || !recents.isEmpty()` —— **RECENTS 区块空时整块隐藏**；
  FAVORITES 恒在（空时渲染 `ria.G` 空态文案）。
- `m56`/`zia`：集合区块渲染 = `bbn.b(ria.F 标题, 尾随 See all, 内容)`；
  `zia` 内 `awa==null && listG 空 → u7n.c(ria.G)` 空态，否则逐项 `u7n.b`。
- `s1a` case2：`bbn.b` 尾随的 "See all" `o9n` 文本钮仅当 `listG` 非空时渲染；
  点击 → `oe(bz5, ria)` → `buh.b = ria` → `x2n` 切到 `u7n.d` 独立集合页。
- `u7n.d(ria)`：集合标题 + See all + 整页网格；`zIsEmpty → c(ria.G)`
  （钻入页自身空态）。
- `y07` "See more" 为另一回调（云端页流），与 "See all" 同形态。

## Current 徽记（d2n + p9n.a）

`d2n.g`：`qgc.c`（isCurrent）命中时左下渲染 `eta` 渐变 chip
（端点主题色 `a.b.a → a.c.a`）+ 本地化 `ui_templates__current` 文本。
Phase 1402 曾以 accent 描边近似 —— 本阶段改为原版徽记形态。
`h2n.a` 收藏心形为纯动画，无可移植语义。

## 本阶段落点（PaperTemplateGallery.ets）

- `sections()`：RECENTS 仅 `recentItems.length > 0` 时入列；
  FAVORITES 恒在并带 `emptyRes`；集合区块 `collection: true`。
- `@State expandedSection`：`''` = 主列表；`'recents'`/`'favorites'` =
  `u7n.d` 钻入页（chevron_left 返回 `app.string.back` + 集合标题 +
  整页网格 + `ria.G` 空态兜底）。
- 区块头 Row：标题左、`paper_templates_see_all` 文本钮右，
  仅 `collection && items.length > 0`。
- cell `current` 由 accent 描边改为 BottomStart accent 圆角
  `paper_templates_current` 徽记（原版渐变端点为主题色，
  纯色近似已在注释中说明）。
- `ia6`/`xcm` `search_gallery` 属云端 GALLERY tab —— 维持 fail-closed。

## 字符串

| key | en | zh_CN |
|---|---|---|
| paper_templates_see_all | See all | 查看全部 |
| paper_templates_current | Current | 当前 |

返回钮复用 `app.string.back`；关闭钮复用 `cd_pages_panel_close`。

## 验证

- `d02-original-paper-template-collections.mjs` — 16 checks（新）
- 既有三 fixture（gallery/favorites/default）全绿
- 全量 Desktop Replay：REPLAY_BASELINE PASS=1256 FAIL=0
- `note@default` / `note@ohosTest` clean build 成功
