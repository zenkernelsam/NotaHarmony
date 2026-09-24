# Phase 670 — 原版分享面板任意页子集选择证据

日期：2026-09-24
对应 Replay：`docs/migration/replays/d05-original-share-page-subset.mjs`

## 原版证据（decompiled_1.0.3）

### 状态机与页集合

- `sources/defpackage/b7d.java` —— 分享面板 ViewModel（`cs0` 子类）：
  - `Q` = `v6d` 状态流；`v6d.l` = `Set<Integer>` 页索引集合，
    **null = 全部页**；`v6d.m` = 页总数；`v6d.n` = `r6d` 屏态。
  - `q(int i, boolean z)`：页 toggle —— `setW1 = W1(l ?? V(0, m))`
    （null 时先物化 0..m 全量集合）再 `add(i)`/`remove(i)`。
  - `l(int i, int i2)`：缩略图预取窗口——围绕滚动区间计算
    加载集合、写 `X` LinkedHashMap，`m()` 经 `uy7.l0(X)` 发布进
    `v6d.o`（栅格位图映射）。
  - `j()`/`k()`：回 MAIN 屏（前者连带清空 `X` 缩略图缓存 +
    `o` 置空映射）；`f()`：dismiss 清缓存。
  - 分享事件 `pj(format, j, i, isPartial)`：`isPartial =
    l != null && l.size() != m`；`v6d.i`/`v6d.j` = 两个随事件
    上行的布尔开关（include_* 选项）；`v6d.k` = 密码串
    （`o(str)`：`length()==0 → null`）。
- `sources/defpackage/r6d.java` —— 屏态枚举：
  `MAIN` / `PAGE_SELECTION` / `PASSWORD_ENTRY`。
- `sources/defpackage/v6d.java` —— 面板不可变状态：
  `l`(页集合)/`m`(页数)/`n`(屏态)/`o`(缩略图映射)/`k`(密码)/
  `t`(结果 Intent) 等。
- `strings.xml`：`ui_share__page_range`="Page range"、
  `ui_share__page_range_all`="All"、
  `ui_share__page_range_selection`="%1$d of %2$d"。
- 多笔记分享：`b7d(List noteIds)` —— `noteIds.size()>1` 时默认
  格式 PDF、单笔记默认 LINK（账号域 fail-closed 不变）。

## Harmony 对齐

- `EditorToolbar.ets`：
  - `shareScreen: 'main' | 'pages'` 对应 `r6d.MAIN/PAGE_SELECTION`。
  - `sharePageIndexes: number[] | null` 对应 `v6d.l`（null=All）。
  - MAIN 屏：`share_page_range` 行 + 动态值（`share_range_all` 或
    `share_range_selected` "%d of %d"）→ 点击进 `pages` 屏；
    五格式行不变（LINK 置灰 fail-closed）。
  - `pages` 屏：‹ 返回 + "X of Y" 计数 + Select all/Deselect all
    （null↔[]，对应原版 `z?null:qw3.I` 双向）+ Done 回 MAIN；
    4 列 `SharePageCell` 栅格（缩略图 + ✓/圈 勾选指示 + 页码），
    tap → `toggleSharePage`（b7d.q 等价：null 先物化全量再
    add/remove，增项后按页序排序）。
  - `bindSheet.onDisappear`：回 MAIN + 集合置 null（b7d.j/f 语义，
    每次打开全新会话）。
  - 分发：`onSharePdf/onShareImage` 签名 `allPages:boolean` →
    `pageIndexes:number[]|null`；NOTE 恒整册（v6d.l 不作用于
    .note 归档）。
- `NotePage.ets`：
  - `resolveSharePages(pageIndexes)`：null→`pages.slice()`；
    显式集合按页序过滤（越界索引自然丢弃）。
  - `requestShareThumbnail(page)`：懒建 `ThumbnailRenderer` +
    `shareThumbChain` 串行渲染（b7d.l 缩略图窗口等价物），
    `aboutToDisappear` 释放。
  - `sharePagesAsImages`/`shareNoteAsPdf` 改收页集合；子集为空
    直接返回（空导出无意义）。
- 字符串：`share_page_range` + `share_range_selected` 双语；
  移除被取代的 `share_range_current`。

## 适配差异（文档化）

1. 原版 PAGE_SELECTION 为面板内子屏（Compose 状态机）；Harmony
   同构——同一 bindSheet 内 `shareScreen` 切换。
2. 缩略图预取窗口 `b7d.l(i,i2)`（按滚动区间限载）→ Harmony 全部
   cell 各自懒取 + 串行链（MEDIUM 面板页数规模可承受；懒取即
   滚动驱动加载，语义等价）。
3. 原版的"当前页"概念不存在（仅 All/子集）；Harmony 此前
   P644 的 Current 二选移除，统一为 All/子集栅格——单页导出
   仍可在栅格中仅勾当前页达成。
4. 空子集（全不选）时页格式行点击导出 0 页——Harmony 在
   `resolveSharePages` 为空时直接返回（原版对空集合的行为
   未反编译到可判定层，fail-closed 为不导出）。

## fail-closed 保留

- `r6d.PASSWORD_ENTRY` + `v6d.k` 密码串 + `v6d.i`/`v6d.j`
  （include_recording/include_background 开关）+ LINK 格式 +
  多笔记分享（b7d `noteIds>1`）—— 继续登记（账号后端 / 导出
  选项面）。
