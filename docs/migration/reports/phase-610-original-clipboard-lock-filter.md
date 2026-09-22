# Phase 610 — 复制/剪切剔除 positionLocked 元素（lg2.g → jrh.a）

- 日期：2026-09-23
- 结果：已实现对齐（CUT 删除目标为 fail-closed 推断，见 ADR）
- 证据：`docs/migration/evidence/original-clipboard-lock-filter-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0579-original-clipboard-lock-filter.md`
- Replay：`d02-original-clipboard-lock-filter.mjs`（20 项断言）

## 背景

原版剪贴板组装 `lg2.g(x09, ktc)` 在 `ac4.Q`（POSITION_LOCKED，
生产常量默认开）下先以 `jrh.a` 过滤 `ktc.h()`：`oy0` 块 `t()`
与可锁形状 `cih.a && n5d.t()` 剔除，`s06` 笔迹恒 false；边界、
拷贝 op、组负载全基于过滤集。`dhb` case1 COPY 成功后
`fvb.a()` 清选区；`g()` 为空（全锁）则既不清选区也不写剪贴板。
case4 DUPLICATE 用 `ftc.q`/`m` 原始 id 列表，不经 `jrh.a`。

Harmony 旧实现 `prepareSelectedClipboard` 按请求 id 全量收集：
点按选中的锁定元素（区域选区 Phase 608 已剔、点按仍可达以便
UNLOCK）会被 COPY 进剪贴板、被 CUT 复制并删除——与原版
"锁定元素不进剪贴板负载"不符。

## 实现

- `clipboardSelectionWithoutLocked`：四类块按 `positionLocked`
  收集 `lockedIds` 并 `filter` 剔除对应 id 列表；笔迹列表原样
  返回；组 id 不在此层（原版 `lg2.c` 组内成员递归照常解析）。
- COPY：过滤 → `copySelectedToClipboard` → 成功才清选区；
  全锁选区过滤为空 → `selectedCount === 0` → null → 不写不清。
- CUT：过滤集同时作剪贴板负载与移除目标（`gg2.set` 语义）——
  锁定元素留在页面、其余搬走，选区照常清空。
- DUPLICATE：不过滤（`dhb` case4 原始列表）。

## 与 Phase 608 的关系

608 管"区域选区不圈入锁定元素"；610 管"已含锁定元素的选区
（点按构成）复制/剪切时不携带它们"。两者共用 `jrh.a`/`ac4.Q`
语义，覆盖面互补。

## 验证

- Replay 新增 20 断言；全量 Desktop Replay 500/500 全绿。
- ArkTS 静态检查：`note@default` 构建通过；`note@ohosTest`
  构建通过。
- 边界用例：纯锁选区 COPY/CUT 空操作且选区保留；混合选区
  CUT 后锁定元素仍在页面（未被删除、未被拷贝）。
