# ADR-1340：捆绑纸样集合区块（See all 钻入 / Current 徽记 / 空态语义）

- 日期：2026-09-21
- 状态：Accepted（部分近似，已注明）
- 关联：Phase 1404；前置 ADR-1338（收藏/最近）、ADR-1339（设为默认）

## 背景

Phase 1402 落地了捆绑纸样的收藏星标与最近列表，但与原版 PRESET tab
的集合区块存在三处可见差异：

1. RECENTS 区块恒渲染 —— 原版 `dt.java` case8 在列表为空时整块隐藏。
2. 无 "See all" 钻入 —— 原版 `s1a` case2 在非空集合尾随渲染
   `o9n` 文本钮，点击 `oe(bz5,ria)` → `buh.b=ria` → `x2n` 切到
   `u7n.d` 独立集合页（标题 + 网格 + `ria.G` 空态）。
3. Current 态用 accent 描边近似 —— 原版 `d2n.g`/`p9n.a` 渲染左下
   `eta` 渐变 chip + `ui_templates__current` 文本。

## 决策

### 实现（有硬证据部分）

- `GallerySection` 增加 `collection?: boolean`；RECENTS 区块仅非空时入列，
  FAVORITES 恒在并保留 `emptyRes`（`ria.G`）。
- 集合区块头尾随 "See all" 文本钮（`items.length > 0`），点击置
  `@State expandedSection` 为集合键 —— `buh.b=ria` 钻入等价。
- 钻入页：chevron_left 返回（`app.string.back` 无障碍）+ 集合标题 +
  整页 `cellGrid`；items 空时渲染 `ria.G` 专属空态
  （`u7n.d zIsEmpty → c(ria.G)`）。
- cell `current` 由 accent 描边改为 BottomStart 圆角 "Current" 徽记。

### 近似（fail-open，已注明）

- 原版 Current chip 为 `eta` 渐变（端点主题色 `a.b.a→a.c.a`）；
  ArkUI 实现用纯色 `accent` 圆角徽记近似，视觉层级一致。
- 原版 `h2n.a` 收藏心形弹跳动画未移植 —— 纯动效，无语义。

### 维持 fail-closed

- `y07` "See more"（云端分页加载）、`ia6`/`xcm` `search_gallery`
  （GALLERY tab 搜索）、MY_TEMPLATES tab —— 均依赖云端/上传后端，
  继续 fail-closed。

## 后果

- 主列表集合行为与原版逐条对齐（隐藏/See all/空态/钻入/返回）。
- 新增 en/zh 字符串 `paper_templates_see_all`、`paper_templates_current`。
- `d02-original-paper-template-collections.mjs`（16 checks）锁定本阶段契约。
