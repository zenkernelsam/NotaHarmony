# ADR-0583 — 复制/剪切对含锁定成员的 Group 弃组不散件（lg2.c）

- 状态：Accepted
- Phase 614；对齐 `lg2.g`/`lg2.c`/`itc`/`gtc` ktc 三集（decompiled_1.0.3）。

## 背景

Phase 610 把 `jrh.a`/`ac4.Q` 锁过滤搬进 COPY/CUT 的扁平 id 集。
但 `lg2.g` 还有第二步：选中的 `cqc` 组列表逐组过 `lg2.c` 递归
解析——**组成员闭包必须全部落在过滤后集合内**，任一成员被剔
（positionLocked、非组非实体）即整组解析失败，组 id 不进
`arrayList3`（负载）与 `arrayList5`（`cg2` 组清单，粘贴据此
恢复组）。存活成员仍在扁平集内，照常复制，粘贴后为散件。

Harmony 旧实现只过滤扁平 id，`selectedGroupIds` 原样进
`prepareCopy`；`copyOriginalGroupGraph` 发现任一组成员不在
`copiedLeafIds` 即返回 null → `prepareCopy` null → COPY 不写
剪贴板、CUT 整单静默失败。比原版更严（整单失败 vs 仅弃组）。

## 决策

1. `ClipboardSelectionIdSet` 增加 `groupIds: string[]`；
   `clipboardSelectionWithoutLocked` 接收选中组 id 并调用
   `copyResolvableGroupIds`。
2. `copyResolvableGroupIds` 按 `lg2.c` 语义递归：kept 扁平集
   或已解析组命中 → true；failed/visiting（环防御）/非组 id/
   空成员组 → false；组成员全过 → resolved。仅 `resolve()`
   为真的组进入 `kept.groupIds`。
3. COPY 写 `kept.groupIds`；CUT 的 `prepareSelectedClipboard`
   同样改传 `kept.groupIds`。
4. DUPLICATE 不动——`dhb` case4 使用 `ftc.q/m` 原始集，不经
   `lg2.g`/`jrh.a` 路径（Phase 610 已登记）。

## 边界

- 弃组后散件照常复制/剪切：与原版一致（`set` 仍含未锁成员），
  粘贴不再成组（组不在 `arrayList5`）。
- 环防御：原版 `lg2.c` 无 visiting 集（损坏数据会无限递归）；
  Harmony 加 `visiting` → false，fail-closed，不影响合法数据。
- 嵌套组：失败沿成员闭包传染，与 `z=false` 传播一致。

## 验证

- 桌面 replay：`docs/migration/replays/d02-original-clipboard-group-resolve.mjs`，17/17。
- `note@default`/`note@ohosTest` 构建绿；全量 replay 套件绿。
