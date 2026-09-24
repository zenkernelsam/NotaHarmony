# Phase 685 — 原版上下标互斥切换（Subscript/Superscript）移植

## 范围

P684 落地 B/I/U/S 单字段切换；本期把同一格式行的互斥对——Subscript/
Superscript——补进 `TextBlockOverlay`，并复刻原版 `zyd` 同包显式 FALSE
的原子互斥语义。至此 `l32` 格式行 case2-6 的字符样式项全部落地
（indent/link/高亮/字体留待后续期）。

## 原版行为（证据见 phase-685 evidence）

- `cve.java`：`kue`(superscript)/`lue`(subscript) → `n(new zyd(...))`。
  **启用**：同包写本字段 `TRUE` + 兄弟显式 `FALSE`（mask 1279）——互斥
  原子完成；**停用**：只写本字段 `FALSE`（mask 1535/1791）。
- `zyd.i` = subscript、`zyd.j` = superscript（由启用分支参数位定）。
- `br2.e`/`br2.f` 分别为 sub/super 当前态。
- `l32` 行序：indent+、indent-、italic、underline、**subscript**、
  **superscript**、strikethrough。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `charStyleValue`/`charStyleSet` 补 sub/super 分支；新增 `charStyleHas`
    区分"未设置"与"显式 false"。
  - `toggleCharStylePair(field, other)`：选区启用 → 同范围
    `applyCharStyle(field,true)` + `applyCharStyle(other,false)`；停用只清
    本字段；折叠光标 pending 同语义（pending 内兄弟显式 false）。
  - `onChange` pending 落地改为按 `charStyleHas` 应用存在字段的**实际值**
    ——含显式 false，修复了插入段继承 run 兄弟字段导致 sub+super 同真的
    边界缺陷。
  - `caretCharSub`/`caretCharSuper` 按钮态；sub/super 按钮按 l32 行序插在
    underline 与 strikethrough 之间。
- 资源：`subscript`/`superscript` en+zh（下标/上标）。
- 渲染器此前已支持（基线偏移 + 0.75 字号），无需改动。

## 验证

- Replay：`d02-original-sub-superscript.mjs` 19 项全绿；P684 fixture 的
  pending 落地钉同步更新为 `charStyleHas` 语义（34/34 仍绿）；
  lease-bound enabled 计数 12→14。
- 构建：`note@default` assembleHap BUILD SUCCESSFUL；`note@ohosTest`
  clean 构建见提交记录。
- 真机/模拟器：未验证（约束内）。

## 限制

- 沿用 ADR-0650 登记差异（pending 清除时机、CRDT 编码器缺口）。
- `l32` 行首的 increase/decrease indent（`h5a` 段落级缩进）本期未覆盖。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/{base,zh_CN}/element/string.json`
- `docs/migration/replays/d02-original-sub-superscript.mjs`
- `docs/migration/replays/d02-original-character-styles.mjs`
- `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
