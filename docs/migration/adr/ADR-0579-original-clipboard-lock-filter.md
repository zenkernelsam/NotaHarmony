# ADR-0579 — 复制/剪切剔除 positionLocked 元素（lg2.g → jrh.a/ac4.Q）

- 状态：Accepted
- Phase 610；对齐 `lg2.g`/`jrh.a`/`dhb` case1/case4/`vsc`（decompiled_1.0.3）。

## 背景

原版剪贴板组装 `lg2.g(x09, ktc)` 在 `ac4.Q`（POSITION_LOCKED，
PRODUCTION 默认开）下先用 `jrh.a` 过滤 `ktc.h()` 扁平 id 集——
`oy0` 块 `t()`、可锁形状 `cih.a && n5d.t()` 剔除，`s06` 笔迹恒
false 不剔；边界 `a()`、拷贝 op `u5j.c`、组负载均基于过滤集。
`gg2(cg2, set)` 携过滤集返回，`dhb` case1 成功后 `fvb.a()` 清选区；
case4 DUPLICATE 走 `ftc.q`/`m` 原始列表，**不过滤**。

Harmony 旧实现：`prepareSelectedClipboard` 按请求 id 全量收集——
点选路径可选中锁定元素（Phase 608 证据：点按不过滤以保证 UNLOCK
可达），COPY/CUT 会把锁定元素带进剪贴板，CUT 还会将其删除。

## 决策

1. 新增 `clipboardSelectionWithoutLocked`：收集四类块
   `positionLocked === true` 的 id 得 `lockedIds`，形状/文本/图片/
   数学 id 列表 `filter` 剔除；笔迹列表原样返回；组 id 不在此层
   （`cqc` 不属 `oy0`/`n5d`，原版 `lg2.c` 组员递归照常解析拷贝）。
2. COPY 分支：过滤 → `copySelectedToClipboard` → 成功才
   `clearSelectionWithRegisterReset`；全锁选区过滤后为空 →
   `prepareSelectedClipboard` `selectedCount === 0` 返回 null →
   不写剪贴板不清选区（`g()`→null → 无写无清）。
3. CUT 分支：过滤集同时作剪贴板负载与移除目标——剪切删除集合
   = 拷贝集合（`gg2.set` 语义：剪切只搬走可拷元素，锁定元素
   留在页面并随 `fvb.a()` 失去选中）。
4. DUPLICATE 不过滤（`dhb` case4 原始列表）。

## 后果

- 混合选区复制：锁定元素不进剪贴板；剪切：锁定元素原地保留、
  其余元素搬入剪贴板；纯锁选区 COPY/CUT 均为空操作且选区保留。
- DELETE 不受影响（原版删除走 `mub`/`u5j` op，无 `jrh` 过滤证据）。

## 无法完全证明处

`lg2.d`（CUT 协程）字节码不可完全反编译；"删除目标=`gg2.set`"
为结构推断——`gg2` 的 `set` 字段仅剪切路径需要（COPY 只用
`cg2`）。备选读法（删除 `ktc.h()` 全集）会导致"删而未拷"数据
丢失，与锁定语义相悖，故按 `set` 实现；若后续版本反编译出相反
证据，再随 T-042 差异清单修正。

## 验证

- `docs/migration/replays/d02-original-clipboard-lock-filter.mjs`
  20 断言全绿；全量 Desktop Replay 499+1 全绿；
  `note@default` 与 `note@ohosTest` HAP 构建成功。
