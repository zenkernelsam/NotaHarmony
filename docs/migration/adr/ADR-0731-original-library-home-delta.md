# ADR-0731 — 原版 1.4.2 库主页增量登记（Coming-Up/滑动操作）

日期：2026-09-29
状态：已登记（版本差·本地/边界分层；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-787-original-library-home-delta.md`
Replay：`docs/migration/replays/d02-original-library-home-delta.mjs`

## 背景

`feature_library__` +57 差集归属：Coming-Up 日历区块十键、
考试复习区块、列表滑动操作三键、a11y/入口配套。

## 决策

1. **Coming-Up/考试区块**：日历+syllabus 后端/系统权限边界，
   fail-closed 随 765/772 族。
2. **滑动删除/收藏**：明确未移植的本地 UX 差——ArkUI
   `swipeAction` 可等价——登记为版本差·本地候选
   （回移评审待定）。
3. a11y/入口名增量随族登记。
4. 本阶段不实现。

## 后果

- feature_library__ 差集全部归属；滑动操作为首个被定位的
  "纯本地但原版已做而 Harmony 未做"的库 UX 差。
