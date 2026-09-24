# ADR-0637 — 原版分享面板任意页子集选择（v6d.l / r6d.PAGE_SELECTION）

日期：2026-09-24
状态：已实施（含 4 项文档化适配；PASSWORD_ENTRY/include_* 开关/
多笔记分享/LINK 继续登记）

## 决策

把分享面板的页范围从 P644 的"全部/当前页"二选升级为原版的
任意子集语义：`sharePageIndexes: number[] | null`（null=All，
对应 `v6d.l`）+ 面板内 `shareScreen` 屏态（对应 `r6d.MAIN/
PAGE_SELECTION`）+ 页范围行（"Page range" → All / "X of Y"）+
4 列缩略图勾选栅格（`SharePageCell`，tap 逐页 toggle）+
Select all/Deselect all + Done；导出签名 `allPages:boolean` →
`pageIndexes:number[]|null`，NOTE 恒整册。

## 证据锚点

`b7d.java`（`v6d.l`=Set\<Integer\> 页集合 null=全量；`q(i,z)`
null 先物化 V(0,m) 再增删；`l(i,i2)` 缩略图预取窗口；`j()/f()`
回 MAIN/清缓存；`pj(...,isPartial)` = set!=null && size!=m）、
`r6d.java`（MAIN/PAGE_SELECTION/PASSWORD_ENTRY）、`v6d.java`
（l/m/n/o/k/t 字段）、`strings.xml`（page_range/page_range_all/
page_range_selection="%1$d of %2$d"）。详见
`docs/migration/evidence/phase-670-original-share-page-subset.md`。

## 连带修正

- `d05-original-share-page-range/-page-image/-pdf/-editor-share`
  四个既有 fixture 的 `shareAllPages` 针脚同步更新为新签名。
- `share_range_current` 字符串移除（原版无"当前页"概念；
  单页导出由栅格子集表达）。

## 文档化适配（非 fail-closed）

1. 缩略图窗口 `b7d.l(i,i2)`（滚动区间限载）→ cell 懒取 +
   NotePage 侧串行渲染链（懒取即滚动驱动，规模可承受）。
2. `share_range_current` 快捷项移除——原版面板只有页范围行 +
   栅格；当前页导出 = 栅格仅勾当前页。
3. 空子集不发起导出（`resolveSharePages` 空→返回）；原版对
   空集合的导出行为未反编译到可判定层。
4. NOTE 行忽略页集合（.note 归档恒为整册，原版同）。

## fail-closed 保留

- `r6d.PASSWORD_ENTRY` + `v6d.k`（PDF 导出密码）、
  `v6d.i`/`v6d.j`（include_recording / include_background）、
  多笔记分享（`b7d(List noteIds)`）、LINK 格式 —— 登记后续。

## 验收

- 专项 `d05-original-share-page-subset.mjs` 25/25 绿；四个既有
  分享 fixture 更新后全绿。
- 全量 Desktop Replay、clean + note@ohosTest + note@default
  双 HAP 构建全绿。
