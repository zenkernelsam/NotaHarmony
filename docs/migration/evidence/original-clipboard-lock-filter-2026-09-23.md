# 证据：复制/剪切剔除 positionLocked 元素（lg2.g → jrh.a/ac4.Q）

日期：2026-09-23 · Phase 610

## 原版调用链（decompiled_1.0.3/sources/defpackage）

`dhb` 选区菜单 case1(COPY) 与 `vsc`(CUT，`lg2.d` 协程) 都经
`lg2.g(x09, ktc)` 组装剪贴板负载：

| 位置 | 行为 |
| --- | --- |
| `lg2.java:110-123` | `lc4.a(ac4.Q)`（POSITION_LOCKED，PRODUCTION 常量默认开）时，对 `ktc.h()` 的扁平 id 集合逐个 `jrh.a(be5)` 过滤，得到 `set` |
| `jrh.java:13-22` | `a(be5)`：`oy0` 块 → `t()`（positionLocked）；`m4d` 形状 → `cih.a && n5d.t()`；其余（`s06` 笔迹）→ `false` |
| `lg2.java:124` | `a(x09, set)` 只对过滤后集合求联合边界 |
| `lg2.java:143-155` | `iterableL0`（`ftc.m`/`gtc` 包装的 cqc 组结构）经 `c()` 递归解析组员——组员不在 `set` 时仍可经 `h85Var.M()`/`tl7.I` 解析进 `arrayList3`，即组内锁定成员照常随组负载拷贝（与 `fu1.c` 组扩展不二次过滤一致） |
| `lg2.java:155-168` | `u5j.c(x09, set+arrayList3, placement)` 产出拷贝 op 列表；`gg2(cg2, set)` 返回负载携过滤后 `set` 字段 |
| `dhb.java:17615-17629` | case1 COPY：`g()` 非空 → `c.a=cg2` 写剪贴板 + `fvb.a()` 清选区；`g()` 为空（全锁→`a()` 无界→null）→ 不写也不清 |
| `dhb.java:17638-17652` | case4 DUPLICATE：直接取 `ftc.q`/`ftc.m` 原始 id 列表走 `kk9` 协程，**不经** `jrh.a` —— DUPLICATE 不过滤锁定元素 |
| `vsc.java:52-58` | `vsc.I=0` → `lg2.d`（CUT）；`d` 为协程字节码不可完全反编译，但 `gg2` 第二字段 `set` 只为 `d` 携带（`b`/COPY 只用 `cg2`），按结构推断剪切的删除目标即过滤后集合 |

## Harmony 移植前差异

`prepareSelectedClipboard` 按请求 id 全量收集——点选到的锁定元素
（区域选区已在 Phase 608 剔除，但点按路径不过滤以便 UNLOCK 可达）
会被复制进剪贴板；CUT 同时删除整个选区（含锁定元素）。

## 对齐实现

- `clipboardSelectionWithoutLocked`：按 `positionLocked === true` 收集
  形状/文本/图像/数学块 id 得 `lockedIds`，四类 id 列表 `filter` 剔除；
  笔迹列表原样返回（`jrh.a(s06)` 恒 false）；组 id 不在此层处理。
- COPY（`onSelectionMenuAction` COPY 分支）：过滤后
  `copySelectedToClipboard`；全锁选区 → 空集 → `prepareSelectedClipboard`
  `selectedCount === 0` 返回 null → 不写剪贴板不清选区（`g()`→null 同义）。
- CUT：过滤后的列表同时供 `prepareSelectedClipboard` 与移除循环——
  剪切删除集合 = 剪贴板负载集合（`gg2.set`）。
- DUPLICATE（`duplicateSelected`）：保持未过滤——原版 case4 用原始
  `ftc.q`/`m` 列表。

## 无法完全证明处（fail-closed 说明）

`lg2.d` 删除目标取 `gg2.set` 而非 `ktc.h()` 为结构推断（`gg2` 只为
剪切路径携带 `set` 字段）。若原版实际删除未过滤全集，Harmony 将保留
锁定元素——该行为与"锁定即防改动"语义一致，且避免"删而未拷"的数据
丢失，作为 fail-closed 选择记录于 ADR-0579。
