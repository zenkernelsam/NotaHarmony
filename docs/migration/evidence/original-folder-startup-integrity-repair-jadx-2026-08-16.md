# 原版文件夹不变量与 Harmony 启动修复证据（2026-08-16）

## 范围

本证据对应 M2-U-05 / ADR-0232。原版证据用于定义合法 folder tree；Harmony 侧额外处理旧版本、恢复数据或历史 bug
留下的损坏数据库。涉及 `FolderHierarchyRepair.ets`、`DatabaseManager.ets` 与 `FolderRepository.test.ets`。

## 原版不变量

- `e47.java:353-354` 的 folder metadata 同时保存 parent 与 siblingOrder，树关系和同级顺序都是持久状态。
- `beb.java:133-152` 在同一父级校验名称；`:154-171` 递归 children 计算子树高度。
- `xdb.java:87-109,124-144` 在移动前阻止自身子树并执行六层上限，再按 child index 生成 position。

因此合法状态至少要求：parent 存在且无环、路径不超过六层、同父 children 有确定顺序。原版源码没有证明会对任意
损坏 Room 数据执行自动恢复，所以 Harmony 修复策略必须明确标记为防御适配。

## 损坏来源与旧实现缺口

- v9 migration 只在 schema 版本变化时运行；已升级用户不会再次进入。
- 外部备份恢复、旧版 foreign_keys 关闭、手工数据库和历史移植 bug 可能留下 orphan、自引用或 cycle。
- fractional/重复/空洞 siblingOrder 虽不一定违反外键，却会让 UI 顺序、child index 和后续移动不稳定。
- Phase 253 的 UI fallback 只保证损坏组件可达，不能修复数据库本身。

## 确定性修复规则

1. 读取 `id/created_at/parent_id/sibling_order`，不读取或改写用户可见名称。
2. missing parent 和 self-parent 断到顶层。
3. parent 图中每个 cycle 只断开稳定排序最早节点；其余边保留。
4. 浅层优先计算深度，第一个超过六层的节点断到顶层，后代内部关系保留。
5. 每个父级按旧 order、createdAt、id 稳定归一化为 `0..n-1`。
6. 计划在 startup repair 事务中逐行更新；异常影响行数或后续修复失败均 rollback，随后才执行
   `PRAGMA foreign_key_check`。

## SQLite/模型回放

`d02-folder-startup-integrity-repair.mjs` 建立带自引用外键的内存 SQLite，先关闭 foreign_keys 注入 orphan、A↔B
cycle、self-parent、七层链和 sibling gaps，再运行等价计划并重新开启外键。验证：

- folder 数量、ID 和名称完全保留；
- orphan 归顶层；cycle 只断一个稳定节点；七层链在第七层断开；
- 每组 siblingOrder 连续；`foreign_key_check=0`；
- 第二次执行计划为空且数据库字节语义不再变化；
- 注入中途失败后事务完整回滚；
- 修复不依赖 `user_version` 变化。

输出：

```text
D02_FOLDER_STARTUP_INTEGRITY_REPAIR_REPLAY_OK preserve-all=1|preserve-names=1|orphan=1|self-parent=1|cycle-min-break=1|max-depth-6=1|contiguous-orders=1|idempotent=1|foreign-key-check=0|transaction-rollback=1|same-version-startup=1
```

真实用户数据库副本、启动耗时、UI 恢复顺序和诊断提示仍是设备/迁移验收门。
