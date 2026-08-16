# ADR-0230：文件夹子树判断对无关损坏循环采取隔离语义

## 状态

已采用（2026-08-16）；真实损坏数据库与设备 UI 验收待执行。

## 背景

原版 folder 模型由 parent/children/siblingOrder 构成，并在移动时执行自身子树与六层上限校验。Harmony 侧需要额外
防御旧数据库或恢复数据中的循环。旧 `isFolderInSubtree` 为终止循环直接返回 true，但该函数也驱动删除范围，可能把
与目标无关的循环组件误删或迁移笔记。

## 决策

- 子树成员必须由真实 parent 链到达 `rootId` 证明；遇到无关循环返回 false。
- 需要合法 ancestry 的操作继续调用 `folderDepth`/`subtreeHeight`，循环仍抛错，不能被用作移动目标。
- 导航层单独检测 cyclic ancestry 并作为损坏数据 fallback 显示；不把合法但折叠的子节点当 orphan。

## 原版依据

- `decompiled_1.0.3/sources/defpackage/e47.java:353-354`
- `decompiled_1.0.3/sources/defpackage/beb.java:133-171`
- `decompiled_1.0.3/sources/defpackage/xdb.java`

## 验证

- `d02-folder-cycle-isolation.mjs`：`D02_FOLDER_CYCLE_ISOLATION_REPLAY_OK`。
- `FolderRepository.test.ets` 增加无关循环隔离 fixture。
- `note@ohosTest`、`note@default` 均 `BUILD SUCCESSFUL`。
- 全量桌面 replay：`REPLAY_FILES=238 FAILED=0`；`git diff --check` 通过。
- 未启动设备、模拟器、虚拟机、真机或 Hypium。

## 后续影响

本 ADR 只定义损坏树的 fail-safe 行为，不代表数据库自动修复或原版同步颜色/emoji 已实现。真实迁移、恢复数据修复策略、
拖拽排序和设备可达性仍按 M2-U-05/后续任务处理。

T-042 APK 版本追踪保持为整个 Goal 最后一项；最终另写 Report，并归纳进 Wiki、技术/API 文档与新手入门。
