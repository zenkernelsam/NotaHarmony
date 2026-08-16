# ADR-0232：文件夹层级完整性在每次数据库启动时确定性修复

## 状态

已采用（2026-08-16）；真实旧库副本与用户可见恢复提示待设备验收。

## 背景

原版正常写路径以合法 parent tree、六层上限和有序 children 为前提。Harmony 已有 v9 自引用层级迁移，但数据库版本
不变的已安装用户、外部恢复或旧 bug 仍可能留下 orphan parent、自引用、parent cycle、超过六层及重复/空洞 sibling
order。只在 schema migration 修复无法覆盖这些用户；直接在 UI fallback 显示也不能让外键检查和后续写入恢复稳定。

## 决策

- 新增纯逻辑 `planFolderHierarchyRepairs()`，不删除 folder、不改 ID、不改名称，只生成 parent/order 更新计划。
- missing parent 与 self-parent 断到顶层；每个 parent cycle 只断开稳定排序最早的一个节点，保留其余关系与尽可能多的
  子树。
- 对超过原版六层的链，在第一个将成为第七层的节点断到顶层，其后代保留内部关系；然后重新计算深度。
- 所有父级按旧 `siblingOrder -> createdAt -> id` 稳定顺序归一化为连续 child index，包含 fractional、重复、空洞和
  非有限值。
- 修复在每次 `DatabaseManager.initialize()` 的统一 startup repair 事务内执行，位于 DDL 完成之后、外键检查之前；
  数据库版本未变化的用户同样进入。任何行数异常或其他 startup repair 失败都会回滚整个事务。

## 原版依据与适配边界

- `e47.java:353-354`：folder metadata 保存 parent 与 sibling order。
- `beb.java:133-171`：同级名称规则和递归子树高度。
- `xdb.java:87-109,124-144`：自身子树防护、六层上限和 child-index position。

原版证据定义合法树的不变量，但没有证明它会自动修复任意损坏数据库。本 ADR 的确定性恢复算法是 Harmony 对旧库、
恢复数据和历史移植 bug 的防御适配，不冒充原版业务功能。

## 验证

- `d02-folder-startup-integrity-repair.mjs` 在内存 SQLite 构造 orphan、self-parent、A↔B cycle、七层链和 sibling
  gaps，并验证第二次启动零变更，输出：
  `D02_FOLDER_STARTUP_INTEGRITY_REPAIR_REPLAY_OK preserve-all=1|preserve-names=1|orphan=1|self-parent=1|cycle-min-break=1|max-depth-6=1|contiguous-orders=1|idempotent=1|foreign-key-check=0|transaction-rollback=1|same-version-startup=1`。
- `FolderRepository.test.ets` 包含相同 ArkTS 纯逻辑 fixture。
- 全量桌面 replay：`REPLAY_FILES=240 FAILED=0`。
- 两套 HAP 均 `BUILD SUCCESSFUL`；`git diff --check` 通过。
- 未启动设备、模拟器、虚拟机、真机或 Hypium。

## 后续影响

启动修复已覆盖静态可证明的旧库损坏，但仍需在用户真实数据库副本上验证 relationalStore 行为、启动耗时、恢复后 UI
顺序和用户可见诊断。若未来增加同步颜色/emoji 或新的 folder 字段，修复器必须继续遵守“不猜测、不改用户可见
内容”的边界。
