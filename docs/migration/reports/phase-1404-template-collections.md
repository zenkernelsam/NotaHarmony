# Phase 1404 报告 — 捆绑纸样集合区块细节（See all 钻入 + Current 徽记）

## 范围

PRESET tab 捆绑纸样画廊与原版 `dt`/`m56`/`zia`/`s1a`/`u7n`/`d2n` 的
剩余保真差异收口：集合空态语义、"See all" 钻入独立集合页、
Current 徽记形态。

## 原版证据

- `ria.java`：集合枚举 FAVORITES/RECENTS/CUSTOM，`F`=标题 res、
  `G`=空态 res。
- `dt.java` case8：RECENTS 空时整块隐藏；FAVORITES 恒在。
- `m56`/`zia`：`bbn.b` 区块（标题 + See all 尾随 + 内容/空态）。
- `s1a` case2：`o9n` "See all" 文本钮 → `oe(bz5,ria)` → `buh.b=ria`。
- `u7n.d`：独立集合页（标题 + 网格 + `ria.G` 空态兜底）。
- `d2n.g`/`p9n.a`：Current 为左下 `eta` 渐变 chip + `ui_templates__current`，
  非描边；`h2n.a` 仅为收藏心形动画。

## Harmony 落点

`note/src/main/ets/ui/editor/PaperTemplateGallery.ets`：

- `sections()`：RECENTS 空隐藏、`collection` 标记、FAVORITES 恒在。
- `@State expandedSection` + `expandedItems()`/`expandedEmptyRes()` +
  `@Builder cellGrid()`：主列表 ↔ 钻入页切换。
- 区块头 Row：标题 + 右侧 "See all"（仅非空集合）。
- 钻入页：返回钮（`chevron_left`/`back`）+ 集合标题 + 网格/空态。
- cell Current：accent 描边 → BottomStart accent 圆角 "Current" 徽记
  （渐变端点主题色，纯色近似已注明）。
- 字符串：`paper_templates_see_all`/`paper_templates_current`（en+zh）。

## 未移植（fail-closed）

- "See more" 云端分页、`search_gallery` GALLERY 搜索、MY_TEMPLATES、
  收藏心形动画 —— 依赖云端/纯动效。

## 验证

- 新 fixture：`d02-original-paper-template-collections.mjs` 16 checks 绿。
- 既有三 fixture（1401/1402/1403）不受影响全绿。
- 全量基线 1256/1256；`note@default`、`note@ohosTest` clean build 成功。

## 遗留

- GALLERY/MY_TEMPLATES tab（云端/上传）维持 fail-closed。
- Current 徽记渐变 → 纯色近似（ADR-1340 登记）。
